import SwiftUI
import Observation

// MARK: - Achievement
// 11 milestones every 6 days of the 66-day challenge.
// Each corresponds to one background asset: achievement_1 … achievement_11.

struct Achievement: Identifiable {
    let day: Int
    let phrase: String
    var id: Int { day }
    var assetIndex: Int { day / 6 }
    var imageName: String { "achievement_\(assetIndex)" }

    var displayText: Text {
        let orange = Color(hex: "#F9703E")
        let dark   = Color(hex: "#1F2933")
        switch day {
        case 6:
            return Text("6 días. ").foregroundStyle(orange).bold()
                 + Text("Tu cuerpo ya recuerda el camino.").foregroundStyle(dark)
        case 12:
            return Text("12 días ").foregroundStyle(orange).bold()
                 + Text("corriendo. El hábito empieza a tomar ").foregroundStyle(dark)
                 + Text("forma.").foregroundStyle(orange).bold()
        case 18:
            return Text("18 días. ").foregroundStyle(orange).bold()
                 + Text("Tres semanas de ").foregroundStyle(dark)
                 + Text("movimiento real.").foregroundStyle(orange).bold()
        case 24:
            return Text("24 días. ").foregroundStyle(orange).bold()
                 + Text("La mitad del reto ya quedó atrás.").foregroundStyle(dark)
        case 30:
            return Text("Un mes completo. ").foregroundStyle(orange).bold()
                 + Text("Esto ya no es casualidad.").foregroundStyle(dark)
        case 36:
            return Text("36 días. ").foregroundStyle(orange).bold()
                 + Text("Más de la mitad del reto. ").foregroundStyle(dark)
                 + Text("No paras.").foregroundStyle(orange).bold()
        case 42:
            return Text("42 días. ").foregroundStyle(orange).bold()
                 + Text("Ya superaste el mito de los 21. ").foregroundStyle(dark)
                 + Text("Eres constancia.").foregroundStyle(orange).bold()
        case 48:
            return Text("48 días. ").foregroundStyle(orange).bold()
                 + Text("El final se acerca y ").foregroundStyle(dark)
                 + Text("tú sigues corriendo.").foregroundStyle(orange).bold()
        case 54:
            return Text("54 días. ").foregroundStyle(orange).bold()
                 + Text("A solo ").foregroundStyle(dark)
                 + Text("12 días ").foregroundStyle(orange).bold()
                 + Text("de lograrlo.").foregroundStyle(dark)
        case 60:
            return Text("60 días. ").foregroundStyle(orange).bold()
                 + Text("La recta final. ").foregroundStyle(dark)
                 + Text("No sueltes ahora.").foregroundStyle(orange).bold()
        default: // 66
            return Text("66 días.\n").foregroundStyle(orange).bold()
                 + Text("Cada mañana que elegiste salir cuando todo decía quedarte.\n").foregroundStyle(dark)
                 + Text("Cada kilómetro ").foregroundStyle(dark).bold()
                 + Text("cuando pensabas que no podías.\n\n").foregroundStyle(dark)
                 + Text("Rompiste la meta ").foregroundStyle(orange).bold()
                 + Text("y lo que construiste no desaparece.\n\n").foregroundStyle(dark)
                 + Text("Sigue corriendo.").foregroundStyle(orange).bold()
        }
    }

    /// Each milestone gets its own unique animation (11 unique poses for 11 milestones)
    var pose: PetPose {
        switch day {
        case 6:  return .running
        case 12: return .bounce
        case 18: return .cheer
        case 24: return .dance
        case 30: return .happy
        case 36: return .spin
        case 42: return .jump
        case 48: return .wave
        case 54: return .flex
        case 60: return .star
        default: return .finish  // day 66
        }
    }

    static let all: [Achievement] = [
        Achievement(day: 6,  phrase: "6 días. Tu cuerpo ya recuerda el camino."),
        Achievement(day: 12, phrase: "12 días corriendo. El hábito empieza a tomar forma."),
        Achievement(day: 18, phrase: "18 días. Tres semanas de movimiento real."),
        Achievement(day: 24, phrase: "24 días. La mitad del reto ya quedó atrás."),
        Achievement(day: 30, phrase: "Un mes completo. Esto ya no es casualidad."),
        Achievement(day: 36, phrase: "36 días. Más de la mitad del reto. No paras."),
        Achievement(day: 42, phrase: "42 días. Ya superaste el mito de los 21. Eres constancia."),
        Achievement(day: 48, phrase: "48 días. El final se acerca y tú sigues corriendo."),
        Achievement(day: 54, phrase: "54 días. A solo 12 días de lograrlo."),
        Achievement(day: 60, phrase: "60 días. La recta final. No sueltes ahora."),
        Achievement(day: 66, phrase: "66 días. Cada mañana que elegiste salir cuando todo decía quedarte. Cada kilómetro cuando pensabas que no podías. Rompiste la meta — y lo que construiste no desaparece. Sigue corriendo."),
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
        case .pequeñines: return "🧸 Pequeñín"
        case .pro:        return "🐺 Pro"
        }
    }

    var subtitle: String {
        switch self {
        case .pequeñines: return "La energía dura 7 días"
        case .pro:        return "La energía dura 36 horas"
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

    // Achievement milestones already seen by the user
    private(set) var seenAchievements: Set<Int>

    /// Seconds from 100% to 0% — driven by difficulty
    var decaySeconds: Double { difficulty.decaySeconds }

    init() {
        self.energyResetDate = UserDefaults.standard.object(forKey: "energyResetDate") as? Date ?? Date()
        self.kmCountedForEnergy = UserDefaults.standard.double(forKey: "kmCountedForEnergy")
        self.challengeStartDate = UserDefaults.standard.object(forKey: "challengeStartDate") as? Date ?? Calendar.current.startOfDay(for: Date())
        let diffStr = UserDefaults.standard.string(forKey: "difficulty") ?? Difficulty.pro.rawValue
        self.difficulty = Difficulty(rawValue: diffStr) ?? .pro
        self.onboardingCompleted = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        self.paywallDismissed = UserDefaults.standard.bool(forKey: "paywallDismissed")
        self.healthPermissionDone = UserDefaults.standard.bool(forKey: "healthPermissionDone")
        let seen = UserDefaults.standard.array(forKey: "seenAchievements") as? [Int] ?? []
        self.seenAchievements = Set(seen)
    }

    func completeOnboarding() {
        onboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }

    func dismissPaywall() {
        paywallDismissed = true
        UserDefaults.standard.set(true, forKey: "paywallDismissed")
    }

    func completeHealthPermission() {
        healthPermissionDone = true
        UserDefaults.standard.set(true, forKey: "healthPermissionDone")
    }

    func energy(at date: Date) -> Double {
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

    /// Call when a character is selected — starts at 60% to invite a first run
    /// Set to true when a brand-new character is chosen so HomeView
    /// knows to count today's existing km as fresh energy (not suppress them).
    var isFirstRunForCharacter = false

    func recordKmCounted(_ km: Double) {
        kmCountedForEnergy = km
        UserDefaults.standard.set(km, forKey: "kmCountedForEnergy")
    }

    // Returns the first milestone that's been reached but not yet shown
    var pendingAchievement: Achievement? {
        let dayNum = (Calendar.current.dateComponents([.day], from: challengeStartDate, to: Date()).day ?? 0) + 1
        return Achievement.all.first { dayNum >= $0.day && !seenAchievements.contains($0.day) }
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
        isFirstRunForCharacter = true
    }
}
