import Foundation

// MARK: - Spot (replaces (Int,Int,Int) tuple for Codable support)
struct PetSpot: Codable {
    let dx: Int
    let dy: Int
    let colorIndex: Int  // 0 = accent1, 1 = accent2
}

// MARK: - DNA
struct PetDNA: Identifiable, Codable {
    let id: UUID
    let bodyCx: Double
    let bodyShape: PetBodyShape
    let bodyRy: Double
    let bodyRx: Double
    let bodyCy: Double
    let earTopY: Double
    let animalType: PetAnimalType
    let earSp: Double
    let bunnyEarH: Double
    let bearEarR: Double
    let armStyle: Int
    let eyeSp: Double
    let eyeStyle: Int
    let hasMuzzle: Bool
    let mouthStyle: Int
    let hasNose: Bool
    let hasCheeks: Bool
    let hasMarking: Bool
    let markingStyle: Int
    let hasBow: Bool
    let hasTail: Bool
    let tailOffset: Int
    let spots: [PetSpot]
    var palette: PetPalette
    var name: String

    init(bodyCx: Double, bodyShape: PetBodyShape, bodyRy: Double, bodyRx: Double,
         bodyCy: Double, earTopY: Double, animalType: PetAnimalType,
         earSp: Double, bunnyEarH: Double, bearEarR: Double,
         armStyle: Int, eyeSp: Double, eyeStyle: Int,
         hasMuzzle: Bool, mouthStyle: Int, hasNose: Bool,
         hasCheeks: Bool, hasMarking: Bool, markingStyle: Int,
         hasBow: Bool, hasTail: Bool, tailOffset: Int,
         spots: [PetSpot], palette: PetPalette, name: String,
         id: UUID = UUID()) {
        self.id = id
        self.bodyCx = bodyCx; self.bodyShape = bodyShape
        self.bodyRy = bodyRy; self.bodyRx = bodyRx
        self.bodyCy = bodyCy; self.earTopY = earTopY
        self.animalType = animalType; self.earSp = earSp
        self.bunnyEarH = bunnyEarH; self.bearEarR = bearEarR
        self.armStyle = armStyle; self.eyeSp = eyeSp; self.eyeStyle = eyeStyle
        self.hasMuzzle = hasMuzzle; self.mouthStyle = mouthStyle; self.hasNose = hasNose
        self.hasCheeks = hasCheeks; self.hasMarking = hasMarking; self.markingStyle = markingStyle
        self.hasBow = hasBow; self.hasTail = hasTail; self.tailOffset = tailOffset
        self.spots = spots; self.palette = palette; self.name = name
    }

    // MARK: - Random generation (faithful port of JS generateDNA)
    static func random() -> PetDNA {
        func rndInt(_ a: Int, _ b: Int) -> Int { Int.random(in: a...b) }
        func chance(_ p: Double) -> Bool { Double.random(in: 0..<1) < p }
        func pick<T>(_ arr: [T]) -> T { arr[Int.random(in: 0..<arr.count)] }

        let bodyCx: Double = 12
        let shapes: [PetBodyShape] = [.round, .round, .chubby, .chubby, .slim, .pear, .tall]
        let bodyShape = pick(shapes)
        var bodyRy: Double, bodyRx: Double
        switch bodyShape {
        case .round:  bodyRy = Double(rndInt(6, 7)); bodyRx = Double(rndInt(5, 7))
        case .chubby: bodyRy = 6; bodyRx = 7
        case .slim:   bodyRy = 7; bodyRx = Double(rndInt(3, 4))
        case .pear:   bodyRy = Double(rndInt(6, 7)); bodyRx = Double(rndInt(5, 7))
        case .tall:   bodyRy = 7; bodyRx = Double(rndInt(5, 6))
        }

        let bodyCy  = 18.0 - bodyRy
        let earTopY = 18.0 - 2.0 * bodyRy

        let animalType: PetAnimalType
        if earTopY >= 5 {
            animalType = pick([.bunny, .bunny, .cat, .cat, .bear, .bear, .raccoon, .raccoon, .mouse, .axolotl, .smooth])
        } else if earTopY >= 3 {
            animalType = pick([.bear, .bear, .raccoon, .raccoon, .frog, .duck, .axolotl, .smooth])
        } else {
            animalType = pick([.frog, .frog, .raccoon, .duck, .smooth])
        }

        let earSp     = (bodyRx * 0.5).rounded()
        let bunnyEarH = animalType == .bunny ? Double(max(1, min(rndInt(3, 5), Int(earTopY) - 1))) : 0
        let bearEarR  = animalType == .bear ? (earTopY >= 4 ? 2.2 : 1.6) : 0.0

        let armStyle   = rndInt(0, 2)
        let eyeSp      = Double(rndInt(3, 4))
        let eyeStyle   = rndInt(0, 3)
        let hasMuzzle  = animalType != .frog && animalType != .axolotl && animalType != .raccoon && chance(0.6)
        let mouthStyle = rndInt(0, 3)
        let hasNose    = !hasMuzzle && animalType != .frog && animalType != .axolotl && chance(0.4)
        let hasCheeks  = chance(0.6)
        let hasMarking = chance(0.3)
        let markingStyle = rndInt(0, 1)
        let hasBow     = chance(0.2) && earTopY >= 4 && animalType != .raccoon && animalType != .axolotl
        let hasTail    = chance(0.2)
        let tailOffset = rndInt(0, 3)

        let a1 = pick(ALEBRIJE_ACCENTS)
        let a2 = pick(ALEBRIJE_ACCENTS.filter { $0 != a1 })
        let spots: [PetSpot] = (0..<6).map { _ in
            PetSpot(
                dx: rndInt(-Int((bodyRx * 0.7).rounded()), Int((bodyRx * 0.7).rounded())),
                dy: rndInt(-Int((bodyRy * 0.6).rounded()), Int((bodyRy * 0.6).rounded())),
                colorIndex: rndInt(0, 1)
            )
        }

        var base = pick(PALETTES)
        base.accent1 = a1
        base.accent2 = a2

        return PetDNA(
            bodyCx: bodyCx, bodyShape: bodyShape, bodyRy: bodyRy, bodyRx: bodyRx,
            bodyCy: bodyCy, earTopY: earTopY, animalType: animalType,
            earSp: earSp, bunnyEarH: bunnyEarH, bearEarR: bearEarR,
            armStyle: armStyle, eyeSp: eyeSp, eyeStyle: eyeStyle,
            hasMuzzle: hasMuzzle, mouthStyle: mouthStyle, hasNose: hasNose,
            hasCheeks: hasCheeks, hasMarking: hasMarking, markingStyle: markingStyle,
            hasBow: hasBow, hasTail: hasTail, tailOffset: tailOffset,
            spots: spots, palette: base,
            name: PetDNA.randomName()
        )
    }

    // MARK: - Preset characters (smooth always first)
    static func presets() -> [PetDNA] {
        [
            // Smooth – sapphire (minimal, no animal features)
            PetDNA(bodyCx: 12, bodyShape: .round, bodyRy: 7, bodyRx: 6, bodyCy: 11, earTopY: 4,
                   animalType: .smooth, earSp: 3, bunnyEarH: 0, bearEarR: 0,
                   armStyle: 1, eyeSp: 3, eyeStyle: 0, hasMuzzle: false, mouthStyle: 1,
                   hasNose: false, hasCheeks: true, hasMarking: false, markingStyle: 0,
                   hasBow: false, hasTail: false, tailOffset: 0,
                   spots: [PetSpot(dx:2,dy:1,colorIndex:0), PetSpot(dx:-2,dy:2,colorIndex:1),
                           PetSpot(dx:3,dy:-1,colorIndex:0), PetSpot(dx:-3,dy:1,colorIndex:1),
                           PetSpot(dx:0,dy:3,colorIndex:0), PetSpot(dx:1,dy:-2,colorIndex:1)],
                   palette: { var p = PALETTES[11]; p.accent1 = "#AFF75C"; p.accent2 = "#62F4EB"; return p }(),
                   name: "Cipactli"),

            // Bear – honey
            PetDNA(bodyCx: 12, bodyShape: .round, bodyRy: 6, bodyRx: 6, bodyCy: 12, earTopY: 6,
                   animalType: .bear, earSp: 3, bunnyEarH: 0, bearEarR: 2.2,
                   armStyle: 0, eyeSp: 2, eyeStyle: 2, hasMuzzle: true, mouthStyle: 0,
                   hasNose: false, hasCheeks: true, hasMarking: false, markingStyle: 0,
                   hasBow: false, hasTail: false, tailOffset: 0,
                   spots: [PetSpot(dx:2,dy:1,colorIndex:0), PetSpot(dx:-3,dy:2,colorIndex:1),
                           PetSpot(dx:3,dy:-1,colorIndex:0), PetSpot(dx:-2,dy:-2,colorIndex:1),
                           PetSpot(dx:1,dy:3,colorIndex:0), PetSpot(dx:-1,dy:0,colorIndex:1)],
                   palette: { var p = PALETTES[6]; p.accent1 = "#F35627"; p.accent2 = "#FADB5F"; return p }(),
                   name: "Itzcoatl"),

            // Bunny – amethyst
            PetDNA(bodyCx: 12, bodyShape: .round, bodyRy: 6, bodyRx: 5, bodyCy: 12, earTopY: 6,
                   animalType: .bunny, earSp: 3, bunnyEarH: 4, bearEarR: 0,
                   armStyle: 1, eyeSp: 2, eyeStyle: 3, hasMuzzle: false, mouthStyle: 1,
                   hasNose: false, hasCheeks: true, hasMarking: false, markingStyle: 0,
                   hasBow: true, hasTail: false, tailOffset: 0,
                   spots: [PetSpot(dx:-2,dy:2,colorIndex:0), PetSpot(dx:2,dy:1,colorIndex:1),
                           PetSpot(dx:-1,dy:-1,colorIndex:0), PetSpot(dx:3,dy:0,colorIndex:1),
                           PetSpot(dx:-3,dy:1,colorIndex:0), PetSpot(dx:0,dy:3,colorIndex:1)],
                   palette: { var p = PALETTES[2]; p.accent1 = "#DA127D"; p.accent2 = "#A368FC"; return p }(),
                   name: "Xochitl"),

            // Cat – sunset
            PetDNA(bodyCx: 12, bodyShape: .chubby, bodyRy: 6, bodyRx: 7, bodyCy: 12, earTopY: 6,
                   animalType: .cat, earSp: 4, bunnyEarH: 0, bearEarR: 0,
                   armStyle: 2, eyeSp: 3, eyeStyle: 0, hasMuzzle: true, mouthStyle: 0,
                   hasNose: false, hasCheeks: true, hasMarking: true, markingStyle: 1,
                   hasBow: false, hasTail: true, tailOffset: 1,
                   spots: [PetSpot(dx:3,dy:2,colorIndex:0), PetSpot(dx:-2,dy:-1,colorIndex:1),
                           PetSpot(dx:1,dy:-2,colorIndex:0), PetSpot(dx:4,dy:1,colorIndex:1),
                           PetSpot(dx:-4,dy:0,colorIndex:0), PetSpot(dx:2,dy:3,colorIndex:1)],
                   palette: { var p = PALETTES[10]; p.accent1 = "#F35627"; p.accent2 = "#FADB5F"; return p }(),
                   name: "Tepeyotl"),

            // Frog – jade
            PetDNA(bodyCx: 12, bodyShape: .round, bodyRy: 7, bodyRx: 6, bodyCy: 11, earTopY: 4,
                   animalType: .frog, earSp: 3, bunnyEarH: 0, bearEarR: 0,
                   armStyle: 0, eyeSp: 3, eyeStyle: 1, hasMuzzle: false, mouthStyle: 2,
                   hasNose: false, hasCheeks: false, hasMarking: false, markingStyle: 0,
                   hasBow: false, hasTail: false, tailOffset: 0,
                   spots: [PetSpot(dx:2,dy:1,colorIndex:0), PetSpot(dx:-2,dy:2,colorIndex:1),
                           PetSpot(dx:3,dy:-1,colorIndex:0), PetSpot(dx:-3,dy:1,colorIndex:1),
                           PetSpot(dx:1,dy:3,colorIndex:0), PetSpot(dx:-1,dy:-2,colorIndex:1)],
                   palette: { var p = PALETTES[3]; p.accent1 = "#5CB70B"; p.accent2 = "#27AB83"; return p }(),
                   name: "Quetzalco"),

            // Raccoon – slate
            PetDNA(bodyCx: 12, bodyShape: .round, bodyRy: 6, bodyRx: 5, bodyCy: 12, earTopY: 6,
                   animalType: .raccoon, earSp: 3, bunnyEarH: 0, bearEarR: 0,
                   armStyle: 2, eyeSp: 3, eyeStyle: 1, hasMuzzle: false, mouthStyle: 1,
                   hasNose: false, hasCheeks: false, hasMarking: false, markingStyle: 0,
                   hasBow: false, hasTail: false, tailOffset: 0,
                   spots: [PetSpot(dx:-1,dy:2,colorIndex:0), PetSpot(dx:2,dy:-1,colorIndex:1),
                           PetSpot(dx:-3,dy:0,colorIndex:0), PetSpot(dx:1,dy:3,colorIndex:1),
                           PetSpot(dx:-2,dy:-2,colorIndex:0), PetSpot(dx:3,dy:2,colorIndex:1)],
                   palette: { var p = PALETTES[13]; p.accent1 = "#9AA5B4"; p.accent2 = "#E2E8F0"; return p }(),
                   name: "Mixtli"),

            // Mouse – berry
            PetDNA(bodyCx: 12, bodyShape: .round, bodyRy: 6, bodyRx: 5, bodyCy: 12, earTopY: 6,
                   animalType: .mouse, earSp: 3, bunnyEarH: 0, bearEarR: 0,
                   armStyle: 0, eyeSp: 3, eyeStyle: 2, hasMuzzle: false, mouthStyle: 0,
                   hasNose: true, hasCheeks: true, hasMarking: false, markingStyle: 0,
                   hasBow: true, hasTail: true, tailOffset: 0,
                   spots: [PetSpot(dx:2,dy:1,colorIndex:0), PetSpot(dx:-2,dy:3,colorIndex:1),
                           PetSpot(dx:3,dy:0,colorIndex:0), PetSpot(dx:-1,dy:-2,colorIndex:1),
                           PetSpot(dx:1,dy:2,colorIndex:0), PetSpot(dx:-3,dy:1,colorIndex:1)],
                   palette: { var p = PALETTES[9]; p.accent1 = "#F191C1"; p.accent2 = "#FADB5F"; return p }(),
                   name: "Xochipilli"),

            // Axolotl – seafoam
            PetDNA(bodyCx: 12, bodyShape: .chubby, bodyRy: 6, bodyRx: 7, bodyCy: 12, earTopY: 6,
                   animalType: .axolotl, earSp: 3, bunnyEarH: 0, bearEarR: 0,
                   armStyle: 0, eyeSp: 3, eyeStyle: 2, hasMuzzle: false, mouthStyle: 2,
                   hasNose: false, hasCheeks: true, hasMarking: false, markingStyle: 0,
                   hasBow: false, hasTail: false, tailOffset: 1,
                   spots: [PetSpot(dx:2,dy:1,colorIndex:0), PetSpot(dx:-2,dy:2,colorIndex:1),
                           PetSpot(dx:3,dy:-1,colorIndex:0), PetSpot(dx:-3,dy:1,colorIndex:1),
                           PetSpot(dx:0,dy:3,colorIndex:0), PetSpot(dx:1,dy:-2,colorIndex:1)],
                   palette: { var p = PALETTES[0]; p.accent1 = "#DA127D"; p.accent2 = "#62F4EB"; return p }(),
                   name: "Axolitl"),
        ]
    }

    // MARK: - Name generator
    private static func randomName() -> String {
        let pre = ["Xo","Tla","Quet","Itz","Cit","Mix","Co","Hui","Tep",
                   "Oc","Mo","Xoch","Tec","Mez","Cha","No","Ate","Cuau","Teo","Ix"]
        let suf = ["tl","atl","otl","tzin","ito","ita","ali","xitl",
                   "zotl","coatl","palco","lote","quil","pilli","tlan","cal"]
        return pre.randomElement()! + suf.randomElement()!
    }
}
