import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(PurchaseManager.self) private var store
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
    @State private var lastTrackedEnergy: Double = 1.0
    @State private var displayedKm: Double = 0.0
    @State private var lastKnownKm: Double = 0.0
    @State private var isInitialLoad = true
    @State private var phraseIndex: Int = Int.random(in: 0..<RunningPhrase.all.count)
    @State private var showPetStatus = false
    @State private var pendingAchievement: Achievement? = nil
    @State private var replayAchievement: Achievement? = nil
    @State private var deadAudioStarted = false

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }

    private var hasPhotoBackground: Bool { appState.selectedBackground != nil }

    private var energy: Double { appState.energy(at: now) }

    private var energyColor: Color {
        if energy <= 0    { return Color(hex: "#E12D39") }
        switch energy {
        case 0.60...: return Color(hex: "#4ADE80")
        case 0.30...: return Color(hex: "#A3E635")
        case 0.15...: return Color(hex: "#FCD34D")
        default:      return Color(hex: "#E12D39")   // 1–14%: rojo crítico
        }
    }

    private var energyTimeLabel: String {
        let minutes = Int(appState.decaySeconds / 60.0 * energy)
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
        case .angry: return "Está exigiendo que corras"
        case .sad:   return "La energía se acaba... ¡sal a correr!"
        case .dizzy: return "\(dna.name) está a punto de colapsar..."
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
        if energy > 0.25  { return .angry }
        if energy > 0.14  { return .sad   }
        return .dizzy
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────────
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 44)

                Spacer(minLength: 20)

                // ── Energy bar ───────────────────────────────────────────
                energySection
                    .padding(.horizontal, 28)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TutorialFrameKey.self,
                            value: ["energy": geo.frame(in: .global)])
                    })

                Spacer(minLength: 16)

                // ── Running phrase ────────────────────────────────────────
                phraseSection
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
                    .animation(.spring(duration: 0.45), value: phraseIndex)

                Spacer(minLength: 4)

                // ── Pet ──────────────────────────────────────────────────
                petSection

                Spacer(minLength: 16)

                // ── KM counter ───────────────────────────────────────────
                kmSection
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: TutorialFrameKey.self,
                            value: ["km": geo.frame(in: .global)])
                    })

                // ── Pet status pill ───────────────────────────────────────
                Button { showPetStatus = true } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(energyColor)
                        Text(moodText)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(hasPhotoBackground ? Color(hex: "#1F2933") : Color(hex: "#4A3F35"))
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(hasPhotoBackground ? Color(hex: "#1F2933").opacity(0.4) : Color(hex: "#4A3F35").opacity(0.4))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(hasPhotoBackground ? Color.white : energyColor.opacity(0.13))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(energyColor, lineWidth: 1.5))
                }
                .padding(.top, 10)
                .animation(.easeInOut(duration: 0.3), value: moodText)

                Spacer(minLength: 24)
            }
            .sheet(isPresented: $showPetStatus) {
                PetStatusSheet(dna: dna, moodText: moodText, energyColor: energyColor) { tapped in
                    showPetStatus = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                            replayAchievement = tapped
                        }
                    }
                }
                .presentationDetents([.fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationBackground { AppBackground() }
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

            // ── Achievement overlays (auto-trigger + replay) ──────────────
            if let achievement = pendingAchievement {
                AchievementModal(achievement: achievement, dna: dna) {
                    appState.markAchievementSeen(achievement.day)
                    withAnimation(.spring(duration: 0.35)) { pendingAchievement = nil }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }
            if let achievement = replayAchievement {
                AchievementModal(achievement: achievement, dna: dna) {
                    withAnimation(.spring(duration: 0.35)) { replayAchievement = nil }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .background { AppBackground(imageName: appState.selectedBackground) }
        .animation(.easeInOut(duration: 0.3), value: pendingAchievement?.day)
        .animation(.easeInOut(duration: 0.3), value: replayAchievement?.day)
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
            lastTrackedEnergy = appState.energy(at: Date())
            SoundManager.shared.stopMusic(fadeDuration: 1.2)
            if energy <= 0 {
                if !deadAudioStarted {
                    deadAudioStarted = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        SoundManager.shared.playDeathSequence(enabled: appState.soundsEnabled)
                    }
                }
            } else {
                SoundManager.shared.playRandomHappy(enabled: appState.soundsEnabled)
            }
            health.fetchToday()   // establece baseline al arrancar
            let imgURL = renderPetAttachmentURL(dna: dna, pose: currentPose)
            appState.scheduleNotifications(petName: dna.name, attachmentURL: imgURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                checkForAchievement()
            }
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
                appState.isFirstRunForCharacter = false
                let alreadyCounted = appState.kmCountedForEnergy
                let delta = newVal - alreadyCounted
                if delta > 0.01 {
                    // Uncounted km (new character or ran while app was closed): animate + add energy
                    displayedKm = alreadyCounted
                    lastKnownKm = alreadyCounted
                    Task { @MainActor in await runKmAnimation(delta: delta, newTotal: newVal) }
                } else {
                    // All km already counted in a previous session
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
        .onChange(of: appState.energyResetDate) { _, _ in
            now = Date()
            if !isAnimating { currentPose = normalPose }
            let newEnergy = appState.energy(at: Date())
            let imgURL = renderPetAttachmentURL(dna: dna, pose: currentPose)
            NotificationManager.fireIfThresholdCrossed(petName: dna.name, oldEnergy: lastTrackedEnergy, newEnergy: newEnergy, attachmentURL: imgURL)
            lastTrackedEnergy = newEnergy
            appState.scheduleNotifications(petName: dna.name, attachmentURL: imgURL)
        }
        .onReceive(
            Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        ) { date in
            now = date
            if energy > 0 {
                health.fetchToday()
                if !isAnimating { currentPose = normalPose }
            }
            checkForAchievement()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
        ) { _ in
            if energy > 0 { health.fetchToday() }
        }
        .onChange(of: normalPose) { oldPose, newPose in
            // Always stop looping SFX immediately when entering dead state (before isAnimating guard)
            if newPose == .dead && !deadAudioStarted {
                deadAudioStarted = true
                SoundManager.shared.playDeathSequence(enabled: appState.soundsEnabled)
            }

            guard !isAnimating else { return }

            // Stop looping SFX when leaving a looping-sound pose
            if (oldPose == .sad || oldPose == .dizzy) && newPose != .sad && newPose != .dizzy {
                SoundManager.shared.stopSFX()
            }
            if oldPose == .dead && newPose != .dead {
                deadAudioStarted = false
                if SoundManager.shared.currentMusicName != "pacepal" {
                    SoundManager.shared.stopMusic(fadeDuration: 1.0)
                }
            }
            switch newPose {
            case .dead: break  // handled above the guard
            case .dizzy: SoundManager.shared.play(.dizzy,  enabled: appState.soundsEnabled, loop: true)
            case .sad:   SoundManager.shared.play(.crying, enabled: appState.soundsEnabled, loop: true)
            case .angry: SoundManager.shared.play(.angry,  enabled: appState.soundsEnabled)
            default: break
            }
        }
        .onChange(of: pendingAchievement) { _, achievement in
            guard let achievement else { return }
            if achievement.day == 66 {
                SoundManager.shared.play(.day66, enabled: appState.soundsEnabled)
            } else {
                SoundManager.shared.play(.achievement, enabled: appState.soundsEnabled)
            }
        }
    }

    // MARK: – Achievement check

    private func checkForAchievement() {
        guard pendingAchievement == nil, !showPetStatus else { return }
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
            pendingAchievement = appState.pendingAchievement
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
        SoundManager.shared.play(.running, enabled: appState.soundsEnabled)
        let steps = max(1, Int((delta / 0.1).rounded()))
        let stepDelay = min(0.12, 3.0 / Double(steps))
        for i in 1...steps {
            displayedKm = min(startKm + Double(i) * 0.1, newTotal)
            try? await Task.sleep(for: .seconds(stepDelay))
        }
        displayedKm = newTotal
        lastKnownKm = newTotal
        appState.addEnergy(km: delta)
        appState.recordKmCounted(newTotal)
        now = Date()
        if energy >= 0.99 {
            currentPose = .hype
            SoundManager.shared.play(.hype, enabled: appState.soundsEnabled)
            try? await Task.sleep(for: .seconds(1.6))
        } else if delta >= 0.3 {
            currentPose = .jump
            SoundManager.shared.play(.jump, enabled: appState.soundsEnabled)
            try? await Task.sleep(for: .seconds(0.8))
        }
        isAnimating = false
        currentPose = normalPose
        appState.confirmChallengeStart()
        checkForAchievement()
    }

    // MARK: – Top bar
    private var topBar: some View {
        HStack(alignment: .center) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)
            Spacer()
            Button { showHistory = true } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(hasPhotoBackground ? Color(hex: "#3D3D3D") : Color(hex: "#A09080"))
                    .padding(10)
                    .background(hasPhotoBackground ? Color.white : Color(hex: "#F5ECE4"))
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
                    .foregroundStyle(hasPhotoBackground ? Color(hex: "#3D3D3D") : Color(hex: "#A09080"))
                    .padding(10)
                    .background(hasPhotoBackground ? Color.white : Color(hex: "#F5ECE4"))
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
                .environment(store)
            }
        }
    }

    // MARK: – Energy section (Pokémon HUD card)
    private var energySection: some View {
        let dayNum = max(1, (Calendar.current.dateComponents([.day],
            from: appState.challengeStartDate, to: Date()).day ?? 0) + 1)

        return VStack(alignment: .leading, spacing: 14) {
            // ── Name + Day row ────────────────────────────────────────────
            HStack(alignment: .firstTextBaseline) {
                Text(dna.name.uppercased())
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                Text("DÍA: \(String(format: "%02d", dayNum))/66")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.55))
            }

            // ── HP bar row ────────────────────────────────────────────────
            HStack(spacing: 10) {
                Text("HP")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(energyColor)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.12))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [energyColor.opacity(0.75), energyColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * energy)
                            .animation(.spring(duration: 0.9), value: energy)
                        RoundedRectangle(cornerRadius: 4)
                            .strokeBorder(Color.white.opacity(0.70), lineWidth: 2)
                    }
                }
                .frame(height: 13)

                Text("\(Int(energy * 100))%")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(energyColor)
                    .frame(width: 40, alignment: .trailing)
                    .animation(.easeInOut(duration: 0.4), value: energy)
            }

            // ── Time remaining ────────────────────────────────────────────
            Text(energyTimeLabel)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(energy <= 0 ? Color(hex: "#FF6B6B") : .white.opacity(0.38))
                .animation(.easeInOut(duration: 0.4), value: energy)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#2B2420"))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.78), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
        )
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

            PetAnimationView(dna: dna, pose: currentPose, pixelSize: 9.07)
                .id(dna.id)
                .onTapGesture {
                    guard !isAnimating && currentPose != .dead else { return }
                    let saved = currentPose
                    currentPose = .hurt
                    SoundManager.shared.play(.hurt, enabled: appState.soundsEnabled)
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

    // MARK: – Phrase section
    private var phraseSection: some View {
        Text(RunningPhrase.all[phraseIndex].es)
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .foregroundStyle(hasPhotoBackground ? .white : Color(hex: "#7A6E68"))
            .shadow(color: hasPhotoBackground ? .black.opacity(0.80) : .clear, radius: 12, x: 0, y: 2)
            .shadow(color: hasPhotoBackground ? .black.opacity(0.50) : .clear, radius: 4, x: 0, y: 1)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .onTapGesture {
                UIPasteboard.general.string = RunningPhrase.all[phraseIndex].es
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .id(phraseIndex)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .offset(y: 10)),
                removal:   .opacity.combined(with: .offset(y: -6))
            ))
    }

    // MARK: – KM section (no card)
    private var kmSection: some View {
        HStack(alignment: .center, spacing: 8) {
            Button { health.fetchToday() } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#F9703E"))
                    .frame(width: 34, height: 34)
                    .background(hasPhotoBackground ? Color.white : Color(hex: "#F5ECE4"))
                    .clipShape(Circle())
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", displayedKm))
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                    .shadow(color: hasPhotoBackground ? .black.opacity(0.55) : .clear, radius: 6, x: 0, y: 1)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.3), value: displayedKm)
                Text("km")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E").opacity(0.65))
                    .shadow(color: hasPhotoBackground ? .black.opacity(0.45) : .clear, radius: 4, x: 0, y: 1)
                    .padding(.bottom, 6)
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
                    PetAnimationView(dna: dna, pose: .dead, pixelSize: 9.07)
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
                    SoundManager.shared.cancelDeathSequence()
                    SoundManager.shared.playMusic(name: "pacepal", enabled: appState.soundsEnabled)
                    appState.onCharacterSelected()
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

// MARK: - Pet Status Sheet

private struct PetStatusSheet: View {
    let dna: PetDNA
    let moodText: String
    let energyColor: Color
    var onAchievementTapped: (Achievement) -> Void = { _ in }

    @Environment(HealthManager.self) private var health
    @Environment(AppState.self) private var appState

    private var bodyColor: Color { Color(hex: dna.palette.body) }

    var body: some View {
        ScrollView {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            // Pet name
            Text(dna.name.uppercased())
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(Color(hex: "#1F2933"))

            // Archetype pill
            Text(dna.animalType.archetypeLabel.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(bodyColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(bodyColor.opacity(0.12))
                .clipShape(Capsule())
                .padding(.top, 6)

            // Mood row
            HStack(spacing: 6) {
                Circle()
                    .fill(energyColor)
                    .frame(width: 7, height: 7)
                Text(moodText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
            .padding(.top, 8)

            Spacer().frame(height: 24)

            // Stats — dark HUD card
            HStack(spacing: 0) {
                statCell(value: "\(health.totalRuns)", label: "Carreras")
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                statCell(value: String(format: "%.1f", health.totalKmAllTime), label: "km totales")
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                statCell(value: "\(health.bestStreak)", label: "Mejor racha")
            }
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#2B2420"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.78), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
            )
            .padding(.horizontal, 24)

            // Achievements
            VStack(alignment: .leading, spacing: 10) {
                Text("LOGROS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                    .padding(.horizontal, 24)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Achievement.all) { a in
                        let unlocked = appState.seenAchievements.contains(a.day)
                        Button {
                            if unlocked { onAchievementTapped(a) }
                        } label: {
                            VStack(spacing: 5) {
                                ZStack {
                                    Circle()
                                        .fill(unlocked
                                              ? Color(hex: "#F9703E").opacity(0.12)
                                              : Color(hex: "#F0F4F8"))
                                        .frame(width: 46, height: 46)
                                    Image(systemName: unlocked ? "star.fill" : "lock.fill")
                                        .font(.system(size: unlocked ? 16 : 13, weight: .semibold))
                                        .foregroundStyle(unlocked
                                                         ? Color(hex: "#F9703E")
                                                         : Color(hex: "#CBD2D9"))
                                }
                                Text("Día \(a.day)")
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(unlocked
                                                     ? Color(hex: "#F9703E")
                                                     : Color(hex: "#CBD2D9"))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 20)

            Spacer().frame(height: 32)
        }
        } // ScrollView
        .task {
            await health.fetchRunStats(since: appState.challengeStartDate)
        }
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(Color.white)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Achievement Modal

private struct AchievementModal: View {
    let achievement: Achievement
    let dna: PetDNA
    let onDismiss: () -> Void

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background photo — pinned to exact screen size
                Image(achievement.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0.15), Color.black.opacity(0.65)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(spacing: 0) {
                    Spacer().frame(height: 132)

                    // Day badge
                    Text("DÍA \(achievement.day) / 66")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.18))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))

                    // Phrase
                    achievement.displayText
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.black.opacity(0.55), radius: 6, x: 0, y: 2)
                        .frame(width: 280)
                        .padding(.top, 24)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                    Spacer()

                    // Pet
                    PetAnimationView(dna: dna, pose: achievement.pose, pixelSize: 7)
                        .scaleEffect(appeared ? 1.0 : 0.8)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                        .padding(.bottom, 32)

                    // CTA
                    Button(action: onDismiss) {
                        Text("¡Vamos!")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 48)
                            .padding(.vertical, 16)
                    }
                    .foregroundStyle(.white)
                    .background(Color(hex: "#F9703E"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.black.opacity(0.3), radius: 12, y: 5)
                    .padding(.bottom, 76)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation { appeared = true }
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
