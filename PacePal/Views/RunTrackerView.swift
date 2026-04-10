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
            // Same background across ALL phases — no dark overlay
            Color(hex: "#F9F496").ignoresSafeArea()
            AppBackground(imageName: "pattern")
                .ignoresSafeArea()
                .opacity(0.30)

            Group {
                switch phase {
                case .idle:           idleView
                case .countdown(let n): countdownView(n)
                case .running:        runningView
                case .paused:         pausedView
                case .finished:       finishedView
                }
            }
            .id(phase)
            .transition(.opacity.animation(.easeInOut(duration: 0.5)))
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
        .onAppear {
            // Fresh state every time the view is presented
            tracker.reset()
            phase = .idle
            startHoldProgress = 0
            stopHoldProgress = 0
        }
    }

    // MARK: - Shared Nike-style header (Pace | Day | Time)

    private var nrcHeader: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tracker.formattedPace ?? "--:--")
                    .font(.system(size: 26, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                Text("Pace")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .center, spacing: 3) {
                Text("\(currentDay)/66")
                    .font(.system(size: 26, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                Text("Day")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .trailing, spacing: 3) {
                Text(tracker.formattedTime)
                    .font(.system(size: 26, weight: .black))
                    .monospacedDigit()
                    .foregroundStyle(.black)
                Text("Time")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.4))
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 32)
        .padding(.top, 60)
    }

    // MARK: - Shared KM block

    private var kmDisplay: some View {
        VStack(spacing: 6) {
            Text(String(format: "%.2f", tracker.distanceKm))
                .font(.system(size: 112, weight: .black))
                .foregroundStyle(.black)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3), value: tracker.distanceKm)
            Text("kilometers")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.4))
        }
    }

    // MARK: - Idle: hold-circle to start

    private var idleView: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(.black)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 52)

            Spacer()

            PetAnimationView(
                dna: displayDNA,
                pose: startHoldProgress > 0 ? .sign : .idle,
                pixelSize: 9
            )
            .frame(width: 200, height: 200)
            .animation(.easeInOut(duration: 0.2), value: startHoldProgress > 0)

            Spacer()

            Text(L("tracker.hold_to_start"))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.5))
                .padding(.bottom, 28)

            HoldCircle(
                progress: startHoldProgress,
                icon: "figure.run",
                color: Color(hex: "#F9703E"),
                size: 120
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in startHoldBegan() }
                    .onEnded   { _ in startHoldCancelled() }
            )
            .padding(.bottom, 60)
        }
    }

    // MARK: - Countdown

    private func countdownView(_ n: Int) -> some View {
        ZStack {
            VStack {
                Spacer()
                Text("\(n)")
                    .font(.system(size: 140, weight: .black))
                    .foregroundStyle(.black)
                    .id(n)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.4).combined(with: .opacity),
                        removal:   .scale(scale: 0.6).combined(with: .opacity)
                    ))
                Spacer()
            }
        }
    }

    // MARK: - Running

    private var runningView: some View {
        VStack(spacing: 0) {
            nrcHeader

            Spacer()

            kmDisplay

            // Pause button — below KM
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
    }

    // MARK: - Finished

    private var finishedView: some View {
        VStack(spacing: 0) {
            nrcHeader

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
    }

    // MARK: - Share (screenshot card + optional route)

    private func prepareShare() {
        Task { @MainActor in
            var routeImg: UIImage? = nil
            if tracker.routeCoordinates.count > 3 {
                routeImg = await makeRouteSnapshot(tracker.routeCoordinates)
            }
            let card = RunShareCard(
                km: tracker.distanceKm,
                time: tracker.formattedTime,
                pace: tracker.formattedPace,
                day: currentDay,
                dna: displayDNA,
                routeImage: routeImg
            )
            let renderer = ImageRenderer(content: card)
            renderer.scale = 3
            if let img = renderer.uiImage {
                shareText = ""          // unused when sharing image
                shareItems = [img]
                showShareSheet = true
            }
        }
    }

    private func makeRouteSnapshot(_ coords: [CLLocationCoordinate2D]) async -> UIImage? {
        let lats = coords.map { $0.latitude }
        let lons = coords.map { $0.longitude }
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return nil }

        let latPad = max((maxLat - minLat) * 0.25, 0.002)
        let lonPad = max((maxLon - minLon) * 0.25, 0.002)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                           longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(latitudeDelta: (maxLat - minLat) + latPad * 2,
                                   longitudeDelta: (maxLon - minLon) + lonPad * 2)
        )
        let opts = MKMapSnapshotter.Options()
        opts.region = region
        opts.size   = CGSize(width: 390, height: 220)
        opts.scale  = 3

        return await withCheckedContinuation { cont in
            MKMapSnapshotter(options: opts).start { snap, _ in
                guard let snap else { cont.resume(returning: nil); return }
                UIGraphicsBeginImageContextWithOptions(opts.size, true, opts.scale)
                defer { UIGraphicsEndImageContext() }
                snap.image.draw(at: .zero)
                if let ctx = UIGraphicsGetCurrentContext() {
                    ctx.setStrokeColor(UIColor(red: 0.98, green: 0.44, blue: 0.24, alpha: 1).cgColor)
                    ctx.setLineWidth(4); ctx.setLineCap(.round); ctx.setLineJoin(.round)
                    let pts = coords.map { snap.point(for: $0) }
                    ctx.move(to: pts[0]); pts.dropFirst().forEach { ctx.addLine(to: $0) }
                    ctx.strokePath()
                }
                cont.resume(returning: UIGraphicsGetImageFromCurrentImageContext())
            }
        }
    }

    // MARK: - Hold-to-start logic

    private func startHoldBegan() {
        guard phase == .idle, startHoldTimer == nil else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let interval = 0.05
        let total = 2.0
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
        startHoldTimer?.invalidate()
        startHoldTimer = nil
        withAnimation(.spring(duration: 0.3)) { startHoldProgress = 0 }
    }

    private func beginCountdown() {
        startHoldProgress = 0
        phase = .countdown(3)
        Task {
            for n in stride(from: 3, through: 1, by: -1) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                await MainActor.run { phase = .countdown(n) }
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
        let total = 2.0
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
        stopHoldTimer?.invalidate()
        stopHoldTimer = nil
        withAnimation(.spring(duration: 0.3)) { stopHoldProgress = 0 }
    }

    // MARK: - Finish

    private func finishAndSave() {
        stopHoldProgress = 0
        tracker.finish()
        let km = tracker.distanceKm
        if km > 0 {
            health.addManualKm(km)
            appState.addEnergy(km: km, at: Date())
            appState.syncToWidget(km: health.todayKm)
        }
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
    let routeImage: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            // Route map or gradient placeholder
            if let img = routeImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 210)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color(hex: "#F9703E").opacity(0.7), Color(hex: "#F9F496")],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .frame(height: 210)
                .overlay {
                    Image(systemName: "figure.run")
                        .font(.system(size: 70, weight: .black))
                        .foregroundStyle(.white.opacity(0.35))
                }
            }

            // Stats block
            VStack(spacing: 0) {
                // KM
                VStack(spacing: 4) {
                    Text(String(format: "%.2f", km))
                        .font(.system(size: 80, weight: .black))
                        .foregroundStyle(.black)
                        .monospacedDigit()
                    Text("kilometers")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.4))
                }
                .padding(.top, 24)

                // Secondary stats
                HStack(spacing: 32) {
                    VStack(spacing: 3) {
                        Text(time)
                            .font(.system(size: 22, weight: .black))
                            .monospacedDigit()
                            .foregroundStyle(.black)
                        Text("Time")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.4))
                    }
                    if let p = pace {
                        VStack(spacing: 3) {
                            Text(p)
                                .font(.system(size: 22, weight: .black))
                                .monospacedDigit()
                                .foregroundStyle(.black)
                            Text("Pace /km")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.4))
                        }
                    }
                    VStack(spacing: 3) {
                        Text("\(day)/66")
                            .font(.system(size: 22, weight: .black))
                            .monospacedDigit()
                            .foregroundStyle(.black)
                        Text("Day")
                            .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.4))
                    }
                }
                .padding(.top, 20)

                // Pet + branding
                HStack {
                    PetAnimationView(dna: dna, pose: .jump, pixelSize: 5)
                        .frame(width: 90, height: 90)
                    Spacer()
                    Text("PacePal")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#F9703E"))
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(hex: "#F9F496"))
        }
        .frame(width: 390)
        .background(Color(hex: "#F9F496"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}
