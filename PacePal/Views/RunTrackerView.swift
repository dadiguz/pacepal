import SwiftUI
import CoreLocation
import CoreMotion
import MapKit

// MARK: - Phase

private enum TrackerPhase: Equatable, Hashable {
    case idle
    case locationPermission
    case motionPermission
    case countdown(Int)
    case running
    case paused
    case finished
}

// MARK: - RunTrackerView

struct RunTrackerView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    @State private var tracker = RunTracker()
    @State private var phase: TrackerPhase = .idle
    @State private var showLocationAlert = false
    @State private var pendingKm: Double = 0        // applied on dismiss so HomeView animates
    @State private var showHoldToast = false
    @State private var toastMessage: String = ""

    // Hold-to-start
    @State private var startHoldProgress: Double = 0
    @State private var startHoldTimer: Timer? = nil

    // Hold-to-stop
    @State private var stopHoldProgress: Double = 0
    @State private var stopHoldTimer: Timer? = nil

    // Permission screen entrance animations
    @State private var locationPermAppeared = false
    @State private var motionPermAppeared = false

    private var displayDNA: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }
    private var currentDay: Int {
        let alreadyRanToday = health.todayKm >= appState.challengeLevel.runThreshold
        return max(1, min(66, alreadyRanToday ? appState.completedDays : appState.completedDays + 1))
    }

    private var currentPose: PetPose {
        switch phase {
        case .idle, .countdown, .locationPermission, .motionPermission: return .idle
        case .running:          return tracker.isMoving ? .running : .tired
        case .paused:           return .drinking
        case .finished:         return .jump
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#F9F496").ignoresSafeArea()
            AppBackground(imageName: "pattern")
                .ignoresSafeArea()
                .opacity(0.30)

            // All phases rendered simultaneously; opacity drives visibility.
            // Each view gets the full screen frame → no layout collapse.
            Group {
                idleContentView
                    .opacity(phase == .idle ? 1 : 0)

                locationPermissionView
                    .opacity(phase == .locationPermission ? 1 : 0)
                    .allowsHitTesting(phase == .locationPermission)

                motionPermissionView
                    .opacity(phase == .motionPermission ? 1 : 0)
                    .allowsHitTesting(phase == .motionPermission)

                countdownOverlay
                    .opacity({ if case .countdown = phase { return 1 } else { return 0 } }())

                runningView
                    .opacity(phase == .running ? 1 : 0)

                pausedView
                    .opacity(phase == .paused ? 1 : 0)

                finishedView
                    .opacity(phase == .finished ? 1 : 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.35), value: phase)

        }
        .overlay(alignment: .top) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .padding(.trailing, 36)
            }
            .frame(width: UIScreen.main.bounds.width)
            .padding(.top, 60)
            .opacity([.idle, .locationPermission].contains(phase) ? 1 : 0)
            .allowsHitTesting([.idle, .locationPermission].contains(phase))
            .animation(.easeInOut(duration: 0.2), value: phase)
        }
        .alert(L("tracker.location_title"), isPresented: $showLocationAlert) {
            Button(L("tracker.location_open_settings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button(L("tracker.location_cancel"), role: .cancel) {}
        } message: {
            Text(L("tracker.location_body"))
        }
        .onChange(of: tracker.locationAuthStatus) { _, status in
            if status == .denied || status == .restricted {
                if phase == .locationPermission { withAnimation { phase = .idle } }
                showLocationAlert = true
            } else if (status == .authorizedWhenInUse || status == .authorizedAlways)
                        && phase == .locationPermission {
                withAnimation { phase = .idle }
                beginCountdown()
            }
        }
        .overlay(alignment: .top) {
            if showHoldToast {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(toastMessage.isEmpty ? L("tracker.hold_toast") : toastMessage)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.75))
                .clipShape(Capsule())
                    .padding(.top, 60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: showHoldToast)
        .onChange(of: tracker.autoPauseTriggered) { _, triggered in
            if triggered {
                pauseRun()
                tracker.autoPauseTriggered = false
                showAutoPauseToast()
            }
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .locationPermission {
                locationPermAppeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { locationPermAppeared = true }
            } else if newPhase == .motionPermission {
                motionPermAppeared = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { motionPermAppeared = true }
            }
        }
        .onAppear {
            if tracker.restoreStateIfNeeded() {
                phase = .paused   // show paused state with progress intact
            } else {
                tracker.reset()
                phase = .idle
            }
            startHoldProgress = 0
            stopHoldProgress = 0
            pendingKm = 0
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard phase == .running || phase == .paused else { return }
            if newPhase == .background {
                tracker.saveState()
                if phase == .running { pauseRun() }
            }
        }
        .onDisappear {
            // addManualKm updates sessionKm → HomeView onChange → runKmAnimation
            // handles energy + completedDays (single source of truth, avoids double-add)
            if pendingKm > 0 {
                health.addManualKm(pendingKm)
                appState.syncToWidget(km: health.todayKm)
                pendingKm = 0
            }
        }
    }

    // MARK: - Shared Nike-style header (Pace | Day | Time)

    private var nrcHeader: some View {
        let screenW = UIScreen.main.bounds.width
        let col = (screenW - 72) / 3   // 72 = 36pt padding × 2

        return HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tracker.formattedPace ?? "--:--")
                    .font(.system(size: 28, weight: .black)).monospacedDigit()
                    .foregroundStyle(.black)
                Text(L("tracker.label_pace"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(width: col, alignment: .leading)

            VStack(alignment: .center, spacing: 3) {
                Text("\(currentDay)/66")
                    .font(.system(size: 28, weight: .black)).monospacedDigit()
                    .foregroundStyle(.black)
                Text(L("tracker.label_day"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(width: col, alignment: .center)

            VStack(alignment: .trailing, spacing: 3) {
                Text(tracker.formattedTime)
                    .font(.system(size: 28, weight: .black)).monospacedDigit()
                    .foregroundStyle(.black)
                Text(L("tracker.label_time"))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(width: col, alignment: .trailing)
        }
        .frame(width: screenW - 72)
        .padding(.horizontal, 36)
        .padding(.top, 56)
    }

    // MARK: - Shared KM block

    private var kmDisplay: some View {
        VStack(spacing: 4) {
            Text(String(format: "%.2f", tracker.distanceKm))
                .font(.system(size: 128, weight: .black))
                .foregroundStyle(.black)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: tracker.distanceKm)
            Text(L("tracker.label_kilometers"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1)
        }
    }

    // MARK: - Idle: hold-circle to start

    private var idleContentView: some View {
        ZStack {

        VStack(spacing: 0) {
            Spacer()

            ZStack {
                PetAnimationView(
                    dna: displayDNA,
                    pose: startHoldProgress > 0 ? .sign : .idle,
                    pixelSize: 9
                )
                .animation(.easeInOut(duration: 0.2), value: startHoldProgress > 0)
                .opacity(tracker.isIndoor ? 0 : 1)

                PetIndoorStage(dna: displayDNA, isRunning: false)
                    .opacity(tracker.isIndoor ? 1 : 0)
            }
            .frame(width: 200, height: 200)
            .animation(.easeInOut(duration: 0.25), value: tracker.isIndoor)

            Circle()
                .fill(Color(hex: "#F9703E"))
                .frame(width: 120, height: 120)
                .overlay(
                    Text(L("tracker.start_button"))
                        .font(.system(size: 21, weight: .black))
                        .italic()
                        .tracking(0.5)
                        .foregroundStyle(.white)
                )
                .scaleEffect(startHoldProgress > 0 ? 1.12 : 1.0)
                .animation(.spring(duration: 0.2), value: startHoldProgress > 0)
                .shadow(color: Color(hex: "#F9703E").opacity(0.4), radius: 20, y: 8)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in startHoldBegan() }
                        .onEnded   { _ in startHoldCancelled() }
                )
                .padding(.top, 40)

            // Settings row
            HStack(spacing: 12) {
                // Indoor / Outdoor toggle
                let motionDenied = CMMotionActivityManager.authorizationStatus() == .denied
                Button {
                    if tracker.isIndoor {
                        tracker.isIndoor = false
                    } else {
                        let status = CMMotionActivityManager.authorizationStatus()
                        if status == .authorized {
                            tracker.isIndoor = true
                        } else if status == .notDetermined {
                            withAnimation { phase = .motionPermission }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run.treadmill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(L("tracker.indoor"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(motionDenied ? Color.black.opacity(0.3) : tracker.isIndoor ? .white : Color.black.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(motionDenied ? Color.black.opacity(0.04) : tracker.isIndoor ? Color.black : Color.black.opacity(0.07))
                    .clipShape(Capsule())
                }
                .disabled(motionDenied)

                // Auto-pause toggle
                Button {
                    tracker.isAutoPause.toggle()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(L("tracker.auto_pause"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(tracker.isAutoPause ? .white : Color.black.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(tracker.isAutoPause ? Color.black : Color.black.opacity(0.07))
                    .clipShape(Capsule())
                }
            }
            .padding(.top, 36)

            Spacer()
        }
        } // ZStack idleContentView
    }

    // MARK: - Location Permission

    private var locationPermissionView: some View {
        TrackerLocPermView(
            dna: displayDNA,
            appeared: locationPermAppeared,
            onAllow: { tracker.requestLocationPermission() },
            onCancel: { withAnimation { phase = .idle } }
        )
    }

    // MARK: - Motion Permission

    private var motionPermissionView: some View {
        TrackerMotionPermView(
            dna: displayDNA,
            appeared: motionPermAppeared,
            onAllow: {
                tracker.requestMotionPermission { granted in
                    tracker.isIndoor = granted
                    withAnimation { phase = .idle }
                }
            },
            onCancel: {
                tracker.isIndoor = false
                withAnimation { phase = .idle }
            }
        )
    }

    // MARK: - Countdown

    private var countdownOverlay: some View {
        ZStack {
            if case .countdown(let n) = phase {
                Text("\(n)")
                    .font(.system(size: 140, weight: .black))
                    .foregroundStyle(.black)
                    .id(n)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.4).combined(with: .opacity),
                        removal:   .scale(scale: 0.6).combined(with: .opacity)
                    ))
            }
        }
    }

    // MARK: - Running

    private var runningView: some View {
        VStack(spacing: 0) {
            nrcHeader
            Spacer()
            kmDisplay
            Button { pauseRun() } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 80, height: 80)
                    .background(.black)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
            }
            .padding(.top, 40)
            Spacer()
            PetAnimationView(dna: displayDNA, pose: currentPose, pixelSize: 9)
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 0.4), value: currentPose)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Paused

    private var pausedView: some View {
        VStack(spacing: 0) {
            nrcHeader
            Spacer()
            kmDisplay
            HStack(spacing: 32) {
                HoldCircle(
                    progress: stopHoldProgress,
                    icon: "stop.fill",
                    color: Color(hex: "#E12D39"),
                    size: 72
                )
                .scaleEffect(stopHoldProgress > 0 ? 1.12 : 1.0)
                .animation(.spring(duration: 0.2), value: stopHoldProgress > 0)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in stopHoldBegan() }
                        .onEnded   { _ in stopHoldCancelled() }
                )
                Button { resumeRun() } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 80, height: 80)
                        .background(.black)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 5)
                }
            }
            .padding(.top, 40)
            Spacer()
            PetAnimationView(dna: displayDNA, pose: currentPose, pixelSize: 9)
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 0.4), value: currentPose)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Finished

    private var finishedView: some View {
        VStack(spacing: 0) {
            nrcHeader
            .frame(maxWidth: .infinity)

            Spacer()

            kmDisplay

            HStack(spacing: 20) {
                // Share
                Button { Task { await prepareShare() } } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(Color.black.opacity(0.08))
                        .clipShape(Circle())
                }

                // Done
                Button { dismiss() } label: {
                    Text(L("tracker.done"))
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .padding(.horizontal, 48)
                        .padding(.vertical, 18)
                        .background(.black)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
                }
            }
            .padding(.top, 40)

            Spacer()

            PetAnimationView(dna: displayDNA, pose: currentPose, pixelSize: 9)
                .frame(width: 200, height: 200)
                .animation(.easeInOut(duration: 0.4), value: currentPose)
                .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Share (screenshot card + optional route)

    @MainActor
    private func prepareShare() async {
        let card = RunShareCard(
            km: tracker.distanceKm,
            time: tracker.formattedTime,
            pace: tracker.formattedPace,
            day: currentDay,
            dna: displayDNA,
            routeCoordinates: tracker.isIndoor ? [] : tracker.routeCoordinates
        )
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = .init(width: 1080, height: 1920)
        renderer.scale = 1

        let items: [Any]
        if let img = renderer.uiImage, let data = img.pngData() {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("pacepal_run.png")
            if (try? data.write(to: url)) != nil {
                items = [url]
            } else {
                items = [img]
            }
        } else {
            items = ["\(String(format: "%.2f", tracker.distanceKm)) km — Day \(currentDay)/66 #PacePal"]
        }

        // Present via UIKit directly — avoids SwiftUI nested-sheet issues
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        var top = root
        while let next = top.presentedViewController { top = next }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        top.present(vc, animated: true)
    }

    // MARK: - Hold-to-start logic

    private func startHoldBegan() {
        guard phase == .idle, startHoldTimer == nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let interval = 0.05
        let total = 1.0
        startHoldTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            startHoldProgress += interval / total
            if Int(startHoldProgress * total) != Int((startHoldProgress - interval / total) * total) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            if startHoldProgress >= 1.0 {
                t.invalidate()
                startHoldTimer = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                beginCountdown()
            }
        }
    }

    private func startHoldCancelled() {
        let wasHolding = startHoldProgress > 0 && startHoldProgress < 1.0
        startHoldTimer?.invalidate()
        startHoldTimer = nil
        withAnimation(.spring(duration: 0.3)) { startHoldProgress = 0 }
        if wasHolding { triggerHoldToast() }
    }

    private func triggerHoldToast() {
        showToast(L("tracker.hold_toast"))
    }

    private func showAutoPauseToast() {
        showToast(L("tracker.auto_paused_toast"))
    }

    private func showToast(_ message: String) {
        toastMessage = message
        showHoldToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { showHoldToast = false; toastMessage = "" }
        }
    }

    private func beginCountdown() {
        startHoldProgress = 0
        // Outdoor + location permission not yet granted
        if !tracker.isIndoor && tracker.locationAuthStatus == .notDetermined {
            withAnimation { phase = .locationPermission }
            return
        }
        // If motion permission was denied, indoor can't be used
        if tracker.isIndoor && CMMotionActivityManager.authorizationStatus() == .denied {
            tracker.isIndoor = false
        }
        // Indoor + motion permission not yet granted
        if tracker.isIndoor && tracker.needsMotionPermission {
            withAnimation { phase = .motionPermission }
            return
        }
        beginCountdownDirectly()
    }

    private func beginCountdownDirectly() {
        withAnimation { phase = .countdown(3) }
        Task {
            for n in stride(from: 3, through: 1, by: -1) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                await MainActor.run { withAnimation(.spring(duration: 0.3)) { phase = .countdown(n) } }
                try? await Task.sleep(for: .seconds(1))
            }
            await MainActor.run { beginRun() }
        }
    }

    private func beginRun() {
        let status = tracker.locationAuthStatus
        if status == .denied || status == .restricted {
            phase = .idle
            showLocationAlert = true
            return
        }
        tracker.requestPermissionAndStart()
        withAnimation { phase = .running }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        SoundManager.shared.play(.running, enabled: appState.soundsEnabled)
    }

    // MARK: - Pause / Resume

    private func pauseRun() {
        tracker.pause()
        withAnimation { phase = .paused }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    private func resumeRun() {
        tracker.resume()
        withAnimation { phase = .running }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    // MARK: - Hold-to-stop logic

    private func stopHoldBegan() {
        guard phase == .paused, stopHoldTimer == nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let interval = 0.05
        let total = 1.0
        stopHoldTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            stopHoldProgress += interval / total
            if Int(stopHoldProgress * total) != Int((stopHoldProgress - interval / total) * total) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            if stopHoldProgress >= 1.0 {
                t.invalidate()
                stopHoldTimer = nil
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                finishAndSave()
            }
        }
    }

    private func stopHoldCancelled() {
        let wasHolding = stopHoldProgress > 0 && stopHoldProgress < 1.0
        stopHoldTimer?.invalidate()
        stopHoldTimer = nil
        withAnimation(.spring(duration: 0.3)) { stopHoldProgress = 0 }
        if wasHolding { triggerHoldToast() }
    }

    // MARK: - Finish

    private func finishAndSave() {
        stopHoldProgress = 0
        tracker.finish()
        tracker.clearSavedState()
        let km = tracker.distanceKm
        if km > 0 { pendingKm = km }   // applied on dismiss so HomeView's km animation fires
        withAnimation { phase = .finished }
        SoundManager.shared.play(.jump, enabled: appState.soundsEnabled)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - PetCarryingPinStage (GPS permission)

private struct PetCarryingPinStage: View {
    let dna: PetDNA
    @State private var liftUp = false

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)

            VStack(spacing: -14) {
                PixelLocationPinView()
                    .shadow(color: Color(hex: "#F9703E").opacity(0.4), radius: 8, y: 4)

                PixelPetArmsUpView(dna: dna)
            }
            .offset(y: liftUp ? -5 : 2)
            .animation(
                .interpolatingSpring(stiffness: 50, damping: 6)
                    .repeatForever(autoreverses: true)
                    .speed(0.45),
                value: liftUp
            )
        }
        .onAppear { liftUp = true }
    }
}

// MARK: - PixelPetArmsUpView (pixel art pet holding pin — used in GPS permission screens)

struct PixelPetArmsUpView: View {
    let dna: PetDNA

    var body: some View {
        Canvas { ctx, _ in
            let p: CGFloat = 8
            let B  = Color(hex: "#1A1A1A")
            let bd = Color(hex: dna.palette.body)
            let sh = Color(hex: dna.palette.shade)
            let fc = Color(hex: dna.palette.face)
            let ey = Color(hex: dna.palette.eyeP)
            let ck = Color(hex: dna.palette.cheek)

            func px(_ c: Int, _ r: Int, _ col: Color) {
                ctx.fill(Path(CGRect(x: CGFloat(c)*p, y: CGFloat(r)*p, width: p, height: p)),
                         with: .color(col))
            }

            // MARK: Ears — animal-specific
            switch dna.animalType {
            case .bunny:
                // Tall thin ears (cols 1 and 8, rows 0-1 — above head)
                px(0,0,B); px(1,0,bd); px(8,0,bd); px(9,0,B)
                px(0,1,B); px(1,1,bd); px(8,1,bd); px(9,1,B)
            case .cat, .fox, .tiger, .dragon:
                // Pointed ears — one row
                px(0,1,B); px(1,1,bd); px(8,1,bd); px(9,1,B)
            case .bear, .panda, .raccoon, .mouse, .dog, .corgi, .capuchin, .mandrill, .lion:
                // Round bump ears alongside upper head
                px(1,2,bd); px(8,2,bd)
                px(1,3,bd); px(8,3,bd)
            default:
                break
            }

            // Row 0 — hands (gripping the pin stem)
            px(2,0,bd); px(7,0,bd)
            // Row 1 — wrists / raised arms
            px(2,1,B); px(7,1,B)
            // Row 2 — head top
            px(2,2,B); px(3,2,B); px(4,2,B); px(5,2,B); px(6,2,B); px(7,2,B)
            // Row 3 — face
            px(2,3,B); px(3,3,fc); px(4,3,fc); px(5,3,fc); px(6,3,fc); px(7,3,B)
            // Row 4 — eyes
            px(2,4,B); px(3,4,fc); px(4,4,ey); px(5,4,fc); px(6,4,ey); px(7,4,B)
            // Row 5 — mouth + cheeks (cheeks replace smile corners when present)
            let mouthCorner = dna.hasCheeks ? ck : fc
            px(2,5,B); px(3,5,mouthCorner); px(4,5,B); px(5,5,B); px(6,5,mouthCorner); px(7,5,B)
            // Row 6 — chin
            px(2,6,B); px(3,6,B); px(4,6,B); px(5,6,B); px(6,6,B); px(7,6,B)
            // Row 7 — shoulders
            px(1,7,B); px(2,7,bd); px(3,7,bd); px(4,7,bd); px(5,7,bd); px(6,7,bd); px(7,7,bd); px(8,7,B)
            // Row 8 — body
            px(1,8,B); px(2,8,bd); px(3,8,sh); px(4,8,sh); px(5,8,sh); px(6,8,sh); px(7,8,bd); px(8,8,B)
            // Row 9 — waist
            px(2,9,B); px(3,9,bd); px(4,9,bd); px(5,9,bd); px(6,9,bd); px(7,9,B)
            // Row 10 — thighs
            px(2,10,B); px(3,10,bd); px(6,10,bd); px(7,10,B)
            // Row 11 — feet
            px(1,11,B); px(2,11,bd); px(3,11,B); px(6,11,B); px(7,11,bd); px(8,11,B)
        }
        .frame(width: 10 * 8, height: 12 * 8)
    }
}

// MARK: - PetIndoorStage (Motion/Indoor permission)

// MARK: - PixelLocationPinView

struct PixelLocationPinView: View {
    var body: some View {
        Canvas { ctx, _ in
            let p: CGFloat = 5
            let B = Color(hex: "#1A1A1A")   // black border + hole
            let O = Color(hex: "#F9703E")   // orange fill
            let H = Color(hex: "#FFAA78")   // highlight

            func px(_ c: Int, _ r: Int, _ color: Color) {
                ctx.fill(Path(CGRect(x: CGFloat(c)*p, y: CGFloat(r)*p, width: p, height: p)),
                         with: .color(color))
            }

            // Row 0 — top border
            px(1,0,B); px(2,0,B); px(3,0,B); px(4,0,B); px(5,0,B); px(6,0,B)
            // Row 1
            px(0,1,B); px(1,1,O); px(2,1,O); px(3,1,O); px(4,1,O); px(5,1,O); px(6,1,O); px(7,1,B)
            // Row 2 — highlight top-left
            px(0,2,B); px(1,2,O); px(2,2,H); px(3,2,H); px(4,2,H); px(5,2,O); px(6,2,O); px(7,2,B)
            // Row 3 — hole top
            px(0,3,B); px(1,3,O); px(2,3,H); px(3,3,B); px(4,3,B); px(5,3,H); px(6,3,O); px(7,3,B)
            // Row 4 — hole bottom
            px(0,4,B); px(1,4,O); px(2,4,O); px(3,4,B); px(4,4,B); px(5,4,O); px(6,4,O); px(7,4,B)
            // Row 5
            px(0,5,B); px(1,5,O); px(2,5,O); px(3,5,O); px(4,5,O); px(5,5,O); px(6,5,O); px(7,5,B)
            // Row 6 — narrowing
            px(1,6,B); px(2,6,O); px(3,6,O); px(4,6,O); px(5,6,O); px(6,6,B)
            // Row 7
            px(2,7,B); px(3,7,O); px(4,7,O); px(5,7,B)
            // Row 8 — tip
            px(3,8,B); px(4,8,B)
            // Row 9 — point
            px(3,9,B)
        }
        .frame(width: 8*5, height: 10*5)
    }
}

private struct PetIndoorStage: View {
    let dna: PetDNA
    var isRunning: Bool = true

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)

            VStack(spacing: -12) {
                ZStack(alignment: .topTrailing) {
                    PetAnimationView(dna: dna, pose: isRunning ? .running : .idle, pixelSize: 7)
                        .frame(width: 90, height: 145)
                        .offset(y: 23)

                    if isRunning {
                        SweatDropsView()
                            .offset(x: 10, y: 61)
                    }
                }

                PixelTreadmillView(isRunning: isRunning)
            }
        }
    }
}

// MARK: - SweatDropsView

private struct SweatDropsView: View {
    var body: some View {
        ZStack {
            SweatDrop(delay: 0.0, x: 0)
            SweatDrop(delay: 0.35, x: 10)
            SweatDrop(delay: 0.7, x: -8)
        }
        .frame(width: 40, height: 40)
    }
}

private struct SweatDrop: View {
    let delay: Double
    let x: CGFloat
    @State private var animating = false

    var body: some View {
        Canvas { ctx, _ in
            let p: CGFloat = 5
            let blue  = Color(hex: "#5BA8E8")
            let light = Color(hex: "#A8D8FA")

            func px(_ c: Int, _ r: Int, _ col: Color) {
                ctx.fill(Path(CGRect(x: CGFloat(c)*p, y: CGFloat(r)*p, width: p, height: p)),
                         with: .color(col))
            }
            // Pixel drop shape (2×4):
            //  . X
            //  X X
            //  X x  (x = highlight)
            //  . X
            px(1, 0, blue)
            px(0, 1, blue); px(1, 1, blue)
            px(0, 2, blue); px(1, 2, light)
            px(1, 3, blue)
        }
        .frame(width: 10, height: 20)
        .offset(x: x, y: animating ? 18 : 0)
        .opacity(animating ? 0 : 0.9)
        .onAppear {
            withAnimation(.easeIn(duration: 0.6).delay(delay).repeatForever(autoreverses: false)) {
                animating = true
            }
        }
    }
}

// MARK: - PixelTreadmillView

private struct PixelTreadmillView: View {
    var isRunning: Bool = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.08)) { tl in
            Canvas { ctx, _ in
                let p: CGFloat = 8
                let t = isRunning ? tl.date.timeIntervalSinceReferenceDate : 0

                let orange = Color(hex: "#F9703E")
                let gray   = Color(hex: "#4A4A4A")
                let drum   = Color(hex: "#3A3A3A")
                let belt   = Color(hex: "#525252")
                let shine  = Color(hex: "#787878")
                let foot   = Color(hex: "#2A2A2A")

                func px(_ c: Int, _ r: Int, _ color: Color) {
                    ctx.fill(
                        Path(CGRect(x: CGFloat(c) * p, y: CGFloat(r) * p, width: p, height: p)),
                        with: .color(color)
                    )
                }

                // Handlebars (orange accent)
                px(3, 0, orange); px(4, 0, orange)
                px(3, 1, orange); px(4, 1, orange)

                // Diagonal frame
                px(2, 2, gray); px(3, 2, gray)
                px(1, 3, gray); px(2, 3, gray)
                px(0, 4, gray); px(1, 4, gray)

                // Back drum
                px(0, 5, drum); px(0, 6, drum); px(0, 7, drum)

                // Belt top highlight
                for c in 1...16 { px(c, 5, shine) }

                // Belt surface — animated stripes scroll left
                for c in 1...16 {
                    let phase = (Double(c) + t * 5.0).truncatingRemainder(dividingBy: 4.0)
                    let isStripe = phase < 1.0
                    px(c, 6, isStripe ? shine : belt)
                    px(c, 7, isStripe ? shine : belt)
                }

                // Front drum
                px(17, 5, drum); px(17, 6, drum); px(17, 7, drum)

                // Left leg + foot
                px(2, 8, foot); px(2, 9, foot)
                px(1, 10, foot); px(2, 10, foot); px(3, 10, foot)

                // Right leg + foot
                px(15, 8, foot); px(15, 9, foot)
                px(14, 10, foot); px(15, 10, foot); px(16, 10, foot)
            }
        }
        .frame(width: 8 * 20, height: 8 * 11)
    }
}

// MARK: - PetOnTreadmillStage (Motion permission)

private struct PetOnTreadmillStage: View {
    let dna: PetDNA
    @State private var beltOffset: CGFloat = -100

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background glow
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.07))
                .frame(width: 180, height: 180)
                .blur(radius: 28)

            VStack(spacing: 0) {
                // Pet running on top
                PetAnimationView(dna: dna, pose: .running, pixelSize: 9)
                    .frame(width: 130, height: 130)
                    .offset(y: 10) // slightly overlap the belt

                // Treadmill machine
                ZStack {
                    // Belt track
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "#2C2C2E"))
                        .frame(width: 190, height: 24)

                    // Moving shimmer stripe
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.28), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 80, height: 24)
                        .offset(x: beltOffset)
                        .onAppear {
                            withAnimation(.linear(duration: 0.75).repeatForever(autoreverses: false)) {
                                beltOffset = 190
                            }
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Support legs
                HStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1C1C1E"))
                        .frame(width: 10, height: 22)
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1C1C1E"))
                        .frame(width: 10, height: 22)
                }
                .frame(width: 170)
            }
        }
    }
}

// MARK: - HoldCircle

private struct HoldCircle: View {
    let progress: Double
    let icon: String
    let color: Color
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.12), lineWidth: 5)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
                .animation(.linear(duration: 0.05), value: progress)

            Image(systemName: icon)
                .font(.system(size: size * 0.35, weight: .bold))
                .foregroundStyle(progress > 0 ? color : .black)
                .frame(width: size, height: size)
                .background(progress > 0 ? color.opacity(0.12) : Color.black.opacity(0.07))
                .clipShape(Circle())
                .scaleEffect(progress > 0 ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: progress > 0)
        }
        .shadow(color: color.opacity(0.25), radius: 10, y: 4)
    }
}


// MARK: - TrackerLocPermView (GPS location permission)

private struct TrackerLocPermView: View {
    let dna: PetDNA
    let appeared: Bool
    let onAllow: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                PetCarryingPinStage(dna: dna)
                    .frame(height: 180)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                VStack(spacing: 20) {
                    (
                        Text(L("tracker.location_permission_title_part1"))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1F2933"))
                        + Text(L("tracker.location_permission_title_highlight"))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#F9703E"))
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                    Text(L("tracker.location_permission_body"))
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(Color(hex: "#52606D"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    HStack(spacing: 10) {
                        pill(icon: "location.fill", label: "GPS")
                        pill(icon: "figure.run",    label: L("tracker.outdoor"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                Spacer()

                VStack(spacing: 12) {
                    Button { onAllow() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill").font(.system(size: 15))
                            Text(L("tracker.location_permission_allow"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
                    }
                    Button { onCancel() } label: {
                        Text(L("tracker.location_permission_cancel"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#52606D"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private func pill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color(hex: "#F9703E"))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "#FFF1EC"))
        .clipShape(Capsule())
    }
}

// MARK: - TrackerMotionPermView (Motion/Indoor permission)

private struct TrackerMotionPermView: View {
    let dna: PetDNA
    let appeared: Bool
    let onAllow: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                PetIndoorStage(dna: dna)
                    .frame(height: 180)
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                VStack(spacing: 20) {
                    (
                        Text(L("tracker.motion_permission_title_part1"))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1F2933"))
                        + Text(L("tracker.motion_permission_title_highlight"))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#F9703E"))
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                    Text(L("tracker.motion_permission_body"))
                        .font(.system(size: 17, design: .rounded))
                        .foregroundStyle(Color(hex: "#52606D"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    HStack(spacing: 10) {
                        pill(icon: "figure.run.treadmill", label: L("tracker.indoor"))
                        pill(icon: "location.slash.fill",  label: "Sin GPS")
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                }
                .frame(width: UIScreen.main.bounds.width)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                Spacer()

                VStack(spacing: 12) {
                    Button { onAllow() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.run.treadmill").font(.system(size: 15))
                            Text(L("tracker.motion_permission_allow"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
                    }
                    Button { onCancel() } label: {
                        Text(L("tracker.motion_permission_cancel"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#52606D"))
                    }
                }
                .frame(width: UIScreen.main.bounds.width - 48)
                .padding(.bottom, 48)
            }
        }
    }

    private func pill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color(hex: "#F9703E"))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "#FFF1EC"))
        .clipShape(Capsule())
    }
}

// MARK: - Share card (rendered by ImageRenderer)

struct RunShareCard: View {
    let km: Double
    let time: String
    let pace: String?
    let day: Int
    let dna: PetDNA
    let routeCoordinates: [CLLocationCoordinate2D]

    private var hasRoute: Bool { routeCoordinates.count > 1 }

    var body: some View {
        ZStack {
            Color(hex: "#F9F496")

            VStack(spacing: 0) {
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 56)
                    .padding(.top, 110)

                // KM
                Text(String(format: "%.2f", km))
                    .font(.system(size: 240, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, 48)
                    .padding(.top, 44)

                Text("KILOMETERS")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.32))
                    .tracking(6)
                    .padding(.top, 8)

                // Route line (outdoor) or pet centered (indoor)
                if hasRoute {
                    RoutePolylineView(coordinates: routeCoordinates)
                        .frame(width: 900, height: 700)
                        .padding(.top, 32)
                } else {
                    PetAnimationView(dna: dna, pose: .jump, pixelSize: 18)
                        .frame(width: 340, height: 340)
                        .padding(.top, 60)
                }

                Spacer()

                // Stats row
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(pace ?? "--:--")
                            .font(.system(size: 58, weight: .black)).monospacedDigit()
                            .foregroundStyle(.black)
                        Text(L("tracker.label_pace"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.32))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .center, spacing: 10) {
                        Text("\(day)/66")
                            .font(.system(size: 58, weight: .black)).monospacedDigit()
                            .foregroundStyle(.black)
                        Text(L("tracker.label_day"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.32))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .trailing, spacing: 10) {
                        Text(time)
                            .font(.system(size: 58, weight: .black)).monospacedDigit()
                            .foregroundStyle(.black)
                        Text(L("tracker.label_time"))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.32))
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding(.horizontal, 72)
                .padding(.bottom, 52)

                // Pet
                HStack(alignment: .bottom) {
                    PetAnimationView(dna: dna, pose: .jump, pixelSize: hasRoute ? 12 : 0)
                        .frame(width: hasRoute ? 160 : 0, height: hasRoute ? 160 : 0)
                    Spacer()
                }
                .padding(.horizontal, 72)
                .padding(.bottom, 100)
            }
        }
        .frame(width: 1080, height: 1920)
    }
}

// MARK: - Route polyline (pure Canvas — no map tiles)

private struct RoutePolylineView: View {
    let coordinates: [CLLocationCoordinate2D]

    var body: some View {
        Canvas { ctx, size in
            guard coordinates.count > 1 else { return }

            var minLat = coordinates[0].latitude, maxLat = coordinates[0].latitude
            var minLon = coordinates[0].longitude, maxLon = coordinates[0].longitude
            for c in coordinates {
                minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
                minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
            }

            let latRange = max(maxLat - minLat, 0.0005)
            let lonRange = max(maxLon - minLon, 0.0005)
            let geoAspect = latRange / lonRange

            let pad: CGFloat = 56
            let availW = size.width - pad * 2
            let availH = size.height - pad * 2
            let drawW: CGFloat
            let drawH: CGFloat
            if geoAspect * availW > availH {
                drawH = availH; drawW = availH / geoAspect
            } else {
                drawW = availW; drawH = availW * geoAspect
            }
            let ox = (size.width - drawW) / 2
            let oy = (size.height - drawH) / 2

            func pt(_ c: CLLocationCoordinate2D) -> CGPoint {
                CGPoint(
                    x: ox + CGFloat((c.longitude - minLon) / lonRange) * drawW,
                    y: oy + CGFloat(1 - (c.latitude - minLat) / latRange) * drawH
                )
            }

            var path = Path()
            path.move(to: pt(coordinates[0]))
            coordinates.dropFirst().forEach { path.addLine(to: pt($0)) }

            let stroke = StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
            ctx.stroke(path, with: .color(.black.opacity(0.12)),
                       style: StrokeStyle(lineWidth: 16, lineCap: .round, lineJoin: .round))
            ctx.stroke(path, with: .color(Color(hex: "#F9703E")), style: stroke)

            func dot(_ c: CLLocationCoordinate2D, fill: Color) {
                let p = pt(c)
                let r: CGFloat = 16
                ctx.fill(Path(ellipseIn: CGRect(x: p.x-r, y: p.y-r, width: r*2, height: r*2)), with: .color(.white))
                let ri: CGFloat = 9
                ctx.fill(Path(ellipseIn: CGRect(x: p.x-ri, y: p.y-ri, width: ri*2, height: ri*2)), with: .color(fill))
            }
            dot(coordinates.first!, fill: Color(hex: "#F9703E"))
            dot(coordinates.last!,  fill: .black)
        }
    }
}
