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
}

// MARK: - Pose
enum PetPose: String, CaseIterable, Identifiable {
    case idle, happy, sad, running, jump, dead, hurt
    var id: String { rawValue }

    var label: String {
        switch self {
        case .idle:    return "Idle"
        case .happy:   return "Happy"
        case .sad:     return "Sad"
        case .running: return "Run"
        case .jump:    return "Jump"
        case .dead:    return "Dead"
        case .hurt:    return "Hurt"
        }
    }

    var emoji: String {
        switch self {
        case .idle:    return "😐"
        case .happy:   return "✨"
        case .sad:     return "😢"
        case .running: return "🏃"
        case .jump:    return "🦘"
        case .dead:    return "💀"
        case .hurt:    return "💥"
        }
    }
}

// MARK: - Animal type
enum PetAnimalType: String, CaseIterable, Codable {
    case bunny, cat, bear, dog, mouse, frog, duck, axolotl, smooth
}

// MARK: - Body shape
enum PetBodyShape: String, Codable {
    case round, chubby, slim, pear, tall
}

// MARK: - Grid typealias
let GRID_SIZE = 24
typealias PetGrid = [[PetCell]]
