import Foundation

// MARK: - Profanity filter (ES + EN)
// Checks whether a string contains a blocked word.
// Comparison is case-insensitive and accent-insensitive.

enum ProfanityFilter {
    static func isClean(_ input: String) -> Bool {
        let normalized = input.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        for word in blockedWords {
            let normalizedWord = word.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            if normalized.contains(normalizedWord) { return false }
        }
        return true
    }

    // Common profanity in Spanish and English.
    // Kept as a flat list — add/remove as needed.
    private static let blockedWords: [String] = [
        // ES
        "puta", "puto", "perra", "perro", "mierda", "chinga", "chingo",
        "chingada", "pendejo", "pendeja", "cabron", "cabrona", "culero",
        "culera", "pinche", "verga", "pito", "coño", "joto", "zorra",
        "mamada", "mamadas", "mamar", "güey", "buey", "wey", "culo",
        "nalgas", "pene", "vagina", "tetas", "pezón", "pezones",
        "maricon", "maricón", "panocha", "panocho", "choto", "chota",
        "putiza", "carajo", "hostia", "follar", "coger", "ojete",
        // EN
        "fuck", "fucker", "fucking", "shit", "bitch", "asshole", "ass",
        "cunt", "cock", "dick", "pussy", "whore", "slut", "bastard",
        "damn", "crap", "piss", "twat", "wank", "nigga", "nigger",
        "faggot", "retard", "kike", "spic", "chink",
    ]
}
