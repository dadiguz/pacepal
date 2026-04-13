import SwiftUI

// MARK: - Keys (mirror del App Group)
private let kAppGroup     = "group.io.dallio.PacePal"
private let kEnergyReset  = "w_energyResetDate"
private let kDecaySeconds = "w_decaySeconds"
private let kTodayKm      = "w_todayKm"
private let kChallengeDay = "w_challengeDay"
private let kMedalEarned  = "w_medalEarned"

// MARK: - Main view
struct ContentView: View {
    @State private var energy: Double    = 0
    @State private var todayKm: Double   = 0
    @State private var challengeDay: Int = 1
    @State private var petImage: UIImage? = nil
    @State private var showRun = false

    var body: some View {
        NavigationStack {
            Group {
                if petImage == nil {
                    notConfiguredView
                } else {
                    mainView
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { loadData() } label: {
                        Image(systemName: "arrow.clockwise").font(.caption2)
                    }
                }
            }
        }
        .onAppear { loadData() }
    }

    // MARK: - Not configured
    private var notConfiguredView: some View {
        VStack(spacing: 10) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
            Text("Abre Pacepal\nen tu iPhone")
                .font(.system(size: 13, weight: .semibold))
                .multilineTextAlignment(.center)
            Text("Tu compañero aparecerá aquí")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Main
    private var mainView: some View {
        ScrollView {
            VStack(spacing: 6) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 20)

                petSprite
                    .frame(width: 80, height: 80)

                energySection

                HStack(spacing: 12) {
                    statBadge(value: String(format: "%.2f", todayKm), label: "km hoy")
                    statBadge(value: "\(challengeDay)/66",             label: "día")
                }

                NavigationLink(destination: WatchRunView(onFinish: { km in
                    addKmToAppGroup(km)
                })) {
                    Label("Iniciar run", systemImage: "figure.run")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0.98, green: 0.44, blue: 0.24))
                .padding(.top, 4)
            }
            .padding(.horizontal, 8)
        }
    }

    // MARK: - Pet sprite
    @ViewBuilder
    private var petSprite: some View {
        if let img = petImage {
            Image(uiImage: img)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.15))
                .overlay(
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.orange.opacity(0.5))
                )
        }
    }

    // MARK: - Energy section
    private var energySection: some View {
        VStack(spacing: 3) {
            HStack {
                Text("Energía")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(energy * 100))%")
                    .font(.caption2.bold())
                    .foregroundStyle(energyColor)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.gray.opacity(0.25)).frame(height: 5)
                    Capsule().fill(energyColor).frame(width: geo.size.width * CGFloat(max(0.001, energy)), height: 5)
                }
            }
            .frame(height: 5)
        }
    }

    private var energyColor: Color {
        if energy >= 0.60 { return Color(red: 0.29, green: 0.87, blue: 0.50) }
        if energy >= 0.30 { return Color(red: 0.64, green: 0.90, blue: 0.21) }
        if energy >= 0.15 { return Color(red: 0.99, green: 0.83, blue: 0.30) }
        return Color(red: 0.88, green: 0.18, blue: 0.22)
    }

    // MARK: - Stat badge
    private func statBadge(value: String, label: String) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Data loading
    private func loadData() {
        let def = UserDefaults(suiteName: kAppGroup)
        let resetDate    = (def?.object(forKey: kEnergyReset) as? Date) ?? Date()
        let decaySeconds = def?.double(forKey: kDecaySeconds) ?? (48 * 3600)
        let medalEarned  = def?.bool(forKey: kMedalEarned) ?? false
        let elapsed      = Date().timeIntervalSince(resetDate)

        energy       = medalEarned ? 1.0 : max(0, min(1, 1.0 - elapsed / decaySeconds))
        todayKm      = def?.double(forKey: kTodayKm) ?? 0
        let rawDay   = def?.integer(forKey: kChallengeDay) ?? 0
        challengeDay = max(1, min(66, rawDay))

        let spriteURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: kAppGroup)?
            .appendingPathComponent("petSprite.png")
        if let url = spriteURL, let data = try? Data(contentsOf: url) {
            petImage = UIImage(data: data)
        }
    }

    // MARK: - Add km to App Group (watch run → iPhone picks it up)
    private func addKmToAppGroup(_ km: Double) {
        guard km >= 0.05 else { return }
        let def = UserDefaults(suiteName: kAppGroup)
        let current = def?.double(forKey: kTodayKm) ?? 0
        def?.set(current + km, forKey: kTodayKm)
        def?.set(Date(), forKey: "w_watchRunFinishedAt")
        def?.set(km, forKey: "w_watchLastRunKm")
        def?.synchronize()
        todayKm = current + km
    }
}
