import SwiftUI

private let totalDays = 66
private let runThreshold = 0.5  // km required for a completed day

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

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 5), count: 7)
    private let weekLabels = ["D", "L", "M", "M", "J", "V", "S"]

    // ── Derived ──────────────────────────────────────────────────────────────

    private var startDate: Date { appState.challengeStartDate }

    /// 0-based index of today (clamped to 0...totalDays-1)
    private var todayIndex: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: Calendar.current.startOfDay(for: Date())).day ?? 0
        return min(max(days, 0), totalDays - 1)
    }

    private var completedCount: Int { (0...todayIndex).filter { state(for: $0) == .completed }.count }
    private var missedCount: Int    { (0..<todayIndex).filter { state(for: $0) == .missed   }.count }
    private var streakCount: Int {
        var streak = 0
        var i = todayIndex
        while i >= 0 && state(for: i) == .completed { streak += 1; i -= 1 }
        return streak
    }

    private var projectedFinish: String {
        let remaining = totalDays - completedCount
        guard remaining > 0 else { return "¡Reto completado!" }
        let today = Calendar.current.startOfDay(for: Date())
        if let finish = Calendar.current.date(byAdding: .day, value: remaining, to: today) {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: "es_MX")
            fmt.dateFormat = "d 'de' MMMM"
            return fmt.string(from: finish)
        }
        return "—"
    }

    // Weekday offset so day 0 aligns to its actual weekday (0=Sun)
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
                dayIndex: sel.index,
                date: date(for: sel.index),
                state: state(for: sel.index),
                km: sel.index == todayIndex ? health.todayKm : (dailyKm[sel.index] ?? 0)
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
                    Text("Reto 66 Días")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Text("Día \(min(todayIndex + 1, totalDays))/\(totalDays)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .padding(10)
                        .background(Color(hex: "#F0E8E0"))
                        .clipShape(Circle())
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "#F0E8E0"))
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

                ForEach(0..<totalDays, id: \.self) { i in
                    DayCell(
                        dayIndex: i,
                        state: state(for: i),
                        km: dailyKm[i] ?? 0,
                        todayKm: i == todayIndex ? health.todayKm : nil
                    )
                    .aspectRatio(1, contentMode: .fit)
                    .id(i == todayIndex ? "today" : "day-\(i)")
                    .onTapGesture { selectedDayIndex = SelectedDay(index: i) }
                }
            }
        }
    }

    // MARK: – Stats

    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                statCell(value: "\(completedCount)", label: "Completados", color: "#F9703E")
                Divider().frame(height: 32)
                statCell(value: "\(missedCount)", label: "Faltas", color: missedCount > 0 ? "#E12D39" : "#9AA5B4")
                Divider().frame(height: 32)
                statCell(value: "\(streakCount)", label: "Racha", color: streakCount >= 7 ? "#F9703E" : "#1F2933")
            }
            .padding(.vertical, 16)
            .background(Color(hex: "#FFF0E8"))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                Text("Fin estimado: \(projectedFinish)")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                Spacer()
            }
        }
    }

    private func statCell(value: String, label: String, color: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(Color(hex: color))
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
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

    private var effectiveKm: Double { todayKm ?? km }

    var body: some View {
        GeometryReader { geo in
            let size = geo.size.width
            ZStack {
                switch state {
                case .completed:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#F9703E"))
                    checkmark(size: size)

                case .missed:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#F2C4BA"))
                    xmark(size: size)

                case .today:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#FFF8F2"))
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.22)
                                .strokeBorder(Color(hex: "#F9703E"), lineWidth: 1.5)
                        )
                    if effectiveKm > 0 {
                        // Partial fill
                        ZStack(alignment: .bottom) {
                            Color.clear
                            Rectangle()
                                .fill(Color(hex: "#F9703E").opacity(0.25))
                                .frame(height: size * min(effectiveKm / runThreshold, 1.0))
                        }
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
                    }

                case .future:
                    RoundedRectangle(cornerRadius: size * 0.22)
                        .fill(Color(hex: "#F0E8E0"))
                }
            }
        }
    }

    private func checkmark(size: CGFloat) -> some View {
        Image(systemName: "checkmark")
            .font(.system(size: size * 0.38, weight: .bold))
            .foregroundStyle(.white)
    }

    private func xmark(size: CGFloat) -> some View {
        Image(systemName: "xmark")
            .font(.system(size: size * 0.34, weight: .semibold))
            .foregroundStyle(Color(hex: "#E07060"))
    }
}

// MARK: – SelectedDay (Identifiable wrapper for sheet)

private struct SelectedDay: Identifiable {
    let index: Int
    var id: Int { index }
}

// MARK: – DayDetailView

private struct DayDetailView: View {
    let dayIndex: Int
    let date: Date
    let state: DayState
    let km: Double

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "es_MX")
        fmt.dateFormat = "EEEE d 'de' MMMM"
        return fmt.string(from: date).capitalized
    }

    private var dayLabel: String { "Día \(dayIndex + 1)" }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 20) {
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

                // KM stat
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(String(format: "%.2f", km))
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(stateColor)
                            Text("km")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(stateColor.opacity(0.65))
                                .padding(.bottom, 4)
                        }
                        Text(stateLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(stateColor)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 20)
                .background(stateColor.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 32)

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
        case .completed: return "Completado ✓"
        case .missed:    return "Sin actividad"
        case .today:     return km >= runThreshold ? "Completado ✓" : "En progreso"
        case .future:    return "Próximamente"
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
