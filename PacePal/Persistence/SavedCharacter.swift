import SwiftData
import Foundation

@Model
final class SavedCharacter {
    var dnaData: Data
    var savedAt: Date

    init(dnaData: Data) {
        self.dnaData = dnaData
        self.savedAt = Date()
    }

    var dna: PetDNA? {
        try? JSONDecoder().decode(PetDNA.self, from: dnaData)
    }
}
