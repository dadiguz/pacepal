import WidgetKit
import SwiftUI
import UIKit

// MARK: - Color hex (local copy for widget module)
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

// MARK: - App Group keys
private let kAppGroup     = "group.io.dallio.PacePal"
private let kEnergyReset  = "w_energyResetDate"
private let kDecaySeconds = "w_decaySeconds"
private let kPetDNA       = "w_petDNAData"
private let kTodayKm      = "w_todayKm"
private let kChallengeDay = "w_challengeDay"

// MARK: - Entry
// petImageData is raw PNG bytes — decoded to UIImage inside views to avoid import issues
struct PacepalEntry: TimelineEntry {
    let date: Date
    let dna: PetDNA?
    let petImageData: Data?
    let energy: Double
    let todayKm: Double
    let challengeDay: Int
}

extension PacepalEntry {
    var energyColor: Color {
        if energy <= 0    { return Color(hex: "#E12D39") }
        if energy >= 0.60 { return Color(hex: "#4ADE80") }
        if energy >= 0.30 { return Color(hex: "#A3E635") }
        if energy >= 0.15 { return Color(hex: "#FCD34D") }
        return Color(hex: "#E12D39")
    }

    var moodText: String {
        if energy <= 0    { return "Exhausto"   }
        if energy <= 0.14 { return "Colapsando" }
        if energy <= 0.25 { return "Agotado"    }
        if energy <= 0.50 { return "Exigiendo"  }
        if energy <= 0.90 { return "Listo"      }
        if energy <= 0.95 { return "Contento"   }
        if energy <  0.99 { return "Con energia" }
        return "En racha"
    }
}

// MARK: - Provider
struct PacepalProvider: TimelineProvider {
    func placeholder(in context: Context) -> PacepalEntry {
        PacepalEntry(date: Date(), dna: nil, petImageData: nil,
                     energy: 0.72, todayKm: 3.2, challengeDay: 14)
    }

    func getSnapshot(in context: Context, completion: @escaping (PacepalEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PacepalEntry>) -> Void) {
        let now = Date()
        let entries = (0..<4).map { makeEntry(at: now.addingTimeInterval(Double($0) * 3600)) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(4 * 3600))))
    }

    private func makeEntry(at date: Date) -> PacepalEntry {
        let def          = UserDefaults(suiteName: kAppGroup)
        let resetDate    = (def?.object(forKey: kEnergyReset) as? Date) ?? date
        let decaySeconds = def?.double(forKey: kDecaySeconds) ?? (36 * 3600)
        let todayKm      = def?.double(forKey: kTodayKm) ?? 0
        let rawDay       = def?.integer(forKey: kChallengeDay) ?? 0
        let challengeDay = rawDay > 0 ? rawDay : 1

        let elapsed = date.timeIntervalSince(resetDate)
        let energy  = max(0, min(1, 1.0 - elapsed / decaySeconds))

        let dna: PetDNA? = (def?.data(forKey: kPetDNA))
            .flatMap { try? JSONDecoder().decode(PetDNA.self, from: $0) }

        let spriteURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: kAppGroup)?
            .appendingPathComponent("petSprite.png")
        let petImageData = spriteURL.flatMap { try? Data(contentsOf: $0) }

        return PacepalEntry(date: date, dna: dna, petImageData: petImageData,
                            energy: energy, todayKm: todayKm, challengeDay: challengeDay)
    }
}

// MARK: - Energy bar (shared)
private struct EnergyBar: View {
    let energy: Double
    let color: Color

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color(hex: "#E2E8F0")).frame(height: 5)
            Capsule().fill(color).frame(height: 5)
                .scaleEffect(x: CGFloat(max(0.001, energy)), y: 1, anchor: .leading)
        }
        .frame(height: 5)
        .clipped()
    }
}

// MARK: - Small widget
struct SmallWidgetView: View {
    let entry: PacepalEntry

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white
            VStack(spacing: 0) {
                Spacer(minLength: 4)
                petSprite.padding(.bottom, 6)
                Spacer(minLength: 0)
                bottomStats
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
            }
            Text(String(format: "%.1f km", entry.todayKm))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#F9703E"))
                .padding(.trailing, 12)
                .padding(.bottom, 11)
        }
    }

    @ViewBuilder
    private var petSprite: some View {
        if let data = entry.petImageData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 108, height: 108)
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "#F9703E").opacity(0.12))
                .frame(width: 80, height: 80)
        }
    }

    private var bottomStats: some View {
        VStack(spacing: 5) {
            HStack(spacing: 6) {
                EnergyBar(energy: entry.energy, color: entry.energyColor)
                Text("\(Int(entry.energy * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(entry.energyColor)
                    .frame(width: 26, alignment: .trailing)
            }
            HStack {
                Text("Día \(entry.challengeDay)")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                Spacer()
            }
        }
    }
}

// MARK: - Medium widget
struct MediumWidgetView: View {
    let entry: PacepalEntry

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.white
            HStack(spacing: 16) {
                // Pet image
                if let data = entry.petImageData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 110)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#F9703E").opacity(0.12))
                        .frame(width: 80, height: 80)
                }
                // Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Energía")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#9AA5B4"))
                        Spacer()
                        Text("\(Int(entry.energy * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(entry.energyColor)
                    }
                    EnergyBar(energy: entry.energy, color: entry.energyColor)
                    Label("Día \(entry.challengeDay) de 66", systemImage: "calendar")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#616E7C"))
                    Text(entry.moodText)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(entry.energyColor.opacity(0.18)))
                }
            }
            .padding(16)
            Text(String(format: "%.1f km", entry.todayKm))
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#F9703E"))
                .padding(.trailing, 16)
                .padding(.bottom, 14)
        }
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
