import SwiftUI
import Observation

@Observable
final class AppState {
    var selectedCharacter: PetDNA?

    // Date when energy was last set to 100%
    private(set) var energyResetDate: Date

    // Date when the 66-day challenge started
    private(set) var challengeStartDate: Date

    // Onboarding & paywall state
    private(set) var onboardingCompleted: Bool
    private(set) var paywallDismissed: Bool
    private(set) var healthPermissionDone: Bool

    init() {
        self.energyResetDate = UserDefaults.standard.object(forKey: "energyResetDate") as? Date ?? Date()
        self.challengeStartDate = UserDefaults.standard.object(forKey: "challengeStartDate") as? Date ?? Calendar.current.startOfDay(for: Date())
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

    // 100% on reset → 0% after 48 hours
    func energy(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(energyResetDate)
        return max(0, min(1, 1.0 - elapsed / (36 * 3600)))
    }

    func resetEnergy() {
        energyResetDate = Date()
        UserDefaults.standard.set(energyResetDate, forKey: "energyResetDate")
    }

    /// 1 km = 30% energy, capped at 100%.
    func addEnergy(km: Double, at date: Date = Date()) {
        let current   = energy(at: date)
        let target    = min(1.0, current + km * 0.30)
        let newElapsed = (1.0 - target) * 36 * 3600
        energyResetDate = date.addingTimeInterval(-newElapsed)
        UserDefaults.standard.set(energyResetDate, forKey: "energyResetDate")
    }

    /// Sets energy to a specific fraction 0–1 (for testing)
    func setEnergy(_ fraction: Double) {
        let elapsed = (1.0 - max(0, min(1, fraction))) * 36 * 3600
        energyResetDate = Date().addingTimeInterval(-elapsed)
        UserDefaults.standard.set(energyResetDate, forKey: "energyResetDate")
    }

    /// Call when a character is selected — starts at 60% to invite a first run
    func onCharacterSelected() {
        setEnergy(0.60)
        challengeStartDate = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(challengeStartDate, forKey: "challengeStartDate")
    }
}
