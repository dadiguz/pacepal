import WidgetKit
import SwiftUI

// MARK: - Color hex extension (local copy for widget module)
private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Pet rendering (subset of PetCanvasView for widget)

private func rgb(_ hex: String) -> (Double, Double, Double) {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var n: UInt64 = 0
    Scanner(string: h).scanHexInt64(&n)
    return (Double((n >> 16) & 0xFF), Double((n >> 8) & 0xFF), Double(n & 0xFF))
}

private func tone(_ r: Double, _ g: Double, _ b: Double, _ amt: Double) -> Color {
    Color(.sRGB,
          red:   max(0, min(1, (r + amt) / 255)),
          green: max(0, min(1, (g + amt) / 255)),
          blue:  max(0, min(1, (b + amt) / 255)))
}

private func colorForCell(_ cell: PetCell, gx: Int, gy: Int, dna: PetDNA) -> Color? {
    let palette = dna.palette
    switch cell {
    case .empty, .eyeWhite: return nil
    case .outline:
        let (r, g, b) = rgb(palette.body); return tone(r, g, b, -70)
    case .body, .accent1, .accent2:
        let hexColor = cell == .accent1 ? palette.accent1 : cell == .accent2 ? palette.accent2 : palette.body
        let (r, g, b) = rgb(hexColor)
        let dx = (Double(gx) - dna.bodyCx) / max(1, dna.bodyRx)
        let dy = (Double(gy) - dna.bodyCy) / max(1, dna.bodyRy)
        let light = dx - dy; let ck = (gx + gy) % 2
        if      light >  0.65 { return tone(r, g, b,  90) }
        else if light >  0.50 { return ck == 0 ? tone(r,g,b,90) : tone(r,g,b,42) }
        else if light >  0.25 { return tone(r, g, b,  42) }
        else if light >  0.10 { return ck == 0 ? tone(r,g,b,42) : tone(r,g,b,0) }
        else if light > -0.15 { return tone(r, g, b,   0) }
        else if light > -0.30 { return ck == 0 ? tone(r,g,b,0) : tone(r,g,b,-55) }
        else                  { return tone(r, g, b, -55) }
    case .face:
        let (r, g, b) = rgb(palette.face)
        let dx = (Double(gx) - dna.bodyCx) / max(1, dna.bodyRx)
        let dy = (Double(gy) - dna.bodyCy) / max(1, dna.bodyRy)
        let light = dx - dy; let ck = (gx + gy) % 2
        if      light >  0.25 { return ck == 0 ? tone(r,g,b,-15) : tone(r,g,b,-40) }
        else if light > -0.10 { return tone(r, g, b, -40) }
        else                  { return ck == 0 ? tone(r,g,b,-40) : tone(r,g,b,-60) }
    case .eyePupil: return Color(hex: palette.eyeP)
    case .eyeShine: return Color(.sRGB, red: 0.88, green: 0.93, blue: 1.0)
    case .mouth:    return Color(hex: palette.eyeP)
    case .cheek:    return Color(hex: palette.cheek)
    case .shade:    return Color(hex: palette.shade)
    case .nose:     return Color(hex: palette.eyeP)
    case .tear:     return Color(hex: "#5599ff")
    case .gold:     return Color(hex: "#ffcc00")
    case .speedLine: return Color(hex: "#ff7700")
    case .gray:     return Color(hex: "#888888")
    case .lightning: return Color(hex: "#00cfff")
    }
}

private struct WidgetPetSpriteView: View {
    let grid: PetGrid
    let dna: PetDNA
    let pixelSize: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            for y in 0..<GRID_SIZE {
                for x in 0..<GRID_SIZE {
                    guard let color = colorForCell(grid[y][x], gx: x, gy: y, dna: dna) else { continue }
                    let rect = CGRect(x: CGFloat(x) * pixelSize, y: CGFloat(y) * pixelSize,
                                     width: pixelSize, height: pixelSize)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(GRID_SIZE) * pixelSize, height: CGFloat(GRID_SIZE) * pixelSize)
    }
}

// MARK: - Shared defaults keys (must match AppState)
private let kAppGroup     = "group.io.dallio.PacePal"
private let kEnergyReset  = "w_energyResetDate"
private let kDecaySeconds = "w_decaySeconds"
private let kPetDNA       = "w_petDNAData"
private let kTodayKm      = "w_todayKm"
private let kChallengeDay = "w_challengeDay"

// MARK: - Timeline entry

struct PacepalEntry: TimelineEntry {
    let date: Date
    let dna: PetDNA?
    let energy: Double      // 0–1
    let todayKm: Double
    let challengeDay: Int
}

extension PacepalEntry {
    var pose: PetPose {
        if energy <= 0   { return .dead }
        if energy < 0.25 { return .sad }
        if energy < 0.60 { return .idle }
        return .happy
    }

    var energyColor: Color {
        if energy > 0.60 { return Color(hex: "#F9703E") }
        if energy > 0.25 { return Color(hex: "#F6AD55") }
        return Color(hex: "#E12D39")
    }

    var moodLabel: String {
        if energy <= 0   { return "💀" }
        if energy < 0.25 { return "😢" }
        if energy < 0.60 { return "😐" }
        return "✨"
    }
}

// MARK: - Provider

struct PacepalProvider: TimelineProvider {
    func placeholder(in context: Context) -> PacepalEntry {
        PacepalEntry(date: Date(), dna: PetDNA.presets()[1], energy: 0.72, todayKm: 3.2, challengeDay: 14)
    }

    func getSnapshot(in context: Context, completion: @escaping (PacepalEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PacepalEntry>) -> Void) {
        let now = Date()
        // One entry every 15 min for 12 hours — energy pre-calculated
        let entries = (0..<48).map { i in
            entry(at: now.addingTimeInterval(Double(i) * 15 * 60))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(12 * 3600))))
    }

    private func entry(at date: Date) -> PacepalEntry {
        let def          = UserDefaults(suiteName: kAppGroup)
        let resetDate    = def?.object(forKey: kEnergyReset) as? Date ?? Date()
        let decaySeconds = def?.double(forKey: kDecaySeconds) ?? (36 * 3600)
        let todayKm      = def?.double(forKey: kTodayKm) ?? 0
        let challengeDay = def?.integer(forKey: kChallengeDay).nonZero ?? 1

        let elapsed = date.timeIntervalSince(resetDate)
        let energy  = max(0, min(1, 1.0 - elapsed / decaySeconds))

        let dna = def?.data(forKey: kPetDNA).flatMap {
            try? JSONDecoder().decode(PetDNA.self, from: $0)
        }

        return PacepalEntry(date: date, dna: dna, energy: energy, todayKm: todayKm, challengeDay: challengeDay)
    }
}

private extension Int {
    var nonZero: Int? { self == 0 ? nil : self }
}

// MARK: - Small widget view

struct SmallWidgetView: View {
    let entry: PacepalEntry

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#F5F8FC")
            RadialGradient(
                colors: [Color(hex: "#F9703E").opacity(0.10), .clear],
                center: .init(x: 0.5, y: 0.0),
                startRadius: 0, endRadius: 150
            )

            VStack(spacing: 0) {
                Spacer(minLength: 4)

                petSprite
                    .padding(.bottom, 6)

                Spacer(minLength: 0)

                stats
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
        }
    }

    @ViewBuilder
    private var petSprite: some View {
        if let dna = entry.dna {
            let grid = buildCharacterGrid(dna: dna, pose: entry.pose, frame: 0)
            WidgetPetSpriteView(grid: grid, dna: dna, pixelSize: 4.5)
                .frame(width: 108, height: 108)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F9703E").opacity(0.12))
                .frame(width: 80, height: 80)
        }
    }

    private var stats: some View {
        VStack(spacing: 5) {
            // Energy bar
            HStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: "#E2E8F0")).frame(height: 5)
                        Capsule()
                            .fill(entry.energyColor)
                            .frame(width: geo.size.width * CGFloat(entry.energy), height: 5)
                    }
                }
                .frame(height: 5)

                Text("\(Int(entry.energy * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.energyColor)
                    .frame(width: 26, alignment: .trailing)
            }

            // Km + day
            HStack {
                Label(String(format: "%.1f km", entry.todayKm), systemImage: "figure.run")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#616E7C"))

                Spacer()

                Text("Día \(entry.challengeDay)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
        }
    }
}

// MARK: - Medium widget view

struct MediumWidgetView: View {
    let entry: PacepalEntry

    var body: some View {
        ZStack {
            Color(hex: "#F5F8FC")
            RadialGradient(
                colors: [Color(hex: "#F9703E").opacity(0.09), .clear],
                center: .init(x: 0.2, y: 0.0),
                startRadius: 0, endRadius: 200
            )

            HStack(spacing: 0) {
                petSprite
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color(hex: "#E2E8F0"))
                    .frame(width: 1)
                    .padding(.vertical, 16)

                rightStats
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private var petSprite: some View {
        if let dna = entry.dna {
            VStack(spacing: 4) {
                let grid = buildCharacterGrid(dna: dna, pose: entry.pose, frame: 0)
                WidgetPetSpriteView(grid: grid, dna: dna, pixelSize: 5)
                    .frame(width: 120, height: 120)
                if !dna.name.isEmpty {
                    Text(dna.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#616E7C"))
                }
            }
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F9703E").opacity(0.12))
                .frame(width: 80, height: 80)
        }
    }

    private var rightStats: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text(entry.moodLabel).font(.system(size: 18))
                Text("PacePal")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Energía")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                    Spacer()
                    Text("\(Int(entry.energy * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(entry.energyColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: "#E2E8F0")).frame(height: 5)
                        Capsule()
                            .fill(entry.energyColor)
                            .frame(width: geo.size.width * CGFloat(entry.energy), height: 5)
                    }
                }
                .frame(height: 5)
            }

            statRow(icon: "figure.run", label: String(format: "%.1f km hoy", entry.todayKm))
            statRow(icon: "calendar", label: "Día \(entry.challengeDay) de 66")
        }
    }

    private func statRow(icon: String, label: String) -> some View {
        Label(label, systemImage: icon)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(Color(hex: "#616E7C"))
    }
}

// MARK: - Entry view

struct PacepalWidgetEntryView: View {
    let entry: PacepalEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: MediumWidgetView(entry: entry)
        default:            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct PacepalWidget: Widget {
    let kind = "PacepalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PacepalProvider()) { entry in
            PacepalWidgetEntryView(entry: entry)
                .containerBackground(Color(hex: "#F5F8FC"), for: .widget)
        }
        .configurationDisplayName("PacePal")
        .description("Tu compañero de carrera, siempre contigo.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
