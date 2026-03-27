import SwiftUI
import Observation

// MARK: - Achievement
// 23 milestones: day 1, then every 3 days through day 64, plus day 66.
// Each maps to background_01 … background_23 in order.

struct Achievement: Identifiable {
    let day: Int
    let index: Int  // 1-based, maps to background_01 … background_23
    let phrase: String
    var id: Int { day }
    var imageName: String { String(format: "background_%02d", index) }

    var displayText: Text {
        let orange = Color(hex: "#F9703E")
        let white  = Color.white
        switch day {
        case 1:
            return Text("Día 1. ").foregroundStyle(orange).bold()
                 + Text("Empezaste cuando era más fácil quedarte. Eso ya es ").foregroundStyle(white)
                 + Text("más que la mayoría.").foregroundStyle(orange).bold()
        case 4:
            return Text("4 días seguidos. ").foregroundStyle(orange).bold()
                 + Text("Tu cuerpo ya siente el ritmo ").foregroundStyle(white)
                 + Text("en los pies.").foregroundStyle(orange).bold()
        case 7:
            return Text("Una semana completa. ").foregroundStyle(orange).bold()
                 + Text("Tu cuerpo empieza a recordar el camino y ").foregroundStyle(white)
                 + Text("quiere más.").foregroundStyle(orange).bold()
        case 10:
            return Text("10 días. ").foregroundStyle(orange).bold()
                 + Text("La disciplina ya no es esfuerzo, ").foregroundStyle(white)
                 + Text("se está instalando sola.").foregroundStyle(orange).bold()
        case 13:
            return Text("13 días. ").foregroundStyle(orange).bold()
                 + Text("Casi dos semanas de ").foregroundStyle(white)
                 + Text("movimiento real y constante.").foregroundStyle(orange).bold()
        case 16:
            return Text("16 días. ").foregroundStyle(orange).bold()
                 + Text("Ya no tienes que convencerte de salir. El hábito ").foregroundStyle(white)
                 + Text("ya es tuyo.").foregroundStyle(orange).bold()
        case 19:
            return Text("19 días. ").foregroundStyle(orange).bold()
                 + Text("Cada mañana que elegiste moverte en lugar de quedarte ").foregroundStyle(white)
                 + Text("cuenta.").foregroundStyle(orange).bold()
        case 22:
            return Text("22 días. ").foregroundStyle(orange).bold()
                 + Text("Tres semanas completas de ").foregroundStyle(white)
                 + Text("correr sin excusas.").foregroundStyle(orange).bold()
        case 25:
            return Text("25 días. ").foregroundStyle(orange).bold()
                 + Text("Ya pasaste la mitad del reto. No hay marcha atrás, ").foregroundStyle(white)
                 + Text("no paras.").foregroundStyle(orange).bold()
        case 28:
            return Text("28 días. ").foregroundStyle(orange).bold()
                 + Text("Un mes entero de decisiones correctas, una tras otra.").foregroundStyle(white)
        case 31:
            return Text("31 días. ").foregroundStyle(orange).bold()
                 + Text("El primer mes completo quedó atrás. Cada kilómetro fue ").foregroundStyle(white)
                 + Text("tuyo.").foregroundStyle(orange).bold()
        case 34:
            return Text("34 días. ").foregroundStyle(orange).bold()
                 + Text("La mayoría ya se rindió hace tiempo. ").foregroundStyle(white)
                 + Text("Tú sigues corriendo.").foregroundStyle(orange).bold()
        case 37:
            return Text("37 días. ").foregroundStyle(orange).bold()
                 + Text("Más de la mitad del camino recorrido. El final ya ").foregroundStyle(white)
                 + Text("se acerca.").foregroundStyle(orange).bold()
        case 40:
            return Text("40 días. ").foregroundStyle(orange).bold()
                 + Text("Eres constancia, disciplina y ").foregroundStyle(white)
                 + Text("movimiento puro.").foregroundStyle(orange).bold()
        case 43:
            return Text("43 días. ").foregroundStyle(orange).bold()
                 + Text("Cada salida, cada kilómetro, es ").foregroundStyle(white)
                 + Text("una victoria tuya.").foregroundStyle(orange).bold()
        case 46:
            return Text("46 días. ").foregroundStyle(orange).bold()
                 + Text("A solo ").foregroundStyle(white)
                 + Text("20 días ").foregroundStyle(orange).bold()
                 + Text("de cruzar la meta. Aguanta.").foregroundStyle(white)
        case 49:
            return Text("49 días. ").foregroundStyle(orange).bold()
                 + Text("Siete semanas de ").foregroundStyle(white)
                 + Text("pura determinación y ganas.").foregroundStyle(orange).bold()
        case 52:
            return Text("52 días. ").foregroundStyle(orange).bold()
                 + Text("La recta final ya ").foregroundStyle(white)
                 + Text("está muy cerca.").foregroundStyle(orange).bold()
        case 55:
            return Text("55 días. ").foregroundStyle(orange).bold()
                 + Text("Solo 11 días más entre tú y la meta. ").foregroundStyle(white)
                 + Text("No sueltes ahora.").foregroundStyle(orange).bold()
        case 58:
            return Text("58 días. ").foregroundStyle(orange).bold()
                 + Text("Ya puedes sentirla. ").foregroundStyle(white)
                 + Text("La meta está justo ahí.").foregroundStyle(orange).bold()
        case 61:
            return Text("61 días. ").foregroundStyle(orange).bold()
                 + Text("Solo 5 días más entre tú y los 66. ").foregroundStyle(white)
                 + Text("Tú puedes.").foregroundStyle(orange).bold()
        case 64:
            return Text("64 días. ").foregroundStyle(orange).bold()
                 + Text("La línea de meta ").foregroundStyle(white)
                 + Text("está a dos pasos.").foregroundStyle(orange).bold()
        default: // 66
            return Text("66 días. ").foregroundStyle(orange).bold()
                 + Text("Elegiste salir cuando todo decía quedarte. Corriste cuando pensabas que no podías. ").foregroundStyle(white)
                 + Text("Rompiste la meta ").foregroundStyle(orange).bold()
                 + Text("y lo construiste. ").foregroundStyle(white)
                 + Text("Ahora sigue corriendo.").foregroundStyle(orange).bold()
        }
    }

    /// Unique celebratory animation per milestone (cycles through 12 poses, finish for day 66)
    var pose: PetPose {
        let cycle: [PetPose] = [.running, .happy, .hype, .jump, .cheer, .bounce,
                                .dance, .spin, .wave, .flex, .star, .running]
        if day == 66 { return .finish }
        let i = (index - 1) % cycle.count
        return cycle[i]
    }

    static let all: [Achievement] = [
        Achievement(day:  1, index:  1, phrase: "Día 1. Empezaste."),
        Achievement(day:  4, index:  2, phrase: "4 días. Ya tienes el ritmo en los pies."),
        Achievement(day:  7, index:  3, phrase: "Una semana. Tu cuerpo empieza a recordar."),
        Achievement(day: 10, index:  4, phrase: "10 días. La disciplina se está instalando."),
        Achievement(day: 13, index:  5, phrase: "13 días. Casi dos semanas de movimiento real."),
        Achievement(day: 16, index:  6, phrase: "16 días. El hábito ya es tuyo."),
        Achievement(day: 19, index:  7, phrase: "19 días. Cada salida cuenta."),
        Achievement(day: 22, index:  8, phrase: "22 días. Tres semanas completas corriendo."),
        Achievement(day: 25, index:  9, phrase: "25 días. A mitad del reto. No paras."),
        Achievement(day: 28, index: 10, phrase: "28 días. Un mes de decisiones correctas."),
        Achievement(day: 31, index: 11, phrase: "31 días. El mes completo quedó atrás."),
        Achievement(day: 34, index: 12, phrase: "34 días. La mayoría ya se rindió. Tú sigues."),
        Achievement(day: 37, index: 13, phrase: "37 días. Más de la mitad. El final se acerca."),
        Achievement(day: 40, index: 14, phrase: "40 días. Eres constancia en movimiento."),
        Achievement(day: 43, index: 15, phrase: "43 días. Cada salida es una victoria."),
        Achievement(day: 46, index: 16, phrase: "46 días. A solo 20 días de lograrlo."),
        Achievement(day: 49, index: 17, phrase: "49 días. Siete semanas de pura determinación."),
        Achievement(day: 52, index: 18, phrase: "52 días. La recta final está cerca."),
        Achievement(day: 55, index: 19, phrase: "55 días. A solo 11 días. No sueltes ahora."),
        Achievement(day: 58, index: 20, phrase: "58 días. Ya puedes verla. La meta está ahí."),
        Achievement(day: 61, index: 21, phrase: "61 días. 5 días más. Tú puedes."),
        Achievement(day: 64, index: 22, phrase: "64 días. La línea de meta está a la vuelta."),
        Achievement(day: 66, index: 23, phrase: "66 días. Elegiste salir cuando todo decía quedarte. Corriste cuando pensabas que no podías. Rompiste la meta y lo construiste. Ahora sigue corriendo."),
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
