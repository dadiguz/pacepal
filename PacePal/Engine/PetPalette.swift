import Foundation

// MARK: - Palette
struct PetPalette: Codable {
    let name: String
    let body: String
    let shade: String
    let face: String
    let eyeP: String
    let cheek: String
    var accent1: String
    var accent2: String

    init(_ name: String, body: String, shade: String, face: String,
         eyeP: String, cheek: String,
         accent1: String = "#F35627", accent2: String = "#FADB5F") {
        self.name = name; self.body = body; self.shade = shade
        self.face = face; self.eyeP = eyeP; self.cheek = cheek
        self.accent1 = accent1; self.accent2 = accent2
    }
}

// MARK: - Alebrije accent pool
let ALEBRIJE_ACCENTS: [String] = [
    "#E12D39", "#F35627", "#DE911D", "#FADB5F",
    "#5CB70B", "#27AB83", "#2CB1BC", "#0967D2",
    "#4C63B6", "#8719E0", "#DA127D", "#F191C1",
    "#AFF75C", "#62F4EB", "#A368FC", "#FF9466",
]

// MARK: - Palette library
let PALETTES: [PetPalette] = [
    PetPalette("seafoam",  body: "#044E54", shade: "#2CB1BC", face: "#BEF8FD", eyeP: "#044E54", cheek: "#F191C1"),
    PetPalette("ocean",    body: "#003E6B", shade: "#2680C2", face: "#DCEEFB", eyeP: "#003E6B", cheek: "#FAB38B"),
    PetPalette("amethyst", body: "#240754", shade: "#5D55FA", face: "#E6E6FF", eyeP: "#240754", cheek: "#DA127D"),
    PetPalette("jade",     body: "#014D40", shade: "#3EBD93", face: "#C6F7E2", eyeP: "#014D40", cheek: "#F9703E"),
    PetPalette("slate",    body: "#102A43", shade: "#627D98", face: "#D9E2EC", eyeP: "#102A43", cheek: "#EF8E58"),
    PetPalette("cherry",   body: "#610404", shade: "#D64545", face: "#FACDCD", eyeP: "#610404", cheek: "#F7D070"),
    PetPalette("honey",    body: "#513C06", shade: "#CB6E17", face: "#FCEFC7", eyeP: "#513C06", cheek: "#DA127D"),
    PetPalette("indigo",   body: "#19216C", shade: "#4C63B6", face: "#BED0F7", eyeP: "#19216C", cheek: "#E668A7"),
    PetPalette("meadow",   body: "#05400A", shade: "#3F9142", face: "#C1EAC5", eyeP: "#05400A", cheek: "#DA4A91"),
    PetPalette("berry",    body: "#5C0B33", shade: "#AD2167", face: "#FFE0F0", eyeP: "#5C0B33", cheek: "#F9DA8B"),
    PetPalette("sunset",   body: "#572508", shade: "#C65D21", face: "#FFD3BA", eyeP: "#572508", cheek: "#DA4A91"),
    PetPalette("sapphire", body: "#002159", shade: "#2186EB", face: "#B6E0FE", eyeP: "#002159", cheek: "#F191C1"),
    PetPalette("ink",      body: "#27241D", shade: "#625D52", face: "#FAF9F7", eyeP: "#27241D", cheek: "#DA4A91"),
    PetPalette("slate2",   body: "#1F2933", shade: "#3E4C59", face: "#F0F4F8", eyeP: "#1F2933", cheek: "#F35627"),
]
