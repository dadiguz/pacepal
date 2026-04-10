import SwiftUI
import CoreLocation
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
    private var currentDay: Int { min(66, appState.completedDays + 1) }

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
            // Fresh state every time the view is presented
            tracker.reset()
            phase = .idle
            startHoldProgress = 0
            stopHoldProgress = 0
            pendingKm = 0
        }
        .onDisappear {
            // Apply km credit here so HomeView's animation triggers on arrival
            if pendingKm > 0 {
                health.addManualKm(pendingKm)
                appState.addEnergy(km: pendingKm, at: Date())
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
                Text("PACE")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(width: col, alignment: .leading)

            VStack(alignment: .center, spacing: 3) {
                Text("\(currentDay)/66")
                    .font(.system(size: 28, weight: .black)).monospacedDigit()
                    .foregroundStyle(.black)
                Text("DAY")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(width: col, alignment: .center)

            VStack(alignment: .trailing, spacing: 3) {
                Text(tracker.formattedTime)
                    .font(.system(size: 28, weight: .black)).monospacedDigit()
                    .foregroundStyle(.black)
                Text("TIME")
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
            Text("kilometers")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.4))
                .textCase(.uppercase)
                .tracking(1)
        }
    }

    // MARK: - Idle: hold-circle to start

    private var idleContentView: some View {
        VStack(spacing: 0) {
            Spacer()

            PetAnimationView(
                dna: displayDNA,
                pose: startHoldProgress > 0 ? .sign : .idle,
                pixelSize: 9
            )
            .frame(width: 200, height: 200)
            .animation(.easeInOut(duration: 0.2), value: startHoldProgress > 0)

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
                Button {
                    if tracker.isIndoor {
                        tracker.isIndoor = false
                    } else if tracker.needsMotionPermission {
                        withAnimation { phase = .motionPermission }
                    } else {
                        tracker.isIndoor = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tracker.isIndoor ? "figure.run.treadmill" : "location.fill")
                            .font(.system(size: 12, weight: .semibold))
                        Text(tracker.isIndoor ? L("tracker.indoor") : L("tracker.outdoor"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(tracker.isIndoor ? .white : Color.black.opacity(0.6))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(tracker.isIndoor ? Color.black : Color.black.opacity(0.07))
                    .clipShape(Capsule())
                }

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
                    if granted { tracker.isIndoor = true }
                    withAnimation { phase = .idle }
                }
            },
            onCancel: { withAnimation { phase = .idle } }
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
                Button { prepareShare() } label: {
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
    private func prepareShare() {
        let card = RunShareCard(
            km: tracker.distanceKm,
            time: tracker.formattedTime,
            pace: tracker.formattedPace,
            day: currentDay,
            dna: displayDNA
        )
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = .init(width: 390, height: 500)
        renderer.scale = 3

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
    @State private var bobUp = false
    @State private var glowOn = false

    var body: some View {
        ZStack(alignment: .center) {
            // Soft background glow
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)

            VStack(spacing: -12) {
                // Location pin the pet is "holding up"
                ZStack {
                    // Shadow/glow behind pin
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(Color(hex: "#F9703E").opacity(glowOn ? 0.3 : 0.15))
                        .blur(radius: 8)
                        .scaleEffect(glowOn ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: glowOn)

                    // Pin itself
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(Color(hex: "#F9703E"))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.5), radius: 6, y: 3)
                }
                .offset(y: bobUp ? -6 : 0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: bobUp)

                // Pet holding it up with .sign pose
                PetAnimationView(dna: dna, pose: .sign, pixelSize: 9)
                    .frame(width: 130, height: 130)
            }
        }
        .onAppear {
            bobUp  = true
            glowOn = true
        }
    }
}

// MARK: - PetIndoorStage (Motion/Indoor permission)

private struct PetIndoorStage: View {
    let dna: PetDNA

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)

            VStack(spacing: -12) {
                ZStack(alignment: .topTrailing) {
                    PetAnimationView(dna: dna, pose: .running, pixelSize: 7)
                        .frame(width: 90, height: 145)
                        .offset(y: 23)

                    SweatDropsView()
                        .offset(x: 10, y: 61)
                }

                PixelTreadmillView()
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
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.08)) { tl in
            Canvas { ctx, _ in
                let p: CGFloat = 8
                let t = tl.date.timeIntervalSinceReferenceDate

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

    var body: some View {
        ZStack {
            Color(hex: "#F9F496")

            VStack(spacing: 0) {
                // Header row — fixed 390pt width so GeometryReader isn't needed
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pace ?? "--:--")
                            .font(.system(size: 20, weight: .black)).monospacedDigit()
                            .foregroundStyle(.black)
                        Text("PACE")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.4))
                    }
                    .frame(width: 110, alignment: .leading)

                    VStack(alignment: .center, spacing: 2) {
                        Text("\(day)/66")
                            .font(.system(size: 20, weight: .black)).monospacedDigit()
                            .foregroundStyle(.black)
                        Text("DAY")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.4))
                    }
                    .frame(width: 110, alignment: .center)

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(time)
                            .font(.system(size: 20, weight: .black)).monospacedDigit()
                            .foregroundStyle(.black)
                        Text("TIME")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.black.opacity(0.4))
                    }
                    .frame(width: 110, alignment: .trailing)
                }
                .padding(.horizontal, 20)
                .padding(.top, 32)

                // Big KM
                Text(String(format: "%.2f", km))
                    .font(.system(size: 100, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.top, 16)
                    .padding(.horizontal, 20)

                Text("KILOMETERS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.4))
                    .tracking(1.5)
                    .padding(.top, 4)

                // Pet + branding
                HStack(alignment: .bottom) {
                    PetAnimationView(dna: dna, pose: .jump, pixelSize: 5)
                        .frame(width: 80, height: 80)
                    Spacer()
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 28)
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 28)
            }
        }
        .frame(width: 390, height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}
