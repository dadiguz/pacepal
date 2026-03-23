import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @State private var showHistory = false
    @State private var showSettings = false
    @State private var now: Date = Date()

    @State private var showTutorial = false
    @State private var tutorialStep = 0
    @State private var tutorialFrames: [String: CGRect] = [:]

    @State private var currentPose: PetPose = .idle
    @State private var isAnimating = false
    @State private var displayedKm: Double = 0.0
    @State private var lastKnownKm: Double = 0.0
    @State private var isInitialLoad = true

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }

    private var energy: Double { appState.energy(at: now) }

    private var energyColor: Color {
        if energy <= 0    { return Color(hex: "#E12D39") }
        switch energy {
        case 0.60...: return Color(hex: "#4ADE80")
        case 0.30...: return Color(hex: "#A3E635")
        default:      return Color(hex: "#FCD34D")
        }
    }

    private var energyTimeLabel: String {
        let minutes = Int(36.0 * 60.0 * energy)
        guard minutes > 0 else { return "Sin energía" }
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m restantes" }
        if m == 0 { return "\(h)h restantes" }
        return "\(h)h \(m)m restantes"
    }

    private var moodText: String {
        switch normalPose {
        case .hype:  return "¡\(dna.name) está en su mejor momento!"
        case .happy: return "\(dna.name) está feliz, ¡sigamos!"
        case .jump:  return "\(dna.name) tiene energía, ¿corremos?"
        case .idle:  return "\(dna.name) está listo para correr"
        case .sad:   return "La energía se acaba... ¡sal a correr!"
        case .dead:  return "\(dna.name) está exhausto... ¡ve a correr!"
        default:     return "\(dna.name) está listo"
        }
    }

    private var normalPose: PetPose {
        if energy <= 0    { return .dead  }
        if energy >= 0.99 { return .hype  }
        if energy > 0.95  { return .happy }
        if energy > 0.90  { return .jump  }
        if energy > 0.50  { return .idle  }
        return .sad
    }

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────────
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                Spacer(minLength: 20)

                // ── Energy bar ───────────────────────────────────────────
                energySection
                    .padding(.horizontal, 28)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TutorialFrameKey.self,
                            value: ["energy": geo.frame(in: .global)])
                    })

                Spacer(minLength: 28)

                // ── Pet ──────────────────────────────────────────────────
                petSection

                Spacer(minLength: 16)

                // ── KM counter ───────────────────────────────────────────
                kmSection
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TutorialFrameKey.self,
                            value: ["km": geo.frame(in: .global)])
                    })

                Spacer(minLength: 24)

                // ── Test buttons ─────────────────────────────────────────
                testButtons
                    .padding(.bottom, 48)
            }

            // ── Game Over overlay ─────────────────────────────────────────
            if energy <= 0 {
                gameOverOverlay
                    .transition(.opacity)
                    .zIndex(5)
            }

            // ── Tutorial overlay ──────────────────────────────────────────
            if showTutorial {
                TutorialOverlayView(
                    step: tutorialStep,
                    frames: tutorialFrames,
                    onNext: {
                        if tutorialStep < tutorialSteps.count - 1 {
                            withAnimation { tutorialStep += 1 }
                        } else {
                            finishTutorial()
                        }
                    },
                    onSkip: { finishTutorial() }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .onPreferenceChange(TutorialFrameKey.self) { tutorialFrames = $0 }
        .onChange(of: appState.selectedCharacter?.id) { _, _ in
            isInitialLoad = true
            lastKnownKm  = 0
            displayedKm  = 0
            currentPose  = normalPose
            health.fetchToday()   // establece baseline inmediatamente
        }
        .onAppear {
            isInitialLoad = true
            currentPose = normalPose
            health.fetchToday()   // establece baseline al arrancar
            if !UserDefaults.standard.bool(forKey: "hasSeenTutorial") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation { showTutorial = true }
                }
            }
        }
        .onChange(of: health.todayKm) { _, newVal in
            guard energy > 0 else { return }

            // First fetch after launch/appear
            if isInitialLoad {
                isInitialLoad = false
                if appState.isFirstRunForCharacter && newVal > 0.01 {
                    // New character: animate existing km and add energy
                    appState.isFirstRunForCharacter = false
                    displayedKm = 0
                    lastKnownKm = 0
                    Task { @MainActor in await runKmAnimation(delta: newVal, newTotal: newVal) }
                } else {
                    // App relaunch: silently sync, energy was already counted
                    appState.isFirstRunForCharacter = false
                    displayedKm = newVal
                    lastKnownKm = newVal
                }
                return
            }

            let delta = newVal - lastKnownKm
            guard delta > 0.01 else {
                if newVal < lastKnownKm { lastKnownKm = newVal; displayedKm = newVal }
                return
            }
            guard !isAnimating else { return }
            Task { @MainActor in await runKmAnimation(delta: delta, newTotal: newVal) }
        }
        .onReceive(
            Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        ) { date in
            now = date
            if energy > 0 {
                health.fetchToday()
                if !isAnimating { currentPose = normalPose }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            if energy > 0 { health.fetchToday() }
        }
    }

    // MARK: – Tutorial
    func startTutorial() {
        tutorialStep = 0
        withAnimation { showTutorial = true }
    }

    private func finishTutorial() {
        withAnimation { showTutorial = false }
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
    }

    // MARK: – KM animation state machine
    @MainActor
    private func runKmAnimation(delta: Double, newTotal: Double) async {
        if energy <= 0 && delta < 0.1 {
            lastKnownKm = newTotal; displayedKm = newTotal; return
        }
        isAnimating = true
        let startKm = displayedKm
        currentPose = .running
        let steps = max(1, Int((delta / 0.1).rounded()))
        let stepDelay = min(0.12, 3.0 / Double(steps))
        for i in 1...steps {
            displayedKm = min(startKm + Double(i) * 0.1, newTotal)
            try? await Task.sleep(for: .seconds(stepDelay))
        }
        displayedKm = newTotal
        lastKnownKm = newTotal
        appState.addEnergy(km: delta); now = Date()
        if energy >= 0.99 {
            currentPose = .hype
            try? await Task.sleep(for: .seconds(1.6))
        } else if delta >= 0.3 {
            currentPose = .jump
            try? await Task.sleep(for: .seconds(0.8))
        }
        isAnimating = false
        currentPose = normalPose
    }

    // MARK: – Top bar
    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                Text("Día 1 / 66")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#B0A090"))
            }
            Spacer()
            Button { showHistory = true } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "#A09080"))
                    .padding(10)
                    .background(Color(hex: "#F5ECE4"))
                    .clipShape(Circle())
            }
            .sheet(isPresented: $showHistory) {
                HistoryView()
                    .environment(appState)
                    .environment(health)
            }

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "#A09080"))
                    .padding(10)
                    .background(Color(hex: "#F5ECE4"))
                    .clipShape(Circle())
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(onShowTutorial: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startTutorial()
                    }
                })
                .environment(appState)
                .environment(health)
            }
        }
    }

    // MARK: – Energy section (no card)
    private var energySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("ENERGÍA")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(Color(hex: "#B0A090"))
                Spacer()
                Text("\(Int(energy * 100))%")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(energyColor)
                    .animation(.easeInOut(duration: 0.4), value: energy)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "#F0E8E0"))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(energyColor)
                        .frame(width: geo.size.width * energy)
                        .animation(.spring(duration: 0.9), value: energy)
                }
            }
            .frame(height: 12)

            Text(energyTimeLabel)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(energy <= 0 ? Color(hex: "#E12D39") : Color(hex: "#B0A090"))
                .animation(.easeInOut(duration: 0.4), value: energy)
        }
    }

    // MARK: – Pet section (no card)
    private var petSection: some View {
        ZStack(alignment: .bottom) {
            // Ground shadow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: dna.palette.body).opacity(0.25), .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 160, height: 28)
                .blur(radius: 12)
                .padding(.bottom, 8)

            PetAnimationView(dna: dna, pose: currentPose, pixelSize: 11)
                .id(dna.id)
                .onTapGesture {
                    guard !isAnimating && currentPose != .dead else { return }
                    let saved = currentPose
                    currentPose = .hurt
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                        if currentPose == .hurt { currentPose = saved }
                    }
                }
        }
        // Hide visually when dead (layout space is preserved)
        .opacity(energy <= 0 ? 0 : 1)
        // Capture frame for game over overlay positioning
        .background(GeometryReader { geo in
            Color.clear.preference(key: TutorialFrameKey.self,
                value: ["pet": geo.frame(in: .global)])
        })
    }

    // MARK: – KM section (no card)
    private var kmSection: some View {
        VStack(spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", displayedKm))
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: displayedKm)
                Text("km")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E").opacity(0.65))
                    .padding(.bottom, 6)
            }
            Text(moodText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#B0A090"))
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.4), value: energy)

            Button {
                health.fetchToday()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Sincronizar")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Color(hex: "#A09080"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Color(hex: "#F5ECE4"))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: – Game Over overlay
    private var gameOverOverlay: some View {
        let pf = tutorialFrames["pet"] ?? .zero

        return ZStack {
            // Dark backdrop — blocks all taps
            Color.black.opacity(0.90)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            if pf != .zero {
                // Spotlight cone: top at safe area, bottom at pet frame
                let coneHeight = max(60, pf.maxY - 52)
                let coneCenterY = 52 + coneHeight / 2

                SpotlightCone()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color(hex: "#A8C8FF").opacity(0.12),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 260, height: coneHeight)
                    .position(x: pf.midX, y: coneCenterY)

                // Diffused glow at the cone's top (light source)
                Ellipse()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 48, height: 16)
                    .blur(radius: 18)
                    .position(x: pf.midX, y: 57)

                // Halo on the ground where light lands
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.18), .clear],
                            center: .center, startRadius: 0, endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 40)
                    .blur(radius: 8)
                    .position(x: pf.midX, y: pf.midY + 44)

                // Dead pet at exact petSection position
                ZStack(alignment: .bottom) {
                    PetAnimationView(dna: dna, pose: .dead, pixelSize: 11)
                    // Floating shadow below canvas
                    Ellipse()
                        .fill(Color.black.opacity(0.65))
                        .frame(width: 76, height: 10)
                        .blur(radius: 10)
                        .offset(y: 18)
                }
                .position(x: pf.midX, y: pf.midY - 26)
            }

            // Message + button pinned to bottom
            VStack(spacing: 0) {
                Spacer()
                Text("\(dna.name) se quedó sin energía...")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.80))
                Spacer().frame(height: 32)
                Button {
                    saved.forEach { modelContext.delete($0) }
                    health.resetKm()
                    withAnimation(.spring(duration: 0.4)) {
                        appState.selectedCharacter = nil
                    }
                } label: {
                    Text("Volver a intentarlo")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.45), radius: 16, y: 6)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 52)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: energy <= 0)
    }

    // MARK: – Test buttons
    private var testButtons: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach([
                    ("100%", 1.00),
                    ("96%",  0.96),
                    ("92%",  0.92),
                    ("70%",  0.70),
                    ("25%",  0.25),
                    ("0%",   0.00),
                ], id: \.0) { label, value in
                    Button {
                        appState.setEnergy(value)
                        now = Date()
                        if !isAnimating { currentPose = normalPose }
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(Color(hex: "#F5ECE4"))
                            .foregroundStyle(Color(hex: "#8A7060"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 24)

            Button { health.addTestKm() } label: {
                Text("➕ 1 km")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#F5ECE4"))
                    .foregroundStyle(Color(hex: "#8A7060"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Spotlight cone shape (trapezoid: narrow top, wide bottom)
private struct SpotlightCone: Shape {
    func path(in rect: CGRect) -> Path {
        let topInset = rect.width * 0.42
        var p = Path()
        p.move(to:    CGPoint(x: rect.minX + topInset,     y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - topInset,     y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX,                y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX,                y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    HomeView()
        .environment({
            let s = AppState()
            s.selectedCharacter = PetDNA.presets()[0]
            return s
        }())
        .environment(HealthManager())
}
