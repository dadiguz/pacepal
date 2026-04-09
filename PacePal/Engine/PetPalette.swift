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
    PetPalette("sapphire",   body: "#002159", shade: "#2186EB", face: "#B6E0FE", eyeP: "#002159",  cheek: "#F191C1"),
    PetPalette("slate",      body: "#1F2933", shade: "#3E4C59", face: "#F0F4F8", eyeP: "#1F2933",  cheek: "#F35627"),

    // Dusty pink and navy — body: navy, face: dusty pink
    PetPalette("rosa_navy",  body: "#1B3458", shade: "#2D5080", face: "#D4A0A8", eyeP: "#0D1E35",  cheek: "#E8C8CC"),
    // Olive and gold — body: olive, face: gold
    PetPalette("oliva_oro",  body: "#4A5A22", shade: "#6B8030", face: "#D4A835", eyeP: "#252E0F",  cheek: "#E8CC6A"),
    // Plum and cream — body: plum, face: cream
    PetPalette("ciruela",    body: "#4A1040", shade: "#6B2060", face: "#F0E0C8", eyeP: "#250820",  cheek: "#D4B090"),
    // Burnt orange and teal — body: teal, face: burnt orange
    PetPalette("naranja_teal", body: "#1A5C6A", shade: "#267080", face: "#E8782A", eyeP: "#0D2E35", cheek: "#F0A860"),
    // Mustard and grey — body: dark mustard, face: mustard, cheek: grey
    PetPalette("mostaza",    body: "#5A4810", shade: "#8A7020", face: "#CCA030", eyeP: "#2D2508",  cheek: "#9A9A9A"),
    // Black cherry and blush — body: black cherry, face: blush
    PetPalette("cereza",     body: "#4A0820", shade: "#700C30", face: "#F0C0C8", eyeP: "#200410",  cheek: "#E8A0B0"),
    // Forest green and sand — body: forest green, face: sand
    PetPalette("bosque",     body: "#1A4028", shade: "#286040", face: "#D8C8A0", eyeP: "#0D2014",  cheek: "#E8D8B8"),
    // Copper and white — body: copper, face: white
    PetPalette("cobre",      body: "#8A4A20", shade: "#B06030", face: "#F8F0E8", eyeP: "#3A1C08",  cheek: "#D4A878"),
    // Rust and off-white — body: rust, face: off-white
    PetPalette("oxido",      body: "#8A2C1A", shade: "#B04030", face: "#F5EDE0", eyeP: "#3A1008",  cheek: "#D4A090"),
    // Denim blue and taupe — body: denim, face: taupe
    PetPalette("denim",      body: "#2A3D6A", shade: "#405A9A", face: "#C8B8A8", eyeP: "#141E35",  cheek: "#A89888"),
    // Chocolate and peach — body: chocolate, face: peach
    PetPalette("chocolate",  body: "#2A1408", shade: "#40200C", face: "#F0B898", eyeP: "#140A04",  cheek: "#E8A880"),
    // Mint and silver grey — body: dark mint, face: silver
    PetPalette("menta",      body: "#2A6A50", shade: "#409070", face: "#C0D0C8", eyeP: "#143028",  cheek: "#A8B8B0"),
    // Eggplant and light grey — body: eggplant, face: light grey
    PetPalette("berenjena",  body: "#3A1860", shade: "#5A2890", face: "#D0C8D8", eyeP: "#1C0C30",  cheek: "#B0A8C0"),
    // Turquoise and coral — body: turquoise, face: coral
    PetPalette("turquesa",   body: "#0A7878", shade: "#109898", face: "#F0806A", eyeP: "#053C3C",  cheek: "#F8B0A0"),
    // Burgundy and gold — body: burgundy, face: gold
    PetPalette("bordo",      body: "#5A0818", shade: "#880C24", face: "#D4A830", eyeP: "#2D0408",  cheek: "#E8CC70"),
    // Stone blue and ivory — body: stone blue, face: ivory
    PetPalette("piedra",     body: "#3A4E6A", shade: "#5A7098", face: "#F0ECD8", eyeP: "#1C2635",  cheek: "#D8D4C0"),
    // Lemon yellow and navy — body: navy, face: lemon
    PetPalette("limon",      body: "#1A2858", shade: "#283C88", face: "#E8D020", eyeP: "#0D1428",  cheek: "#F0E060"),
    // Moss green and cream — body: moss, face: cream
    PetPalette("musgo",      body: "#3A5020", shade: "#587830", face: "#F0E8D0", eyeP: "#1C2810",  cheek: "#D8D0B0"),
    // Rose gold and charcoal — body: charcoal, face: rose gold
    PetPalette("carbon",     body: "#2A2A30", shade: "#404048", face: "#C89088", eyeP: "#141418",  cheek: "#E0B0A8"),
    // Lavender and slate — body: slate, face: lavender
    PetPalette("lavanda",    body: "#404858", shade: "#5A6478", face: "#C8B8D8", eyeP: "#202430",  cheek: "#A898B8"),
    // Sandy brown and teal — body: teal, face: sandy
    PetPalette("arena",      body: "#1A5860", shade: "#287888", face: "#C8A870", eyeP: "#0D2C30",  cheek: "#E0C898"),
    // Red and beige — body: red, face: beige
    PetPalette("rojo_beige", body: "#8A1818", shade: "#B02020", face: "#E8D8C0", eyeP: "#3A0808",  cheek: "#D0B898"),
    // Sky blue and bronze — body: bronze, face: sky blue
    PetPalette("bronce",     body: "#7A5020", shade: "#A86828", face: "#A8C8E0", eyeP: "#3A2810",  cheek: "#D4A848"),
    // Deep green and blush — body: deep green, face: blush
    PetPalette("pino",       body: "#0A3020", shade: "#185040", face: "#F0C0C8", eyeP: "#051810",  cheek: "#E8A8B0"),
]
