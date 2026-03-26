import SwiftUI
import Observation

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
        case .pequeñines: return "Pequeñín"
        case .pro:        return "Pro"
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

    func onCharacterSelected() {
        setEnergy(0.60)
        challengeStartDate = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(challengeStartDate, forKey: "challengeStartDate")
        kmCountedForEnergy = 0
        UserDefaults.standard.set(0.0, forKey: "kmCountedForEnergy")
        isFirstRunForCharacter = true
    }
}
