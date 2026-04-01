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
    // New
    PetPalette("celeste",    body: "#1A6FAD", shade: "#65BAE8", face: "#DCEEFB", eyeP: "#0A3660", cheek: "#F9703E"),
    PetPalette("tangerine",  body: "#C25D10", shade: "#F9A45C", face: "#FFF3E4", eyeP: "#7A3000", cheek: "#F191C1"),
    PetPalette("pearl",      body: "#8AAFC8", shade: "#C8DEF0", face: "#FFFFFF", eyeP: "#3A5470", cheek: "#F9703E"),
    PetPalette("mint",       body: "#045E50", shade: "#2CC9A8", face: "#CCFAF2", eyeP: "#012E27", cheek: "#F9703E"),
    PetPalette("rose",       body: "#A8294A", shade: "#F0709A", face: "#FFE4EE", eyeP: "#540018", cheek: "#FADB5F"),
    // New themed palettes
    PetPalette("planta",         body: "#1E5C6A", shade: "#4FA3B8", face: "#C8EEF5", eyeP: "#1E5C6A", cheek: "#E88995", accent1: "#5FA77A", accent2: "#E88995"),
    PetPalette("fuego",          body: "#8A4A00", shade: "#F28C28", face: "#FFF0D6", eyeP: "#8A4A00", cheek: "#E94B35", accent1: "#E94B35", accent2: "#2F8F9D"),
    PetPalette("agua",           body: "#1B6A96", shade: "#4DA8DA", face: "#D6F0FF", eyeP: "#1B6A96", cheek: "#F9703E", accent1: "#F6D55C", accent2: "#4DA8DA"),
    PetPalette("veneno",         body: "#6A3580", shade: "#B97ACB", face: "#EED6F8", eyeP: "#6A3580", cheek: "#F191C1", accent1: "#E8D8EE", accent2: "#6FAF9C"),
    PetPalette("psiquico",       body: "#1A4E78", shade: "#4A90C2", face: "#C8E4F5", eyeP: "#1A4E78", cheek: "#F25F5C", accent1: "#F25F5C", accent2: "#EAD2AC"),
    PetPalette("fuego_canino",   body: "#8A4800", shade: "#F08A24", face: "#FFF0D0", eyeP: "#2E2A2A", cheek: "#F5E6C8", accent1: "#2E2A2A", accent2: "#F5E6C8"),
    PetPalette("lucha",          body: "#4A5C62", shade: "#9FAFB3", face: "#E8F0F2", eyeP: "#4A5C62", cheek: "#E94B3C", accent1: "#F4D35E", accent2: "#E94B3C"),
    PetPalette("planta_simple",  body: "#7A9A20", shade: "#CDE46B", face: "#F2FBCE", eyeP: "#3A5000", cheek: "#D9A5A5", accent1: "#7FB77E", accent2: "#D9A5A5"),
    PetPalette("agua_roca",      body: "#3A3C6A", shade: "#6C6FA3", face: "#D8D9EE", eyeP: "#1E2040", cheek: "#D96C6C", accent1: "#E3C94A", accent2: "#D96C6C"),
    PetPalette("psiquico_fairy", body: "#C06080", shade: "#F5C6D6", face: "#FFECF2", eyeP: "#2F4F6F", cheek: "#F28CA3", accent1: "#F28CA3", accent2: "#2F4F6F"),
    PetPalette("fuego_luchador", body: "#8A2E00", shade: "#F06A2F", face: "#FFDEC8", eyeP: "#1F2A44", cheek: "#F2D16B", accent1: "#F2D16B", accent2: "#1F2A44"),
    PetPalette("digital",        body: "#7A1010", shade: "#D94C4C", face: "#FFD0D0", eyeP: "#7A1010", cheek: "#F9703E", accent1: "#4FA3B8", accent2: "#D9D9D9"),
    PetPalette("agua_cocodrilo", body: "#1A6364", shade: "#4CA7A8", face: "#C8F0F0", eyeP: "#1A6364", cheek: "#F9703E", accent1: "#F4D06F", accent2: "#A63D40"),
    PetPalette("planta_pajaro",  body: "#2E6C10", shade: "#6DBE45", face: "#D8F7C4", eyeP: "#1A3A08", cheek: "#F9703E", accent1: "#F2D94E", accent2: "#D94C4C"),
]
