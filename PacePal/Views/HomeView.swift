import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @State private var showResetConfirm = false
    @State private var now: Date = Date()

    // Pose state machine
    @State private var currentPose: PetPose = .idle
    @State private var isAnimating = false

    // KM counter (animated display value)
    @State private var displayedKm: Double = 0.0
    @State private var lastKnownKm: Double = 0.0

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }

    // Energy: 100% on reset → 0% after 48h
    private var energy: Double { appState.energy(at: now) }

    private var energyColor: Color {
        if energy <= 0    { return Color(hex: "#E12D39") }  // red — dead
        switch energy {
        case 0.60...: return Color(hex: "#4ADE80")          // green
        case 0.30...: return Color(hex: "#A3E635")          // lime
        default:      return Color(hex: "#FCD34D")          // warm yellow
        }
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

    private var energyTimeLabel: String {
        let minutes = Int(36.0 * 60.0 * energy)
        guard minutes > 0 else { return "Sin energía" }
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return "\(m)m restantes" }
        if m == 0 { return "\(h)h restantes" }
        return "\(h)h \(m)m restantes"
    }

    private var normalPose: PetPose {
        if energy <= 0    { return .dead  }
        if energy >= 0.99 { return .hype  }   // ~100% — primeros ~29 min tras reset
        if energy > 0.95  { return .happy }   // 95–99%
        if energy > 0.90  { return .jump  }   // 90–95%
        if energy > 0.50  { return .idle  }   // 50–90%
        return .sad                           // 0–50%
    }

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                Spacer(minLength: 12)

                companionCard
                    .padding(.horizontal, 24)

                Spacer(minLength: 16)

                HStack(spacing: 12) {
                    kmCard
                    energyCard
                }
                .padding(.horizontal, 24)

                testButtons
                    .padding(.top, 12)
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
                if newVal < lastKnownKm { // new day reset
                    lastKnownKm = newVal
                    displayedKm = newVal
                }
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
        // If dead and not enough km to revive, skip
        if energy <= 0 && delta < 0.5 {
            lastKnownKm = newTotal
            displayedKm = newTotal
            return
        }

        isAnimating = true
        let startKm = displayedKm
        currentPose = .running

        // Count up by 0.1 increments (max ~3s total)
        let steps = max(1, Int((delta / 0.1).rounded()))
        let stepDelay = min(0.12, 3.0 / Double(steps))
        for i in 1...steps {
            displayedKm = min(startKm + Double(i) * 0.1, newTotal)
            try? await Task.sleep(for: .seconds(stepDelay))
        }
        displayedKm = newTotal
        lastKnownKm = newTotal

        // Boost energy if >= 0.5 km
        if delta >= 0.5 {
            appState.resetEnergy()
            now = Date()
        }

        // Celebration pose
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
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
            Spacer()
            Button {
                showResetConfirm = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "#616E7C"))
                    .padding(10)
                    .background(Color(hex: "#EDF0F4"))
                    .clipShape(Circle())
            }
            .confirmationDialog("Perfil", isPresented: $showResetConfirm) {
                Button("Reiniciar compañero", role: .destructive) {
                    saved.forEach { modelContext.delete($0) }
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

    // MARK: – Companion card
    private var companionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 18, y: 5)

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: dna.palette.body).opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 130, height: 22)
                        .blur(radius: 10)
                        .padding(.bottom, 30)

                    PetAnimationView(dna: dna, pose: currentPose, pixelSize: 10.5)
                        .id(dna.id)
                        .onTapGesture {
                            guard !isAnimating && currentPose != .dead else { return }
                            let savedPose = currentPose
                            currentPose = .hurt
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                if currentPose == .hurt { currentPose = savedPose }
                            }
                        }
                }
                .padding(.top, 20)

                Text(moodText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 4)
                    .animation(.easeInOut(duration: 0.4), value: energy)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – KM counter card
    private var kmCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#F9703E"))
                .shadow(color: Color(hex: "#F9703E").opacity(0.30), radius: 12, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text("HOY")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.65))

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", displayedKm))
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(duration: 0.3), value: displayedKm)
                    Text("km")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
    }

    // MARK: – Energy bar card
    private var energyCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("ENERGÍA")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                    Spacer()
                    Text("\(Int(energy * 100))%")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(energyColor)
                        .animation(.easeInOut(duration: 0.4), value: energy)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "#EDF0F4"))
                        RoundedRectangle(cornerRadius: 5)
                            .fill(energyColor)
                            .frame(width: geo.size.width * energy)
                            .animation(.spring(duration: 0.9), value: energy)
                    }
                }
                .frame(height: 8)

                Text(energyTimeLabel)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(energy <= 0 ? Color(hex: "#E12D39") : Color(hex: "#9AA5B4"))
                    .animation(.easeInOut(duration: 0.4), value: energy)
            }
            .padding(16)
        }
    }

    // MARK: – Test buttons
    private var testButtons: some View {
        VStack(spacing: 8) {
            // Energy presets — one per zone
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
                            .background(Color(hex: "#EDF0F4"))
                            .foregroundStyle(Color(hex: "#3E4C59"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 24)

            // KM button
            Button {
                health.addTestKm()
            } label: {
                Text("➕ 1 km")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 7)
                    .background(Color(hex: "#EDF0F4"))
                    .foregroundStyle(Color(hex: "#3E4C59"))
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
