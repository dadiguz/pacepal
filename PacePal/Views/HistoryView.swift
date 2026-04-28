import SwiftUI

private let totalDays = 66
// runThreshold is now dynamic — read from appState.challengeLevel.runThreshold

// MARK: – Day state

private enum DayState {
    case completed, missed, today, future
}

// MARK: – HistoryView

struct HistoryView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.dismiss) private var dismiss

    @State private var dailyKm: [Int: Double] = [:]   // dayIndex → km
    @State private var isLoading = false
    @State private var selectedDayIndex: SelectedDay? = nil

    private var runThreshold: Double { appState.challengeLevel.runThreshold }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private var weekLabels: [String] { [L("history.weekday_sun"), L("history.weekday_mon"), L("history.weekday_tue"), L("history.weekday_wed"), L("history.weekday_thu"), L("history.weekday_fri"), L("history.weekday_sat")] }

    // ── Derived ──────────────────────────────────────────────────────────────

    private var startDate: Date { appState.challengeStartDate }

    /// 0-based index of today in calendar days since challenge start.
    private var todayIndex: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return max(days, 0)
    }

    private var completedCount: Int { (0...todayIndex).filter { state(for: $0) == .completed }.count }
    private var missedCount: Int    { (0..<todayIndex).filter { state(for: $0) == .missed   }.count }

    /// Total cells in the grid: 66 runs + one placeholder per missed day.
    private var totalCells: Int { totalDays + missedCount }
    private var streakCount: Int {
        var streak = 0
        var i = todayIndex
        while i >= 0 && state(for: i) == .completed { streak += 1; i -= 1 }
        return streak
    }

    private var projectedFinish: String {
        let remaining = totalDays - completedCount
        guard remaining > 0 else { return L("history.challenge_complete") }
        let today = Calendar.current.startOfDay(for: Date())
        if let finish = Calendar.current.date(byAdding: .day, value: remaining, to: today) {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: AppLang.current == .en ? "en_US" : "es_MX")
            fmt.dateFormat = AppLang.current == .en ? "MMMM d" : "d 'de' MMMM"
            return fmt.string(from: finish)
        }
        return "—"
    }

    // Weekday offset so day 0 aligns to its actual weekday (0=Sun)
    /// Sequential run number for each completed dayIndex (1-based).
    private var runNumbers: [Int: Int] {
        var result: [Int: Int] = [:]
        var count = 0
        for i in 0..<totalCells {
            if state(for: i) == .completed {
                count += 1
                result[i] = count
            }
        }
        return result
    }

    private var startWeekday: Int {
        let wd = Calendar.current.component(.weekday, from: startDate)
        return wd - 1   // Calendar.weekday is 1-indexed
    }

    // ── State helper ─────────────────────────────────────────────────────────

    private func state(for dayIndex: Int) -> DayState {
        if dayIndex > todayIndex { return .future }
        if dayIndex == todayIndex {
            return health.todayKm >= runThreshold ? .completed : .today
        }
        let km = dailyKm[dayIndex] ?? 0
        #if DEBUG
        if km < runThreshold && dayIndex < appState.completedDays {
            return .completed
        }
        #endif
        return km >= runThreshold ? .completed : .missed
    }

    private func date(for dayIndex: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: dayIndex, to: startDate) ?? startDate
    }

    // ── Body ─────────────────────────────────────────────────────────────────

    var body: some View {
        ZStack {
            AppBackground()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        gridSection
                        statsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .padding(.bottom, 48)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo("today", anchor: .center) }
                    }
                }
            }
        }
        .task { await loadHistory() }
        .sheet(item: $selectedDayIndex) { sel in
            DayDetailView(
                runNumber: runNumbers[sel.index] ?? (completedCount + 1),
                date: date(for: sel.index),
                state: state(for: sel.index),
                km: sel.index == todayIndex ? health.todayKm : (dailyKm[sel.index] ?? 0),
                runThreshold: runThreshold
            )
            .presentationDetents([.fraction(0.35)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: – Header

    private var header: some View {
        VStack(spacing: 6) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("history.title"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Text(L("history.day_progress", completedCount, totalDays))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                }
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

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#E2E8F0"))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#F9703E"))
                        .frame(width: geo.size.width * min(Double(completedCount) / Double(totalDays), 1.0))
                        .animation(.spring(duration: 0.7), value: completedCount)
                }
            }
            .frame(height: 6)
            .padding(.top, 4)

        }
    }

    // MARK: – Grid

    private var gridSection: some View {
        VStack(spacing: 4) {
            // Weekday labels
            HStack(spacing: 5) {
                ForEach(weekLabels, id: \.self) { label in
                    Text(label)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day cells
            LazyVGrid(columns: columns, spacing: 5) {
                // Offset empty cells so day 0 lands on correct weekday
                ForEach(0..<startWeekday, id: \.self) { _ in
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }

                ForEach(0..<totalCells, id: \.self) { i in
                    let nums = runNumbers
                    DayCell(
                        dayIndex: i,
                        state: state(for: i),
                        km: dailyKm[i] ?? 0,
                        todayKm: i == todayIndex ? health.todayKm : nil,
                        runNumber: nums[i],
                        runThreshold: runThreshold
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .id(i == todayIndex ? "today" : "day-\(i)")
                    .onTapGesture {
                        let s = state(for: i)
                        guard s == .completed || s == .today else { return }
                        selectedDayIndex = SelectedDay(index: i)
                    }
                }
            }
        }
    }

    // MARK: – Stats

    private var statsSection: some View {
        VStack(spacing: 16) {
            // Dark HUD card — matches energy card style
            HStack(spacing: 0) {
                statCell(value: "\(completedCount)", label: L("history.completed"), valueColor: Color(hex: "#F9703E"))
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                statCell(value: "\(missedCount)",   label: L("history.missed"),
                         valueColor: missedCount > 0 ? Color(hex: "#E12D39") : Color.white.opacity(0.35))
                Rectangle().fill(Color.white.opacity(0.12)).frame(width: 1, height: 32)
                statCell(value: "\(streakCount)",   label: L("history.streak"),
                         valueColor: streakCount >= 7 ? Color(hex: "#F9703E") : .white)
            }
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#2B2420"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.78), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 10, y: 4)
            )

            HStack {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                Text(L("history.estimated_finish", projectedFinish))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                Spacer()
            }
        }
    }

    private func statCell(value: String, label: String, valueColor: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 26, weight: .black, design: .monospaced))
                .foregroundStyle(valueColor)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(Color.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Load history

    private func loadHistory() async {
        guard !isLoading else { return }
        isLoading = true
        let pastDays = (0..<todayIndex)
        await withTaskGroup(of: (Int, Double).self) { group in
            for i in pastDays {
                group.addTask {
                    let km = await health.fetchKm(for: date(for: i))
                    return (i, km)
                }
            }
            for await (index, km) in group {
                dailyKm[index] = km
            }
        }
        isLoading = false
    }
}

// MARK: – DayCell

private struct DayCell: View {
    let dayIndex: Int
    let state: DayState
    let km: Double
    let todayKm: Double?   // non-nil only for today
    let runNumber: Int?    // sequential run count, nil if not a completed run
    let runThreshold: Double

    private var effectiveKm: Double { todayKm ?? km }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width
            ZStack {
                switch state {
                case .completed:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#F9703E"))
                    if let n = runNumber {
                        runLabel(n, size: size, color: .white.opacity(0.45))
                    }
                    checkmark(size: size)

                case .missed:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#F2C4BA"))
                    xmark(size: size)

                case .today:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#F5F8FC"))
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.22)
                                .strokeBorder(Color(hex: "#F9703E"), lineWidth: 1.5)
                        )
                    if effectiveKm > 0 {
                        ZStack(alignment: .bottom) {
                            Color.clear
                            Rectangle()
                                .fill(Color(hex: "#F9703E").opacity(0.22))
                                .frame(height: size * min(effectiveKm / runThreshold, 1.0))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                    }
                    if let n = runNumber {
                        runLabel(n, size: size, color: Color(hex: "#F9703E").opacity(0.6))
                    }

                case .future:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#E8EEF6"))
                }
            }
        }
    }

    private func runLabel(_ n: Int, size: CGFloat, color: Color) -> some View {
        Text(String(format: "%02d", n))
            .font(.system(size: size * 0.24, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(size * 0.1)
    }

    private func checkmark(size: CGFloat) -> some View {
        Image(systemName: "checkmark")
            .font(.system(size: size * 0.34, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(size * 0.1)
    }

    private func xmark(size: CGFloat) -> some View {
        Image(systemName: "xmark")
            .font(.system(size: size * 0.3, weight: .semibold))
            .foregroundStyle(Color(hex: "#E07060"))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(size * 0.1)
    }
}

// MARK: – SelectedDay (Identifiable wrapper for sheet)

private struct SelectedDay: Identifiable {
    let index: Int
    var id: Int { index }
}

// MARK: – DayDetailView

private struct DayDetailView: View {
    let runNumber: Int
    let date: Date
    let state: DayState
    let km: Double
    let runThreshold: Double

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: AppLang.current == .en ? "en_US" : "es_MX")
        fmt.dateFormat = AppLang.current == .en ? "EEEE, MMMM d" : "EEEE d 'de' MMMM"
        return fmt.string(from: date).capitalized
    }

    private var dayLabel: String { L("common.day_n", runNumber) }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer().frame(height: 8)

                // Day + date
                VStack(spacing: 4) {
                    Text(dayLabel)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Text(dateLabel)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                }

                Spacer().frame(height: 24)

                // KM stat — dark HUD card
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(String(format: "%.2f", km))
                        .font(.system(size: 38, weight: .black, design: .monospaced))
                        .foregroundStyle(stateColor)
                    Text("km")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(stateColor.opacity(0.65))
                        .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "#2B2420"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.78), lineWidth: 1.5)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                )
                .padding(.horizontal, 32)

                Spacer().frame(height: 14)

                Text(stateLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(stateColor)

                Spacer()
            }
        }
    }

    private var stateColor: Color {
        switch state {
        case .completed: return Color(hex: "#F9703E")
        case .missed:    return Color(hex: "#E12D39")
        case .today:     return Color(hex: "#F9703E")
        case .future:    return Color(hex: "#9AA5B4")
        }
    }

    private var stateLabel: String {
        switch state {
        case .completed: return L("history.state_completed")
        case .missed:    return L("history.state_missed")
        case .today:     return km >= runThreshold ? L("history.state_completed") : L("history.state_in_progress")
        case .future:    return L("history.state_upcoming")
        }
    }
}

// MARK: – Preview

#Preview {
    let appState: AppState = {
        // Simulate challenge started 12 days ago
        let start = Calendar.current.date(byAdding: .day, value: -12, to: Calendar.current.startOfDay(for: Date()))!
        UserDefaults.standard.set(start, forKey: "challengeStartDate")
        return AppState()
    }()

    return HistoryView()
        .environment(appState)
        .environment(HealthManager())
}
