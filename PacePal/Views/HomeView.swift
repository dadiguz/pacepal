import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @State private var showResetConfirm = false
    @State private var showHistory = false
    @State private var now: Date = Date()

    @State private var currentPose: PetPose = .idle
    @State private var isAnimating = false
    @State private var displayedKm: Double = 0.0
    @State private var lastKnownKm: Double = 0.0

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

                Spacer(minLength: 28)

                // ── Pet ──────────────────────────────────────────────────
                petSection

                Spacer(minLength: 16)

                // ── KM counter or dead screen ────────────────────────────
                if energy <= 0 {
                    retrySection
                } else {
                    kmSection
                }

                Spacer(minLength: 24)

                // ── Test buttons ─────────────────────────────────────────
                testButtons
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            displayedKm = health.todayKm
            lastKnownKm = health.todayKm
            currentPose = normalPose
        }
        .onChange(of: health.todayKm) { _, newVal in
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
            health.fetchToday()
            if !isAnimating { currentPose = normalPose }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            health.fetchToday()
        }
    }

    // MARK: – KM animation state machine
    @MainActor
    private func runKmAnimation(delta: Double, newTotal: Double) async {
        if energy <= 0 && delta < 0.5 {
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
        if delta >= 0.5 { appState.resetEnergy(); now = Date() }
        if delta > 1.0 {
            currentPose = .hype
            try? await Task.sleep(for: .seconds(1.6))
        } else if delta >= 0.5 {
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
                Text("PacePal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
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

            Button { showResetConfirm = true } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "#A09080"))
                    .padding(10)
                    .background(Color(hex: "#F5ECE4"))
                    .clipShape(Circle())
            }
            .confirmationDialog("Perfil", isPresented: $showResetConfirm) {
                Button("Reiniciar compañero", role: .destructive) {
                    saved.forEach { modelContext.delete($0) }
                    health.resetKm()
                    withAnimation(.spring(duration: 0.4)) {
                        appState.selectedCharacter = nil
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Quieres elegir un nuevo compañero?")
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
    }

    // MARK: – KM section (no card)
    private var kmSection: some View {
        VStack(spacing: 2) {
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
        }
    }

    // MARK: – Retry section (shown when dead)
    private var retrySection: some View {
        VStack(spacing: 12) {
            Text("\(dna.name) se quedó sin energía...")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
                .multilineTextAlignment(.center)

            Button {
                saved.forEach { modelContext.delete($0) }
                health.resetKm()
                withAnimation(.spring(duration: 0.4)) {
                    appState.selectedCharacter = nil
                }
            } label: {
                Text("Volver a intentarlo")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#F9703E"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
        }
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

#Preview {
    HomeView()
        .environment({
            let s = AppState()
            s.selectedCharacter = PetDNA.presets()[0]
            return s
        }())
        .environment(HealthManager())
}
