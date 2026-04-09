import SwiftUI
import SwiftData

// MARK: - Red pulse overlay for low energy
private struct RedPulseOverlay: View {
    let visible: Bool
    @State private var pulse = false

    var body: some View {
        Color.red
            .opacity(visible ? (pulse ? 0.35 : 0.08) : 0)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.3), value: visible)
            .task(id: visible) {
                pulse = false
                guard visible else { return }
                try? await Task.sleep(for: .seconds(0.05))
                withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(PurchaseManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @State private var showHistory = false
    @State private var showSettings = false
    @State private var langRefresh = UUID()
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
    @State private var showMedalTutorial = false
    @State private var pendingTipDay: Int? = nil
    @State private var showRedPulse = false

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }

    private var hasPhotoBackground: Bool { appState.selectedBackground != nil && appState.selectedBackground != "pattern" }

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
        if appState.medalEarned { return L("medal.energy_permanent") }
        let minutes = Int(appState.decaySeconds / 60.0 * energy)
        guard minutes > 0 else { return L("home.no_energy") }
        let h = minutes / 60
        let m = minutes % 60
        if h == 0 { return L("home.time_minutes", m) }
        if m == 0 { return L("home.time_hours", h) }
        return L("home.time_hours_minutes", h, m)
    }

    private var moodText: String {
        switch normalPose {
        case .hype:  return L("home.mood_hype", dna.name)
        case .happy: return L("home.mood_happy", dna.name)
        case .jump:  return L("home.mood_jump", dna.name)
        case .idle:  return L("home.mood_idle", dna.name)
        case .angry: return L("home.mood_angry")
        case .sad:   return L("home.mood_sad")
        case .dizzy: return L("home.mood_dizzy", dna.name)
        case .dead:  return L("home.mood_dead", dna.name)
        default:     return L("home.mood_default", dna.name)
        }
    }

    private var normalPose: PetPose {
        if appState.medalEarned { return .idle }
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
                AchievementModal(achievement: achievement, dna: dna, isFirstTime: true, todayKm: health.todayKm) {
                    appState.markAchievementSeen(achievement.day)
                    withAnimation(.spring(duration: 0.35)) { pendingAchievement = nil }
                    if achievement.day == 66 {
                        appState.grantMedal()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(.spring(duration: 0.4)) { showMedalTutorial = true }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }
            if let achievement = replayAchievement {
                AchievementModal(achievement: achievement, dna: dna, isFirstTime: false, todayKm: health.todayKm) {
                    withAnimation(.spring(duration: 0.35)) { replayAchievement = nil }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(20)
            }

            // ── Daily tip modal ─────────────────────────────────────────
            if let tipDay = pendingTipDay {
                DailyTipModal(day: tipDay, dna: dna) {
                    appState.markTipSeen(tipDay)
                    withAnimation(.spring(duration: 0.35)) { pendingTipDay = nil }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(18)
            }

            // ── Medal tutorial (shown after day 66 modal dismiss) ────────
            if showMedalTutorial {
                MedalTutorialOverlay {
                    withAnimation(.spring(duration: 0.35)) { showMedalTutorial = false }
                }
                .transition(.opacity)
                .zIndex(25)
            }
        }
        .background { AppBackground(imageName: appState.selectedBackground) }
        .overlay {
            RedPulseOverlay(visible: showRedPulse)
        }
        .onChange(of: appState.energyResetDate) { _, _ in
            let e = appState.energy(at: Date())
            showRedPulse = e > 0 && e < 0.10
        }
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
            showRedPulse = energy > 0 && energy < 0.10
            appState.syncToWidget(km: health.todayKm)
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
        .onChange(of: health.todayKm) { _, km in
            appState.syncToWidget(km: km)
        }
        .onChange(of: appState.energyResetDate) { _, _ in
            now = Date()
            if !isAnimating { currentPose = normalPose }
            let newEnergy = appState.energy(at: Date())
            let imgURL = renderPetAttachmentURL(dna: dna, pose: currentPose)
            NotificationManager.fireIfThresholdCrossed(petName: dna.name, oldEnergy: lastTrackedEnergy, newEnergy: newEnergy, attachmentURL: imgURL)
            lastTrackedEnergy = newEnergy
            appState.scheduleNotifications(petName: dna.name, attachmentURL: imgURL)
            appState.syncToWidget(km: health.todayKm)
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
        if let ach = appState.pendingAchievement {
            withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                pendingAchievement = ach
            }
        } else {
            checkForTip()
        }
    }

    private func checkForTip() {
        guard pendingTipDay == nil, pendingAchievement == nil, !showPetStatus, !showMedalTutorial else { return }
        if let day = appState.pendingTip {
            withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
                pendingTipDay = day
            }
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
            .sheet(isPresented: $showSettings, onDismiss: { langRefresh = UUID() }) {
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
            .id(langRefresh)
        }
    }

    // MARK: – Energy section (Pokémon HUD card)
    private var energySection: some View {
        return VStack(alignment: .leading, spacing: 14) {
            // ── Name + Day row ────────────────────────────────────────────
            HStack(alignment: .firstTextBaseline) {
                Text(dna.name.uppercased())
                    .font(.system(size: 20, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 6) {
                    if appState.medalEarned {
                        Image(systemName: "medal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color(hex: "#FFD700"))
                    }
                    Text(L("home.day_counter", String(format: "%02d", appState.medalEarned ? 66 : min(66, appState.completedDays + 1))))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            // ── HP bar row ────────────────────────────────────────────────
            HStack(spacing: 10) {
                Text(L("home.hp"))
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

            PetAnimationView(dna: dna, pose: currentPose, pixelSize: 9.07,
                             accessories: appState.medalEarned ? [.medal66] : [])
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
    private func styledPhrase(_ text: String) -> Text {
        let keyword = "pacepal"
        let baseColor = hasPhotoBackground ? Color.white : Color(hex: "#7A6E68")
        let parts = text.components(separatedBy: keyword)
        var result = Text("")
        for (i, part) in parts.enumerated() {
            result = result + Text(part).foregroundStyle(baseColor)
            if i < parts.count - 1 {
                result = result + Text(keyword)
                    .foregroundStyle(Color(hex: "#F9703E"))
                    .bold()
            }
        }
        return result
    }

    private var phraseSection: some View {
        styledPhrase(RunningPhrase.all[phraseIndex].localized)
            .font(.system(size: 20, weight: .regular, design: .rounded))
            .shadow(color: hasPhotoBackground ? .black.opacity(0.80) : .clear, radius: 12, x: 0, y: 2)
            .shadow(color: hasPhotoBackground ? .black.opacity(0.50) : .clear, radius: 4, x: 0, y: 1)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .onTapGesture {
                UIPasteboard.general.string = RunningPhrase.all[phraseIndex].localized
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
                Text(L("home.km"))
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
                Text(L("home.game_over", dna.name))
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
                    Text(L("home.retry"))
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
                statCell(value: "\(health.totalRuns)", label: L("home.stat_runs"))
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                statCell(value: String(format: "%.1f", health.totalKmAllTime), label: L("home.stat_total_km"))
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                statCell(value: "\(health.bestStreak)", label: L("home.stat_best_streak"))
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
                Text(L("home.achievements_title"))
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
                                Text(L("common.day_n", a.day))
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
            appState.updateCompletedDays(health.totalRuns)
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
    let isFirstTime: Bool
    let todayKm: Double
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var isRendering = false

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
                    Text(L("home.achievement_badge", achievement.day))
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

                    // Buttons
                    HStack(spacing: 12) {
                        // Share button (first time only)
                        if isFirstTime {
                            Button {
                                guard !isRendering else { return }
                                isRendering = true
                                Task {
                                    let img = Self.renderShareImage(achievement: achievement, dna: dna, todayKm: todayKm)
                                    shareImage = img
                                    isRendering = false
                                    showShareSheet = true
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    if isRendering {
                                        ProgressView()
                                            .tint(Color(hex: "#F9703E"))
                                    } else {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    Text(L("share.button"))
                                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .foregroundStyle(Color(hex: "#F9703E"))
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.black.opacity(0.25), radius: 10, y: 4)
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
                        }

                        // CTA
                        Button(action: onDismiss) {
                            Text(L("home.achievement_dismiss"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                        }
                        .foregroundStyle(.white)
                        .background(Color(hex: "#F9703E"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.black.opacity(0.3), radius: 12, y: 5)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.3).delay(0.3), value: appeared)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 56)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation { appeared = true }
        }
        .sheet(isPresented: $showShareSheet) {
            if let shareImage {
                ShareSheet(image: shareImage)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: – Render shareable image

    @MainActor
    private static func renderShareImage(achievement: Achievement, dna: PetDNA, todayKm: Double) -> UIImage {
        let w: CGFloat = 1080
        let h: CGFloat = 1920

        let grid = buildCharacterGrid(dna: dna, pose: achievement.pose, frame: 0)
        let view = AchievementShareCard(
            achievement: achievement,
            dna: dna,
            petGrid: grid,
            todayKm: todayKm,
            width: w,
            height: h
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.uiImage ?? UIImage()
    }
}

// MARK: – Share card (rendered to image)

private struct AchievementShareCard: View {
    let achievement: Achievement
    let dna: PetDNA
    let petGrid: PetGrid
    let todayKm: Double
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            Image(achievement.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: height)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.10), Color.black.opacity(0.70)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 0) {
                // Logo at top
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 64)
                    .opacity(0.6)
                    .padding(.top, height * 0.08)

                Spacer().frame(height: height * 0.04)

                // Day badge
                Text(L("home.achievement_badge", achievement.day))
                    .font(.system(size: 28, weight: .black, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 2))

                // Phrase
                achievement.displayText
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 3)
                    .frame(width: width * 0.82)
                    .padding(.top, 48)

                Spacer()

                // Pet (static frame — no animation needed for image render)
                PetSpriteView(grid: petGrid, dna: dna, pixelSize: 14)
                    .padding(.bottom, 24)

                // KM display (same style as HomeView)
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(String(format: "%.1f", todayKm))
                        .font(.system(size: 112, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#F9703E"))
                    Text("km")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#F9703E").opacity(0.65))
                        .padding(.bottom, 12)
                }
                .shadow(color: Color.black.opacity(0.55), radius: 8, x: 0, y: 3)
                .padding(.bottom, height * 0.08)
            }
        }
        .frame(width: width, height: height)
        .clipped()
    }
}

// MARK: – UIKit Share Sheet wrapper

private struct ShareSheet: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: – Daily Tip Modal

struct DailyTipModal: View {
    let day: Int
    let dna: PetDNA
    let onDismiss: () -> Void

    @State private var appeared = false

    // Parses **bold** markers into orange bold text
    private func richDetail(_ raw: String) -> Text {
        let orange = Color(hex: "#F9703E")
        let parts = raw.components(separatedBy: "**")
        var result = Text("")
        for (i, part) in parts.enumerated() {
            if part.isEmpty { continue }
            if i % 2 == 1 {
                result = result + Text(part).bold().foregroundColor(orange)
            } else {
                result = result + Text(part)
            }
        }
        return result
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Solid yellow + pattern overlay
                Color(hex: "#F9F496")

                Image("pattern")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.3)

                VStack(spacing: 0) {
                    Spacer().frame(height: 80)

                    // Badge
                    Text(L("tip.badge", day))
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color(hex: "#F9703E"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#F9703E").opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color(hex: "#F9703E").opacity(0.3), lineWidth: 1))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.3), value: appeared)

                    Spacer().frame(height: 20)

                    // Content box (like energy card: dark bg, white border)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 14) {
                            // Title (short tip)
                            Text(L("tip.\(day)"))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(hex: "#F9703E"))
                                .multilineTextAlignment(.center)

                            // Detail text with auto-highlighted keywords
                            richDetail(L("tip.\(day).detail"))
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 20)
                    }
                    .frame(maxHeight: geo.size.height * 0.40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "#2B2420"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.white.opacity(0.78), lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 12, y: 4)
                    )
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)

                    Spacer()

                    // Pet with teaching pose (fixed)
                    PetAnimationView(dna: dna, pose: .teaching, pixelSize: 7, fps: 3)
                        .scaleEffect(appeared ? 1.0 : 0.8)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
                        .padding(.bottom, 32)

                    // Dismiss
                    Button(action: onDismiss) {
                        Text(L("tip.dismiss"))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .foregroundStyle(.white)
                    .background(Color(hex: "#F9703E"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(hex: "#F9703E").opacity(0.4), radius: 12, y: 5)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 56)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.25), value: appeared)
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

// MARK: – Medal tutorial overlay

private struct MedalTutorialOverlay: View {
    let onDismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Medal icon
                Image(systemName: "medal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 20)
                    .scaleEffect(appeared ? 1.0 : 0.3)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: appeared)

                Text(L("medal.tutorial_title"))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                Text(L("medal.tutorial_body"))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)

                Spacer()

                Button(action: onDismiss) {
                    Text(L("medal.tutorial_dismiss"))
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
                .animation(.easeOut(duration: 0.3).delay(0.35), value: appeared)
            }
        }
        .onAppear { withAnimation { appeared = true } }
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
