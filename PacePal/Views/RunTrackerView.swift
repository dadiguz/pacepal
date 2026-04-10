import SwiftUI
import CoreLocation
import MapKit

// MARK: - Phase

private enum TrackerPhase: Equatable, Hashable {
    case idle
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
    @State private var showShareSheet = false
    @State private var shareText = ""
    @State private var shareItems: [Any] = []
    @State private var pendingKm: Double = 0        // applied on dismiss so HomeView animates
    @State private var showHoldToast = false

    // Hold-to-start
    @State private var startHoldProgress: Double = 0
    @State private var startHoldTimer: Timer? = nil

    // Hold-to-stop
    @State private var stopHoldProgress: Double = 0
    @State private var stopHoldTimer: Timer? = nil

    private var displayDNA: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }
    private var currentDay: Int { min(66, appState.completedDays + 1) }

    private var currentPose: PetPose {
        switch phase {
        case .idle, .countdown: return .idle
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
            .opacity(phase == .idle ? 1 : 0)
            .allowsHitTesting(phase == .idle)
            .animation(.easeInOut(duration: 0.2), value: phase == .idle)
        }
        .sheet(isPresented: $showShareSheet) {
            RunShareSheet(items: shareItems.isEmpty ? [shareText] : shareItems)
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
                showLocationAlert = true
            }
        }
        .overlay(alignment: .top) {
            if showHoldToast {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text(L("tracker.hold_toast"))
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

            Spacer()

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
                .padding(.bottom, 76)
        }
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
        if let img = renderer.uiImage,
           let data = img.pngData() {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("pacepal_run.png")
            if (try? data.write(to: url)) != nil {
                shareItems = [url]
            } else {
                shareItems = [img]
            }
        } else {
            shareItems = ["\(String(format: "%.2f", tracker.distanceKm)) km — Day \(currentDay)/66 #PacePal"]
        }
        showShareSheet = true
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
        showHoldToast = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { showHoldToast = false }
        }
    }

    private func beginCountdown() {
        startHoldProgress = 0
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

// MARK: - Share sheet

private struct RunShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
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
