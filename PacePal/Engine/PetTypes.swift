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
        }
    }
}

// MARK: - Animal type
enum PetAnimalType: String, CaseIterable, Codable {
    case bunny, cat, bear, raccoon, mouse, frog, duck, axolotl, smooth
    case capuchin, mandrill, fox, lion, domo, pou
    case dog, tiger, panda
}

// MARK: - Body shape
enum PetBodyShape: String, Codable {
    case round, chubby, slim, pear, tall
}

// MARK: - Archetype label
extension PetAnimalType {
    var archetypeLabel: String {
        switch self {
        case .bunny:    return "Veloz"
        case .cat:      return "Ágil"
        case .bear:     return "Fuerza"
        case .raccoon:  return "Adaptable"
        case .mouse:    return "Veloz"
        case .frog:     return "Potencia"
        case .duck:     return "Resistente"
        case .axolotl:  return "Resiliente"
        case .smooth:   return "Libre"
        case .capuchin: return "Dinámico"
        case .mandrill: return "Salvaje"
        case .fox:      return "Estratega"
        case .lion:     return "Dominante"
        case .domo:     return "Imparable"
        case .pou:      return "Constante"
        case .dog:      return "Leal"
        case .tiger:    return "Feroz"
        case .panda:    return "Tenaz"
        }
    }
}

// MARK: - Grid typealias
let GRID_SIZE = 24
typealias PetGrid = [[PetCell]]
