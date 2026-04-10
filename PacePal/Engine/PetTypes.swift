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
    case victory, clap, skip, stretch, stomp, leap, salute, shimmy, kick, pump, twirl, sign, teaching, tired, drinking, navigate
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
        case .sign:     return "Sign"
        case .teaching: return "Teaching"
        case .tired:    return "Tired"
        case .drinking: return "Drinking"
        case .navigate: return "Navigate"
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
        case .sign:     return "🔔"
        case .teaching: return "📝"
        case .tired:    return "😮‍💨"
        case .drinking: return "💧"
        case .navigate: return "🗺️"
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

// MARK: - Archetype label (localized in Localized.swift, used only by main app target)

// MARK: - Grid typealias
let GRID_SIZE = 24
typealias PetGrid = [[PetCell]]
