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
    // Blues
    PetPalette("sapphire",   body: "#002159", shade: "#2186EB", face: "#B6E0FE", eyeP: "#002159", cheek: "#F191C1"),
    PetPalette("ocean",      body: "#003E6B", shade: "#2680C2", face: "#DCEEFB", eyeP: "#003E6B", cheek: "#F9703E"),
    PetPalette("indigo",     body: "#19216C", shade: "#4C63B6", face: "#BED0F7", eyeP: "#19216C", cheek: "#F9703E"),
    // Greens
    PetPalette("bulbasaur",  body: "#185020", shade: "#50BC54", face: "#D0F5D4", eyeP: "#0A2810", cheek: "#F9703E"),
    PetPalette("deepteal",   body: "#003D38", shade: "#2A9484", face: "#CCF0EC", eyeP: "#001E1B", cheek: "#F9703E"),
    PetPalette("lime",       body: "#2D5A00", shade: "#6DC40A", face: "#E8FFD0", eyeP: "#162C00", cheek: "#F9703E"),
    // Pinks & reds
    PetPalette("jigglypuff", body: "#C03070", shade: "#F570A8", face: "#FFE0F0", eyeP: "#620830", cheek: "#F9703E"),
    PetPalette("sylveon",    body: "#980066", shade: "#DC40A0", face: "#FFD0F2", eyeP: "#4A0030", cheek: "#FADB5F"),
    // Yellows & warm
    PetPalette("pikachu",    body: "#C07800", shade: "#F0C030", face: "#FFFACC", eyeP: "#5A3400", cheek: "#F9703E"),
    // Purples
    PetPalette("gengar",     body: "#3A0E70", shade: "#8040C8", face: "#ECD8FF", eyeP: "#1C0638", cheek: "#F9703E"),
    PetPalette("mew",        body: "#6030A8", shade: "#B070F0", face: "#F0E0FF", eyeP: "#301860", cheek: "#F9703E"),
    // Neutrals
    PetPalette("slate",      body: "#1F2933", shade: "#3E4C59", face: "#F0F4F8", eyeP: "#1F2933", cheek: "#F35627"),
    PetPalette("steel",      body: "#243B53", shade: "#627D98", face: "#D9E2EC", eyeP: "#102A43", cheek: "#F9703E"),
]
