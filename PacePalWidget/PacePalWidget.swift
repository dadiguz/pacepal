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



// MARK: - Shared defaults keys (must match AppState)
private let kAppGroup     = "group.io.dallio.PacePal"
private let kEnergyReset  = "w_energyResetDate"
private let kDecaySeconds = "w_decaySeconds"
private let kPetDNA       = "w_petDNAData"
private let kTodayKm      = "w_todayKm"
private let kChallengeDay = "w_challengeDay"
private let kPetImage     = "w_petImageData"

// MARK: - Timeline entry

struct PacepalEntry: TimelineEntry {
    let date: Date
    let dna: PetDNA?
    let petImage: UIImage?
    let energy: Double      // 0–1
    let todayKm: Double
    let challengeDay: Int
}

extension PacepalEntry {
    var pose: PetPose {
        if energy <= 0    { return .dead  }
        if energy <= 0.14 { return .dizzy }
        if energy <= 0.25 { return .sad   }
        if energy <= 0.50 { return .angry }
        if energy <= 0.90 { return .idle  }
        if energy <= 0.95 { return .happy }
        if energy <  0.99 { return .jump  }
        return .hype
    }

    var energyColor: Color {
        if energy <= 0    { return Color(hex: "#E12D39") }
        if energy >= 0.60 { return Color(hex: "#4ADE80") }
        if energy >= 0.30 { return Color(hex: "#A3E635") }
        if energy >= 0.15 { return Color(hex: "#FCD34D") }
        return Color(hex: "#E12D39")
    }

    var moodText: String {
        if energy <= 0    { return "💀 Exhausto"   }
        if energy <= 0.14 { return "😵 Colapsando" }
        if energy <= 0.25 { return "😢 Agotado"    }
        if energy <= 0.50 { return "😠 Exigiendo"  }
        if energy <= 0.90 { return "😐 Listo"       }
        if energy <= 0.95 { return "😊 Contento"   }
        if energy <  0.99 { return "⚡ Con energía" }
        return "🔥 En racha"
    }

}

// MARK: - Provider

struct PacepalProvider: TimelineProvider {
    func placeholder(in context: Context) -> PacepalEntry {
        PacepalEntry(date: Date(), dna: PetDNA.presets()[1], petImage: nil, energy: 0.72, todayKm: 3.2, challengeDay: 14)
    }

    func getSnapshot(in context: Context, completion: @escaping (PacepalEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PacepalEntry>) -> Void) {
        let now = Date()
        let entries = (0..<4).map { i in
            entry(at: now.addingTimeInterval(Double(i) * 3600))
        }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(4 * 3600))))
    }

    private func entry(at date: Date) -> PacepalEntry {
        let def          = UserDefaults(suiteName: kAppGroup)
        let resetDate    = def?.object(forKey: kEnergyReset) as? Date ?? Date()
        let decaySeconds = def?.double(forKey: kDecaySeconds) ?? (36 * 3600)
        let todayKm      = def?.double(forKey: kTodayKm) ?? 0
        let challengeDay = def?.integer(forKey: kChallengeDay).nonZero ?? 1

        let elapsed = date.timeIntervalSince(resetDate)
        let energy  = max(0, min(1, 1.0 - elapsed / decaySeconds))

        let dnaData = def?.data(forKey: kPetDNA)
        let dna = dnaData.flatMap { try? JSONDecoder().decode(PetDNA.self, from: $0) }

        let petImage = def?.data(forKey: kPetImage).flatMap { UIImage(data: $0) }

        print("🔍 Widget entry: def=\(def != nil), dnaData=\(dnaData?.count ?? 0)b, dna=\(dna?.name ?? "nil"), energy=\(Int(energy*100))%, img=\(petImage != nil ? "✅" : "❌")")

        return PacepalEntry(date: date, dna: dna, petImage: petImage, energy: energy, todayKm: todayKm, challengeDay: challengeDay)
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
            Color.white

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
        if let img = entry.petImage {
            Image(uiImage: img)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
        } else {
            Color(hex: "#F9703E").opacity(0.12)
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
            Color.white

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
        VStack(spacing: 6) {
            if let img = entry.petImage {
                Image(uiImage: img)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
            } else {
                Color(hex: "#F9703E").opacity(0.12)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if let name = entry.dna?.name, !name.isEmpty {
                HStack(spacing: 4) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 12)
                    Text(name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#616E7C"))
                }
            }
        }
    }

    private var rightStats: some View {
        VStack(alignment: .leading, spacing: 10) {

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

            Text(entry.moodText)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#4A3F35"))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(entry.energyColor.opacity(0.13))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(entry.energyColor, lineWidth: 1))
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
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("PacePal")
        .description("Tu compañero de carrera, siempre contigo.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
