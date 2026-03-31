import Foundation

// MARK: - Cell types (mirrors the JS constants: E, BD, OL, EP, FC, etc.)
enum PetCell: Equatable {
    case empty
    case body
    case outline
    case eyeWhite
    case eyePupil
    case eyeShine
    case mouth
    case cheek
    case shade
    case nose
    case face
    case tear
    case gold
    case speedLine
    case gray
    case accent1
    case accent2
    case lightning
}

// MARK: - Pose
enum PetPose: String, CaseIterable, Identifiable {
    case idle, happy, sad, angry, running, jump, dead, hurt, hype, dizzy, cheer, spin, bounce, dance, wave, flex, star, finish
    case victory, clap, skip, stretch, stomp, leap, salute, shimmy, kick, pump, twirl, sign
    var id: String { rawValue }

    var label: String {
        switch self {
        case .idle:    return "Idle"
        case .happy:   return "Happy"
        case .sad:     return "Sad"
        case .angry:   return "Angry"
        case .running: return "Run"
        case .jump:    return "Jump"
        case .dead:    return "Dead"
        case .hurt:    return "Hurt"
        case .hype:    return "Hype"
        case .dizzy:   return "Dizzy"
        case .cheer:   return "Cheer"
        case .spin:    return "Spin"
        case .bounce:  return "Bounce"
        case .dance:   return "Dance"
        case .wave:    return "Wave"
        case .flex:    return "Flex"
        case .star:    return "Star"
        case .finish:  return "Finish"
        case .victory: return "Victory"
        case .clap:    return "Clap"
        case .skip:    return "Skip"
        case .stretch: return "Stretch"
        case .stomp:   return "Stomp"
        case .leap:    return "Leap"
        case .salute:  return "Salute"
        case .shimmy:  return "Shimmy"
        case .kick:    return "Kick"
        case .pump:    return "Pump"
        case .twirl:   return "Twirl"
        case .sign:    return "Sign"
        }
    }

    var emoji: String {
        switch self {
        case .idle:    return "😐"
        case .happy:   return "✨"
        case .sad:     return "😢"
        case .angry:   return "😠"
        case .running: return "🏃"
        case .jump:    return "🦘"
        case .dead:    return "💀"
        case .hurt:    return "💥"
        case .hype:    return "⚡️"
        case .dizzy:   return "😵"
        case .cheer:   return "🙌"
        case .spin:    return "🌀"
        case .bounce:  return "🦋"
        case .dance:   return "💃"
        case .wave:    return "👋"
        case .flex:    return "💪"
        case .star:    return "⭐"
        case .finish:  return "🏁"
        case .victory: return "✌️"
        case .clap:    return "👏"
        case .skip:    return "🏃"
        case .stretch: return "🤸"
        case .stomp:   return "🦶"
        case .leap:    return "🦅"
        case .salute:  return "🫡"
        case .shimmy:  return "🕺"
        case .kick:    return "🦵"
        case .pump:    return "👊"
        case .twirl:   return "🌀"
        case .sign:    return "🔔"
        }
    }
}

// MARK: - Animal type
enum PetAnimalType: String, CaseIterable, Codable {
    case bunny, cat, bear, raccoon, mouse, frog, duck, axolotl, smooth
    case capuchin, mandrill, fox, lion, domo, pou
    case dog, tiger, panda
    case corgi, dragon
}

// MARK: - Body shape
enum PetBodyShape: String, Codable {
    case round, chubby, slim, pear, tall
}

// MARK: - Archetype label
extension PetAnimalType {
    func archetypeLabel(language: Language) -> String {
        switch self {
        case .bunny:    return language == .en ? "Swift"      : "Veloz"
        case .cat:      return language == .en ? "Agile"      : "Ágil"
        case .bear:     return language == .en ? "Strength"   : "Fuerza"
        case .raccoon:  return language == .en ? "Adaptable"  : "Adaptable"
        case .mouse:    return language == .en ? "Swift"      : "Veloz"
        case .frog:     return language == .en ? "Power"      : "Potencia"
        case .duck:     return language == .en ? "Resilient"  : "Resistente"
        case .axolotl:  return language == .en ? "Resilient"  : "Resiliente"
        case .smooth:   return language == .en ? "Free"       : "Libre"
        case .capuchin: return language == .en ? "Dynamic"    : "Dinámico"
        case .mandrill: return language == .en ? "Wild"       : "Salvaje"
        case .fox:      return language == .en ? "Strategist" : "Estratega"
        case .lion:     return language == .en ? "Dominant"   : "Dominante"
        case .domo:     return language == .en ? "Unstoppable": "Imparable"
        case .pou:      return language == .en ? "Consistent" : "Constante"
        case .dog:      return language == .en ? "Loyal"      : "Leal"
        case .tiger:    return language == .en ? "Fierce"     : "Feroz"
        case .panda:    return language == .en ? "Tenacious"  : "Tenaz"
        case .corgi:    return language == .en ? "Cheerful"   : "Alegre"
        case .dragon:   return language == .en ? "Legendary"  : "Legendario"
        }
    }
    var archetypeLabel: String { archetypeLabel(language: .es) }
}

// MARK: - Grid typealias
let GRID_SIZE = 24
typealias PetGrid = [[PetCell]]
