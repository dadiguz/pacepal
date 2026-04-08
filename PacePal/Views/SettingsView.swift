import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(PurchaseManager.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var showBackgroundPicker = false
    @State private var showPaywall = false

    #if DEBUG
    @State private var debugNow: Date = Date()
    @State private var drainTimer: Timer? = nil
    #endif

    var onShowTutorial: (() -> Void)? = nil

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(L("settings.title"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#9AA5B4"))
                            .padding(10)
                            .background(Color(hex: "#F5ECE4"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

                // Options list
                VStack(spacing: 10) {
                    settingsRow(
                        icon: "questionmark.circle",
                        iconColor: "#F9703E",
                        title: L("settings.tutorial_title"),
                        subtitle: L("settings.tutorial_subtitle")
                    ) {
                        onShowTutorial?()
                    }

                    settingsRow(
                        icon: "photo.on.rectangle",
                        iconColor: "#3B82F6",
                        title: L("settings.background_title"),
                        subtitle: L("settings.background_subtitle")
                    ) {
                        showBackgroundPicker = true
                    }

                    // ── Sounds toggle ────────────────────────────────────
                    let bindableState = Bindable(appState)
                    HStack(spacing: 14) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(Color(hex: "#F9703E"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L("settings.sounds_title"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color(hex: "#1F2933"))
                            Text(L("settings.sounds_subtitle"))
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundStyle(Color(hex: "#9AA5B4"))
                        }

                        Spacer()

                        Toggle("", isOn: bindableState.soundsEnabled)
                            .labelsHidden()
                            .tint(Color(hex: "#F9703E"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))

                    // ── Subscription row ─────────────────────────────────
                    if store.isPremium {
                        settingsRow(
                            icon: "checkmark.seal.fill",
                            iconColor: "#27AE60",
                            title: L("settings.premium_active"),
                            subtitle: L("settings.premium_manage")
                        ) {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                    } else {
                        settingsRow(
                            icon: "crown.fill",
                            iconColor: "#F9703E",
                            title: L("settings.premium_activate"),
                            subtitle: L("settings.premium_price", store.displayPrice)
                        ) {
                            showPaywall = true
                        }
                    }

                    settingsRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: "#E12D39",
                        title: L("settings.reset_title"),
                        subtitle: L("settings.reset_subtitle")
                    ) {
                        showResetConfirm = true
                    }
                }
                .padding(.horizontal, 24)

                #if DEBUG
                testingSection
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                #endif

                Spacer()
            }
        }
        .sheet(isPresented: $showBackgroundPicker) {
            BackgroundPickerSheet()
                .environment(appState)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environment(appState)
                .environment(store)
        }
        .confirmationDialog(L("settings.reset_title"), isPresented: $showResetConfirm) {
            Button(L("settings.reset_confirm"), role: .destructive) {
                appState.onCharacterSelected()
                saved.forEach { modelContext.delete($0) }
                health.resetKm()
                dismiss()
                withAnimation(.spring(duration: 0.4)) {
                    appState.selectedCharacter = nil
                }
            }
            Button(L("settings.cancel"), role: .cancel) {}
        } message: {
            Text(L("settings.reset_message"))
        }
    }

    #if DEBUG
    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TESTING")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Color(hex: "#9AA5B4"))

            Button {
                appState.syncToWidget(km: health.todayKm)
            } label: {
                Text("📲 Sync widget ahora")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#EFF8FF"))
                    .foregroundStyle(Color(hex: "#1C5FA8"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#BFDBFE"), lineWidth: 1))
            }

            Button {
                SoundManager.shared.playRandomHappy(enabled: true)
            } label: {
                Text("🔊 Test sonido (happy)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundStyle(Color(hex: "#4A3F35"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
            }

            Button {
                SoundManager.shared.playMusic(name: "pacepal", enabled: true)
            } label: {
                Text("🎵 Test música (pacepal)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .foregroundStyle(Color(hex: "#4A3F35"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
            }

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
                        debugNow = Date()
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundStyle(Color(hex: "#4A3F35"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                    }
                }
            }

            // Drain: decreases energy 1% every second for testing notifications
            Button {
                if drainTimer != nil {
                    drainTimer?.invalidate()
                    drainTimer = nil
                } else {
                    drainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        let current = appState.energy(at: Date())
                        appState.setEnergy(max(0, current - 0.01))
                        debugNow = Date()
                    }
                }
            } label: {
                Text(drainTimer != nil ? "⏹ Detener drain" : "📉 -1% / seg (drain)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(drainTimer != nil ? Color(hex: "#FFF0EE") : Color.white)
                    .foregroundStyle(drainTimer != nil ? Color(hex: "#E53E3E") : Color(hex: "#4A3F35"))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(
                        drainTimer != nil ? Color(hex: "#E53E3E").opacity(0.4) : Color(hex: "#E2E8F0"),
                        lineWidth: 1))
            }

            HStack(spacing: 6) {
                Button {
                    health.addTestKm()
                } label: {
                    Text("➕ 1 km")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Button {
                    appState.addEnergy(km: 1.0)
                    debugNow = Date()
                } label: {
                    Text("⚡ +10% energía")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }
            }

            // Day controls
            let dayNum = (Calendar.current.dateComponents([.day], from: appState.challengeStartDate, to: Date()).day ?? 0) + 1
            HStack(spacing: 6) {
                Button {
                    appState.resetChallengeToToday()
                    debugNow = Date()
                } label: {
                    Text("0 días")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#E12D39"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Button {
                    appState.shiftChallengeDay(by: 1)
                    debugNow = Date()
                } label: {
                    Text("+1 día")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Button {
                    appState.shiftChallengeDay(by: 3)
                    debugNow = Date()
                } label: {
                    Text("+3 días")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Button {
                    appState.shiftChallengeDay(by: 10)
                    debugNow = Date()
                } label: {
                    Text("+10 días")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Text("DÍA \(dayNum)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }

            // Medal controls
            HStack(spacing: 6) {
                Button {
                    appState.grantMedal()
                } label: {
                    Text("🏅 Dar medalla")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(appState.medalEarned ? Color(hex: "#FFF9E6") : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(
                            appState.medalEarned ? Color(hex: "#FFD700") : Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Button {
                    appState.revokeMedal()
                } label: {
                    Text("❌ Quitar medalla")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#E12D39"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }
            }

            if appState.medalEarned {
                Text("MEDALLA ACTIVA")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#FFD700"))
            }
        }
    }
    #endif

    private func settingsRow(
        icon: String,
        iconColor: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: iconColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#CBD2D9"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
        }
    }
}

// MARK: - Background Picker Sheet

struct BackgroundPickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    private var currentDay: Int {
        (Calendar.current.dateComponents([.day], from: appState.challengeStartDate, to: Date()).day ?? 0) + 1
    }

    private func isUnlocked(_ index: Int) -> Bool {
        guard index >= 1 && index <= Achievement.all.count else { return true } // 0 = default always unlocked
        guard appState.challengeStarted else { return false }
        return currentDay >= Achievement.all[index - 1].day
    }

    private func imageName(for index: Int) -> String? {
        guard index >= 1 else { return nil }
        return String(format: "background_%02d", index)
    }

    private var selectedIndex: Int? {
        guard let bg = appState.selectedBackground else { return 0 }
        return Achievement.all.first { String(format: "background_%02d", $0.index) == bg }?.index
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L("settings.backgrounds_title"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .padding(9)
                        .background(Color(hex: "#F5ECE4"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Text(L("settings.backgrounds_subtitle"))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    // Index 0 = default background
                    ForEach(0...23, id: \.self) { index in
                        let unlocked = isUnlocked(index)
                        let isSelected = selectedIndex == index
                        let name = imageName(for: index)

                        Button {
                            guard unlocked else { return }
                            withAnimation(.spring(duration: 0.25)) {
                                appState.selectBackground(name)
                            }
                        } label: {
                            ZStack {
                                // Thumbnail
                                if let name {
                                    Image(name)
                                        .resizable()
                                        .scaledToFill()
                                        .clipped()
                                } else {
                                    // Default gradient preview
                                    ZStack {
                                        Color(hex: "#F5F8FC")
                                        RadialGradient(
                                            colors: [Color(hex: "#F9703E").opacity(0.18), .clear],
                                            center: .init(x: 0.5, y: 0.1),
                                            startRadius: 0, endRadius: 80
                                        )
                                    }
                                }

                                // Lock overlay
                                if !unlocked {
                                    Color.black.opacity(0.52)
                                    VStack(spacing: 4) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                        if index >= 1 && index <= Achievement.all.count {
                                            Text(L("common.day_n", Achievement.all[index - 1].day))
                                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white.opacity(0.85))
                                        }
                                    }
                                }

                                // Selection checkmark
                                if isSelected {
                                    Color.black.opacity(0.15)
                                    VStack {
                                        HStack {
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.4), radius: 4)
                                                .padding(6)
                                        }
                                        Spacer()
                                    }
                                }

                                // Day label for unlocked (non-default)
                                if unlocked && index >= 1 {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Text(L("common.day_n", Achievement.all[index - 1].day))
                                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                                .foregroundStyle(.white)
                                                .shadow(color: .black.opacity(0.6), radius: 2)
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 3)
                                                .background(.black.opacity(0.30))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                            Spacer()
                                        }
                                        .padding(5)
                                    }
                                }

                                // "Original" label for default tile
                                if index == 0 {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Text(L("settings.original"))
                                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                                .foregroundStyle(Color(hex: "#4A3F35"))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 3)
                                                .background(Color.white.opacity(0.70))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                            Spacer()
                                        }
                                        .padding(5)
                                    }
                                }
                            }
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(
                                        isSelected ? Color(hex: "#F9703E") : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color(hex: "#F5F8FC").ignoresSafeArea())
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(HealthManager())
}
