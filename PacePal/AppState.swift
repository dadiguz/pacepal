import SwiftUI
import Observation
import WidgetKit

// MARK: - Achievement
// 23 milestones: day 1, then every 3 days through day 64, plus day 66.
// Each maps to background_01 … background_23 in order.

struct Achievement: Identifiable, Equatable {
    let day: Int
    let index: Int  // 1-based, maps to background_01 … background_23
    let phraseKey: String
    var phrase: String { L(phraseKey) }
    var id: Int { day }
    var imageName: String { String(format: "background_%02d", index) }

    var displayText: Text {
        let orange = Color(hex: "#F9703E")
        let white  = Color.white
        let d = day
        switch d {
        case 46:
            return Text(L("achievement.\(d).part1")).foregroundStyle(orange).bold()
                 + Text(L("achievement.\(d).part2")).foregroundStyle(white)
                 + Text(L("achievement.\(d).part3")).foregroundStyle(orange).bold()
                 + Text(L("achievement.\(d).part4")).foregroundStyle(white)
        case 28:
            return Text(L("achievement.\(d).part1")).foregroundStyle(orange).bold()
                 + Text(L("achievement.\(d).part2")).foregroundStyle(white)
        case 66:
            return Text(L("achievement.\(d).part1")).foregroundStyle(orange).bold()
                 + Text(L("achievement.\(d).part2")).foregroundStyle(white)
                 + Text(L("achievement.\(d).part3")).foregroundStyle(orange).bold()
                 + Text(L("achievement.\(d).part4")).foregroundStyle(white)
                 + Text(L("achievement.\(d).part5")).foregroundStyle(orange).bold()
        default:
            return Text(L("achievement.\(d).part1")).foregroundStyle(orange).bold()
                 + Text(L("achievement.\(d).part2")).foregroundStyle(white)
                 + Text(L("achievement.\(d).part3")).foregroundStyle(orange).bold()
        }
    }

    /// Unique celebratory animation per milestone — one distinct pose per day
    var pose: PetPose {
        if day == 66 { return .finish }
        let map: [PetPose] = [
            .running, .happy,   .hype,    .jump,  .cheer,
            .bounce,  .dance,   .spin,    .wave,  .flex,
            .star,    .victory, .clap,    .skip,  .stretch,
            .stomp,   .leap,    .salute,  .shimmy,.kick,
            .pump,    .twirl
        ]
        return map[min(index - 1, map.count - 1)]
    }

    static let all: [Achievement] = [
        Achievement(day:  1, index:  1, phraseKey: "achievement.1.short"),
        Achievement(day:  4, index:  2, phraseKey: "achievement.4.short"),
        Achievement(day:  7, index:  3, phraseKey: "achievement.7.short"),
        Achievement(day: 10, index:  4, phraseKey: "achievement.10.short"),
        Achievement(day: 13, index:  5, phraseKey: "achievement.13.short"),
        Achievement(day: 16, index:  6, phraseKey: "achievement.16.short"),
        Achievement(day: 19, index:  7, phraseKey: "achievement.19.short"),
        Achievement(day: 22, index:  8, phraseKey: "achievement.22.short"),
        Achievement(day: 25, index:  9, phraseKey: "achievement.25.short"),
        Achievement(day: 28, index: 10, phraseKey: "achievement.28.short"),
        Achievement(day: 31, index: 11, phraseKey: "achievement.31.short"),
        Achievement(day: 34, index: 12, phraseKey: "achievement.34.short"),
        Achievement(day: 37, index: 13, phraseKey: "achievement.37.short"),
        Achievement(day: 40, index: 14, phraseKey: "achievement.40.short"),
        Achievement(day: 43, index: 15, phraseKey: "achievement.43.short"),
        Achievement(day: 46, index: 16, phraseKey: "achievement.46.short"),
        Achievement(day: 49, index: 17, phraseKey: "achievement.49.short"),
        Achievement(day: 52, index: 18, phraseKey: "achievement.52.short"),
        Achievement(day: 55, index: 19, phraseKey: "achievement.55.short"),
        Achievement(day: 58, index: 20, phraseKey: "achievement.58.short"),
        Achievement(day: 61, index: 21, phraseKey: "achievement.61.short"),
        Achievement(day: 64, index: 22, phraseKey: "achievement.64.short"),
        Achievement(day: 66, index: 23, phraseKey: "achievement.66.short"),
    ]
}

// MARK: - Difficulty

enum Difficulty: String, CaseIterable {
    case pequeñines = "pequeñines"
    case pro        = "pro"

    var decaySeconds: Double {
        switch self {
        case .pequeñines: return 7 * 24 * 3600   // 7 days
        case .pro:        return 36 * 3600         // 36 hours
        }
    }

    var label: String {
        switch self {
        case .pequeñines: return L("difficulty.casual_label")
        case .pro:        return L("difficulty.pro_label")
        }
    }

    var subtitle: String {
        switch self {
        case .pequeñines: return L("difficulty.casual_subtitle")
        case .pro:        return L("difficulty.pro_subtitle")
        }
    }
}

@Observable
final class AppState {
    var selectedCharacter: PetDNA?

    // Date when energy was last set to 100%
    private(set) var energyResetDate: Date

    // Km already credited to energy for the current character (persisted across launches)
    private(set) var kmCountedForEnergy: Double

    // Date when the 66-day challenge started
    private(set) var challengeStartDate: Date

    // Difficulty mode
    var difficulty: Difficulty {
        didSet { UserDefaults.standard.set(difficulty.rawValue, forKey: "difficulty") }
    }

    // Onboarding & paywall state
    private(set) var onboardingCompleted: Bool
    private(set) var paywallDismissed: Bool
    private(set) var healthPermissionDone: Bool
    private(set) var notificationPermissionDone: Bool
    private(set) var widgetPromptDone: Bool

    // Sounds on/off
    var soundsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundsEnabled, forKey: "soundsEnabled") }
    }

    // Selected background image name (nil = default gradient)
    private(set) var selectedBackground: String?

    // Achievement milestones already seen by the user
    private(set) var seenAchievements: Set<Int>

    // True once the user logs their first run — gates achievement triggers
    private(set) var challengeStarted: Bool

    // True once the 66-day challenge is completed — stops energy decay permanently
    private(set) var medalEarned: Bool

    /// Seconds from 100% to 0% — driven by difficulty
    var decaySeconds: Double { difficulty.decaySeconds }

    init() {
        self.energyResetDate = UserDefaults.standard.object(forKey: "energyResetDate") as? Date ?? Date()
        self.kmCountedForEnergy = UserDefaults.standard.double(forKey: "kmCountedForEnergy")
        self.challengeStartDate = UserDefaults.standard.object(forKey: "challengeStartDate") as? Date ?? Calendar.current.startOfDay(for: Date())
        let diffStr = UserDefaults.standard.string(forKey: "difficulty") ?? Difficulty.pro.rawValue
        self.difficulty = Difficulty(rawValue: diffStr) ?? .pro
        self.soundsEnabled = UserDefaults.standard.object(forKey: "soundsEnabled") as? Bool ?? true
        self.onboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        self.paywallDismissed = UserDefaults.standard.bool(forKey: "paywallDismissed")
        self.healthPermissionDone = UserDefaults.standard.bool(forKey: "healthPermissionDone")
        self.notificationPermissionDone = UserDefaults.standard.bool(forKey: "notificationPermissionDone")
        self.widgetPromptDone = UserDefaults.standard.bool(forKey: "widgetPromptDone")
        let seen = UserDefaults.standard.array(forKey: "seenAchievements") as? [Int] ?? []
        self.seenAchievements = Set(seen)
        self.challengeStarted = UserDefaults.standard.bool(forKey: "challengeStarted")
        self.medalEarned = UserDefaults.standard.bool(forKey: "medalEarned")
        self.selectedBackground = UserDefaults.standard.string(forKey: "selectedBackground")
    }

    func completeOnboarding() {
        onboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }

    func dismissPaywall() {
        paywallDismissed = true
        UserDefaults.standard.set(true, forKey: "paywallDismissed")
    }

    func resetPaywall() {
        paywallDismissed = false
        UserDefaults.standard.set(false, forKey: "paywallDismissed")
    }

    func completeHealthPermission() {
        healthPermissionDone = true
        UserDefaults.standard.set(true, forKey: "healthPermissionDone")
    }

    func completeNotificationPermission() {
        notificationPermissionDone = true
        UserDefaults.standard.set(true, forKey: "notificationPermissionDone")
    }

    func completeWidgetPrompt() {
        widgetPromptDone = true
        UserDefaults.standard.set(true, forKey: "widgetPromptDone")
    }

    func energy(at date: Date) -> Double {
        if medalEarned { return 1.0 }
        let elapsed = date.timeIntervalSince(energyResetDate)
        return max(0, min(1, 1.0 - elapsed / decaySeconds))
    }

    func resetEnergy() {
        energyResetDate = Date()
        UserDefaults.standard.set(energyResetDate, forKey: "energyResetDate")
    }

    /// 1 km = 10% energy, capped at 100%.
    func addEnergy(km: Double, at date: Date = Date()) {
        let current    = energy(at: date)
        let target     = min(1.0, current + km * 0.10)
        let newElapsed = (1.0 - target) * decaySeconds
        energyResetDate = date.addingTimeInterval(-newElapsed)
        UserDefaults.standard.set(energyResetDate, forKey: "energyResetDate")
    }

    /// Sets energy to a specific fraction 0–1 (for testing)
    func setEnergy(_ fraction: Double) {
        let elapsed = (1.0 - max(0, min(1, fraction))) * decaySeconds
        energyResetDate = Date().addingTimeInterval(-elapsed)
        UserDefaults.standard.set(energyResetDate, forKey: "energyResetDate")
    }

    /// Reschedules energy-drop notifications with the pet's current name and sprite image.
    func scheduleNotifications(petName: String, attachmentURL: URL? = nil) {
        NotificationManager.scheduleEnergyNotifications(
            petName: petName,
            energyResetDate: energyResetDate,
            decaySeconds: decaySeconds,
            attachmentURL: attachmentURL
        )
    }

    /// Call when a character is selected — starts at 60% to invite a first run
    /// Set to true when a brand-new character is chosen so HomeView
    /// knows to count today's existing km as fresh energy (not suppress them).
    var isFirstRunForCharacter = false

    func recordKmCounted(_ km: Double) {
        kmCountedForEnergy = km
        UserDefaults.standard.set(km, forKey: "kmCountedForEnergy")
    }

    func grantMedal() {
        medalEarned = true
        UserDefaults.standard.set(true, forKey: "medalEarned")
        resetEnergy()
    }

    func confirmChallengeStart() {
        guard !challengeStarted else { return }
        challengeStarted = true
        UserDefaults.standard.set(true, forKey: "challengeStarted")
    }

    // Returns the first milestone that's been reached but not yet shown
    var pendingAchievement: Achievement? {
        guard challengeStarted else { return nil }
        let dayNum = (Calendar.current.dateComponents([.day], from: challengeStartDate, to: Date()).day ?? 0) + 1
        return Achievement.all.first { dayNum >= $0.day && !seenAchievements.contains($0.day) }
    }

    func selectBackground(_ name: String?) {
        selectedBackground = name
        if let name { UserDefaults.standard.set(name, forKey: "selectedBackground") }
        else { UserDefaults.standard.removeObject(forKey: "selectedBackground") }
    }

    func markAchievementSeen(_ day: Int) {
        var updated = seenAchievements
        updated.insert(day)
        seenAchievements = updated
        UserDefaults.standard.set(Array(seenAchievements), forKey: "seenAchievements")
    }

    #if DEBUG
    /// Shifts the challenge start date backwards and auto-marks passed milestones as seen.
    func shiftChallengeDay(by days: Int) {
        challengeStartDate = Calendar.current.date(byAdding: .day, value: -days, to: challengeStartDate) ?? challengeStartDate
        UserDefaults.standard.set(challengeStartDate, forKey: "challengeStartDate")
        let dayNum = (Calendar.current.dateComponents([.day], from: challengeStartDate, to: Date()).day ?? 0) + 1
        // Mark all reached milestones except the most recent one as seen,
        // so the latest milestone stays pending and the modal can trigger.
        let reached = Achievement.all.filter { $0.day <= dayNum }
        var updated = seenAchievements
        for a in reached.dropLast() { updated.insert(a.day) }
        seenAchievements = updated
        UserDefaults.standard.set(Array(seenAchievements), forKey: "seenAchievements")
    }

    func revokeMedal() {
        medalEarned = false
        UserDefaults.standard.set(false, forKey: "medalEarned")
    }

    /// Resets the challenge to day 1 and clears all seen achievements.
    func resetChallengeToToday() {
        challengeStartDate = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(challengeStartDate, forKey: "challengeStartDate")
        seenAchievements = []
        UserDefaults.standard.set([] as [Int], forKey: "seenAchievements")
    }
    #endif

    func onCharacterSelected() {
        setEnergy(0.60)
        challengeStartDate = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(challengeStartDate, forKey: "challengeStartDate")
        kmCountedForEnergy = 0
        UserDefaults.standard.set(0.0, forKey: "kmCountedForEnergy")
        seenAchievements = []
        UserDefaults.standard.set([] as [Int], forKey: "seenAchievements")
        challengeStarted = false
        UserDefaults.standard.set(false, forKey: "challengeStarted")
        medalEarned = false
        UserDefaults.standard.set(false, forKey: "medalEarned")
        isFirstRunForCharacter = true
        selectedBackground = nil
        UserDefaults.standard.removeObject(forKey: "selectedBackground")
        syncToWidget(km: 0)
    }

    // MARK: - Widget sync

    private static let widgetDefaults = UserDefaults(suiteName: "group.io.dallio.PacePal")

    /// Renders the pet sprite as PNG data using UIGraphicsImageRenderer (main app process only).
    private func renderPetPNG(dna: PetDNA, energy: Double) -> Data? {
        let pose: PetPose
        if medalEarned              { pose = .idle  }
        else if energy <= 0         { pose = .dead  }
        else if energy <= 0.14      { pose = .dizzy }
        else if energy <= 0.25      { pose = .sad   }
        else if energy <= 0.50      { pose = .angry }
        else if energy <= 0.90      { pose = .idle  }
        else if energy <= 0.95      { pose = .happy }
        else if energy <  0.99      { pose = .jump  }
        else                        { pose = .hype  }

        let accessories: [PetAccessory] = medalEarned ? [.medal66] : []
        let grid = buildCharacterGrid(dna: dna, pose: pose, frame: 0)
        let pixelSize: CGFloat = 5
        let size = CGFloat(GRID_SIZE) * pixelSize
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let img = renderer.image { ctx in
            let cgCtx = ctx.cgContext
            let hideGold = !accessories.isEmpty
            for y in 0..<GRID_SIZE {
                for x in 0..<GRID_SIZE {
                    let cell = grid[y][x]
                    if hideGold && cell == .gold { continue }
                    guard let color = colorForCell(cell, gx: x, gy: y, dna: dna) else { continue }
                    cgCtx.setFillColor(UIColor(color).cgColor)
                    cgCtx.fill(CGRect(x: CGFloat(x) * pixelSize, y: CGFloat(y) * pixelSize,
                                      width: pixelSize, height: pixelSize))
                }
            }
            // Draw accessories
            for p in accessoryPixels(for: accessories, bodyCx: Int(dna.bodyCx), bodyCy: Int(dna.bodyCy)) {
                cgCtx.setFillColor(CGColor(srgbRed: CGFloat(p.r)/255, green: CGFloat(p.g)/255, blue: CGFloat(p.b)/255, alpha: 1))
                cgCtx.fill(CGRect(x: CGFloat(p.x) * pixelSize, y: CGFloat(p.y) * pixelSize,
                                  width: pixelSize, height: pixelSize))
            }
        }
        return img.pngData()
    }

    /// Writes all widget-relevant data to the shared App Group and reloads timelines.
    func syncToWidget(km: Double) {
        guard let dna = selectedCharacter else {
            print("⚠️ syncToWidget: selectedCharacter es nil")
            return
        }
        guard let dnaData = try? JSONEncoder().encode(dna) else {
            print("⚠️ syncToWidget: fallo al encodear PetDNA")
            return
        }
        guard let d = Self.widgetDefaults else {
            print("❌ syncToWidget: App Group no disponible — verifica entitlements")
            return
        }
        let currentEnergy = energy(at: Date())
        d.set(energyResetDate, forKey: "w_energyResetDate")
        d.set(difficulty.decaySeconds, forKey: "w_decaySeconds")
        d.set(dnaData, forKey: "w_petDNAData")
        d.set(km, forKey: "w_todayKm")
        let day = (Calendar.current.dateComponents([.day], from: challengeStartDate, to: Date()).day ?? 0) + 1
        d.set(day, forKey: "w_challengeDay")
        d.set(medalEarned, forKey: "w_medalEarned")
        // Write PNG to shared file (more reliable than UserDefaults for binary data)
        let spriteURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.dallio.PacePal")?
            .appendingPathComponent("petSprite.png")
        if let pngData = renderPetPNG(dna: dna, energy: currentEnergy), let url = spriteURL {
            try? pngData.write(to: url, options: .atomic)
            print("✅ syncToWidget: escrito — energía \(Int(currentEnergy * 100))%, km \(km), día \(day), dna \(dna.name), imagen \(pngData.count)b → \(url.lastPathComponent)")
        } else {
            if let url = spriteURL { try? FileManager.default.removeItem(at: url) }
            print("⚠️ syncToWidget: escrito — sin imagen — energía \(Int(currentEnergy * 100))%, dna \(dna.name)")
        }
        d.synchronize()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
