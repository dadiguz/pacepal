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
    @State private var showTipsSheet = false
    @State private var showPaywall = false
    @State private var showLanguagePicker = false
    @State private var langRefresh = UUID()
    @State private var showLevelPicker = false

    #if DEBUG
    @State private var showDebug = false
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

                    settingsRow(
                        icon: "lightbulb.fill",
                        iconColor: "#F59E0B",
                        title: L("tip.section_title"),
                        subtitle: "\(appState.seenTips.count)/66"
                    ) {
                        showTipsSheet = true
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

                    // ── Challenge level selector ─────────────────────────
                    settingsRow(
                        icon: "flame.fill",
                        iconColor: "#F9703E",
                        title: L("settings.level_title"),
                        subtitle: appState.challengeLevel.label
                    ) {
                        showLevelPicker = true
                    }

                    // ── Language selector ────────────────────────────────
                    settingsRow(
                        icon: "globe",
                        iconColor: "#8B5CF6",
                        title: L("settings.language_title"),
                        subtitle: L("settings.language_subtitle")
                    ) {
                        showLanguagePicker = true
                    }

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


                Spacer()
            }
        }
        .sheet(isPresented: $showBackgroundPicker) {
            BackgroundPickerSheet()
                .environment(appState)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showTipsSheet) {
            TipsSheet()
                .environment(appState)
                .presentationDetents([.fraction(0.85)])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
                .environment(appState)
                .environment(store)
        }
        .sheet(isPresented: $showLevelPicker) {
            LevelPickerSheet()
                .environment(appState)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        #if DEBUG
        .sheet(isPresented: $showDebug) {
            DebugSheet()
                .environment(appState)
                .environment(health)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        #endif
        .sheet(isPresented: $showLanguagePicker, onDismiss: { langRefresh = UUID() }) {
            LanguagePickerSheet()
                .presentationDetents([.fraction(0.45)])
                .presentationDragIndicator(.visible)
        }
        .id(langRefresh)
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

    private var currentDay: Int { appState.completedDays }

    // Tile layout: 0 = default gradient, 1 = solid black, 2 = pattern, 3..25 = achievement backgrounds
    private let solidBlackIndex = 1
    private let patternIndex = 2
    private let achievementOffset = 3 // achievement tiles start at this index

    private func isUnlocked(_ index: Int) -> Bool {
        if index <= patternIndex { return true } // default + black + pattern always unlocked
        let achIdx = index - achievementOffset
        guard achIdx >= 0 && achIdx < Achievement.all.count else { return true }
        guard appState.challengeStarted else { return false }
        return currentDay >= Achievement.all[achIdx].day
    }

    private func backgroundValue(for index: Int) -> String? {
        if index == 0 { return nil } // default gradient
        if index == solidBlackIndex { return "solid_black" }
        if index == patternIndex { return "pattern" }
        return String(format: "background_%02d", index - achievementOffset + 1)
    }

    private var selectedIndex: Int? {
        guard let bg = appState.selectedBackground else { return 0 }
        if bg == "solid_black" { return solidBlackIndex }
        if bg == "pattern" { return patternIndex }
        return Achievement.all.first { String(format: "background_%02d", $0.index) == bg }
            .map { $0.index + achievementOffset - 1 }
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
                    // Index 0 = default, 1 = solid black, 2 = pattern, 3..25 = achievement backgrounds
                    ForEach(0...25, id: \.self) { index in
                        let unlocked = isUnlocked(index)
                        let isSelected = selectedIndex == index
                        let bgValue = backgroundValue(for: index)

                        Button {
                            guard unlocked else { return }
                            withAnimation(.spring(duration: 0.25)) {
                                appState.selectBackground(bgValue)
                            }
                        } label: {
                            ZStack {
                                // Thumbnail
                                if bgValue == "solid_black" {
                                    ZStack {
                                        Color(hex: "#2B2420")
                                        RadialGradient(
                                            colors: [Color(hex: "#F9703E").opacity(0.30), .clear],
                                            center: .init(x: 0.5, y: 0.15),
                                            startRadius: 0, endRadius: 80
                                        )
                                    }
                                } else if bgValue == "pattern" {
                                    ZStack {
                                        Color(hex: "#F9F496")
                                        Image("pattern")
                                            .resizable()
                                            .scaledToFill()
                                            .opacity(0.3)
                                    }
                                } else if let bgValue {
                                    Image(bgValue)
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
                                        let achIdx = index - achievementOffset
                                        if achIdx >= 0 && achIdx < Achievement.all.count {
                                            Text(L("common.day_n", Achievement.all[achIdx].day))
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

                                // Day label for unlocked achievement tiles
                                let achIdx = index - achievementOffset
                                if unlocked && achIdx >= 0 && achIdx < Achievement.all.count {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Text(L("common.day_n", Achievement.all[achIdx].day))
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

                                // Label for default and black tiles
                                if index == 0 || index == solidBlackIndex || index == patternIndex {
                                    VStack {
                                        Spacer()
                                        HStack {
                                            Text(L(index == 0 ? "settings.original" : index == solidBlackIndex ? "settings.black" : "settings.pattern"))
                                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                                .foregroundStyle(index == 0 ? Color(hex: "#4A3F35") : index == patternIndex ? Color(hex: "#4A3F35") : .white.opacity(0.85))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 3)
                                                .background(index == solidBlackIndex ? Color.white.opacity(0.15) : Color.white.opacity(0.70))
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

// MARK: - Tips Sheet

struct TipsSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTipDay: Int? = nil

    private var currentDay: Int { appState.completedDays }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L("tip.section_title"))
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
            .padding(.bottom, 16)

            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(1...66, id: \.self) { day in
                        let unlocked = appState.seenTips.contains(day)
                        HStack(spacing: 14) {
                            // Day badge
                            Text("\(day)")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(unlocked ? Color(hex: "#F9703E") : Color(hex: "#9AA5B4"))
                                .frame(width: 34, height: 34)
                                .background(unlocked ? Color(hex: "#F9703E").opacity(0.12) : Color(hex: "#E5E7EB"))
                                .clipShape(Circle())

                            if unlocked {
                                Text(L("tip.\(day)"))
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color(hex: "#1F2933"))
                            } else {
                                HStack(spacing: 6) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 11))
                                    Text(L("tip.locked", day))
                                        .font(.system(size: 14, weight: .regular, design: .rounded))
                                }
                                .foregroundStyle(Color(hex: "#9AA5B4"))
                            }
                            Spacer()
                            if unlocked {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color(hex: "#9AA5B4"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture {
                            if unlocked { selectedTipDay = day }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(Color(hex: "#F5F8FC").ignoresSafeArea())
        .fullScreenCover(item: Binding(
            get: { selectedTipDay.map { TipDayItem(day: $0) } },
            set: { selectedTipDay = $0?.day }
        )) { item in
            DailyTipModal(day: item.day, dna: appState.selectedCharacter ?? PetDNA.presets()[0]) {
                selectedTipDay = nil
            }
            .presentationBackground(.clear)
        }
    }
}

private struct TipDayItem: Identifiable {
    let day: Int
    var id: Int { day }
}

// MARK: - Language picker sheet

private struct LanguagePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: AppLang? = {
        // nil = automatic (device), otherwise the saved override
        UserDefaults.standard.string(forKey: "appLanguageOverride")
            .flatMap { AppLang(rawValue: $0) }
    }()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L("settings.language_title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .padding(8)
                        .background(Color(hex: "#F5ECE4"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                // Auto option
                languageOption(
                    label: L("settings.language_auto"),
                    isSelected: selected == nil
                ) {
                    selected = nil
                    AppLang.setCurrent(nil)
                    dismiss()
                }

                // Each language
                ForEach(AppLang.allCases, id: \.rawValue) { lang in
                    languageOption(
                        label: lang.displayName,
                        isSelected: selected == lang
                    ) {
                        selected = lang
                        AppLang.setCurrent(lang)
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color(hex: "#F5F8FC").ignoresSafeArea())
    }

    private func languageOption(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(label)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color(hex: "#F9703E"))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color(hex: "#F9703E").opacity(0.5) : Color(hex: "#E2E8F0"), lineWidth: isSelected ? 1.5 : 1)
            )
        }
    }
}

// MARK: - Level Picker Sheet

struct LevelPickerSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L("settings.level_title"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .padding(8)
                        .background(Color(hex: "#F5ECE4"))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            VStack(spacing: 8) {
                ForEach(ChallengeLevel.allCases, id: \.rawValue) { level in
                    let isSelected = appState.challengeLevel == level
                    Button {
                        appState.challengeLevel = level
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: level.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(level.color)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.label)
                                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(Color(hex: "#1F2933"))
                                Text(level.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "#9AA5B4"))
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "#F9703E"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isSelected ? Color(hex: "#F9703E").opacity(0.5) : Color(hex: "#E2E8F0"), lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color(hex: "#F5F8FC").ignoresSafeArea())
    }
}

// MARK: - Debug Sheet

#if DEBUG
private struct DebugSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.dismiss) private var dismiss

    @State private var drainTimer: Timer? = nil

    private func btn(_ label: String, color: String = "#4A3F35", bg: String = "#FFFFFF", action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(Color(hex: color))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(hex: bg))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
        }
    }

    private func section(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(1.2)
            .foregroundStyle(Color(hex: "#9AA5B4"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {

                    // MARK: Energía
                    section("ENERGÍA")
                    HStack(spacing: 6) {
                        ForEach([("100%", 1.00), ("70%", 0.70), ("25%", 0.25), ("9%", 0.09), ("0%", 0.00)], id: \.0) { lbl, val in
                            btn(lbl) { appState.setEnergy(val) }
                        }
                    }
                    btn(drainTimer != nil ? "⏹ Detener drain" : "📉 -1% / seg",
                        color: drainTimer != nil ? "#E53E3E" : "#4A3F35",
                        bg:    drainTimer != nil ? "#FFF0EE" : "#FFFFFF") {
                        if drainTimer != nil {
                            drainTimer?.invalidate(); drainTimer = nil
                        } else {
                            drainTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                appState.setEnergy(max(0, appState.energy(at: Date()) - 0.01))
                            }
                        }
                    }

                    // MARK: Km
                    section("KM")
                    HStack(spacing: 6) {
                        btn("➕ 1 km (health)") { health.addTestKm() }
                        btn("⚡ +1 km (energía)") { appState.addEnergy(km: 1.0) }
                    }

                    // MARK: Días
                    section("DÍAS COMPLETADOS: \(appState.completedDays)")
                    HStack(spacing: 6) {
                        btn("0", color: "#E12D39") { appState.resetChallengeToToday() }
                        btn("+1") { appState.shiftChallengeDay(by: 1) }
                        btn("+3") { appState.shiftChallengeDay(by: 3) }
                        btn("+10") { appState.shiftChallengeDay(by: 10) }
                        btn("+30") { appState.shiftChallengeDay(by: 30) }
                    }
                    // MARK: Medalla
                    section("MEDALLA\(appState.medalEarned ? " — ACTIVA 🏅" : "")")
                    HStack(spacing: 6) {
                        btn("🏅 Dar medalla", bg: appState.medalEarned ? "#FFF9E6" : "#FFFFFF") { appState.grantMedal() }
                        btn("❌ Quitar", color: "#E12D39") { appState.revokeMedal() }
                    }

                    // MARK: Resets
                    section("RESETS")
                    btn("💡 Reset tips (\(appState.seenTips.count) vistos)", color: "#E12D39") { appState.resetTips() }
                    btn("📋 Reset cuestionario", color: "#E12D39") {
                        UserDefaults.standard.set(false, forKey: "questionnaireCompleted")
                        withAnimation(.spring(duration: 0.4)) { appState.selectedCharacter = nil }
                        dismiss()
                    }

                    // MARK: Misc
                    section("MISC")
                    btn("📲 Sync widget") { appState.syncToWidget(km: health.todayKm) }
                    btn("🔊 Test sonido (happy)") { SoundManager.shared.playRandomHappy(enabled: true) }
                    btn("🎵 Test música") { SoundManager.shared.playMusic(name: "pacepal", enabled: true) }
                }
                .padding(20)
            }
            .background(Color(hex: "#F5F8FC").ignoresSafeArea())
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }
}
#endif

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(HealthManager())
}
