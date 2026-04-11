import SwiftUI

// MARK: - Obstacle sprite system
// Same pixel-art philosophy as the pet: explicit Color? grids, one entry per pixel.

typealias Px = Color?

// Cactus palette
private let cO: Px = Color(hex: "#1B5E20")   // dark outline
private let cM: Px = Color(hex: "#2E7D32")   // main green
private let cL: Px = Color(hex: "#43A047")   // light (right/top edge)
private let cH: Px = Color(hex: "#66BB6A")   // highlight

// Bird palette
private let bO: Px = Color(hex: "#263238")   // dark outline
private let bM: Px = Color(hex: "#546E7A")   // main slate
private let bL: Px = Color(hex: "#78909C")   // light slate

private let n: Px = nil                      // transparent

// MARK: - Sprite data

/// A multi-frame pixel art sprite for game obstacles.
struct ObstacleSprite {
    /// frames[frameIndex][row][col] — Color? (nil = transparent)
    let frames: [[[Px]]]
    let pixelSize: Double          // pt per pixel
    let groundOffset: Double       // how many pt above ground the sprite bottom floats (aerial)

    var frameCount: Int { frames.count }
    var cols: Int { frames[0].first?.count ?? 0 }
    var rows: Int { frames[0].count }
    var width:  Double { Double(cols) * pixelSize }
    var height: Double { Double(rows) * pixelSize }
}

// MARK: - Cactus A  (10 × 16, single with left arm)

private let cactusAFrames: [[[Px]]] = [[
    // col: 0   1   2   3   4   5   6   7   8   9
           [n,  n,  n,  n,  cO, cO, n,  n,  n,  n ],   // 0
           [n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 1
           [cO, cO, n,  n,  cM, cL, n,  n,  n,  n ],   // 2 arm tip
           [cM, cL, n,  n,  cM, cL, n,  n,  n,  n ],   // 3 arm tip
           [cM, cL, n,  n,  cM, cL, n,  n,  n,  n ],   // 4 arm tip
           [cO, cO, cO, cO, cM, cL, n,  n,  n,  n ],   // 5 arm top wall
           [cM, cM, cM, cM, cM, cL, n,  n,  n,  n ],   // 6 arm body
           [cH, cL, cL, cO, cM, cL, n,  n,  n,  n ],   // 7 arm highlight
           [cO, cO, cO, cO, cM, cL, n,  n,  n,  n ],   // 8 arm bottom wall
           [n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 9
           [n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 10
           [n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 11
           [n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 12
           [n,  n, cO, cO, cO,  cO, cO, cO, n,  n ],   // 13 base top
           [n,  n, cM, cM, cM,  cL, cH, cO, n,  n ],   // 14 base
           [n,  n, cO, cO, cO,  cO, cO, cO, n,  n ],   // 15 base bottom
]]

// MARK: - Cactus B  (14 × 18, two cacti side by side)

private let cactusBFrames: [[[Px]]] = [[
    // col: 0   1   2   3   4   5   6   7   8   9   10  11  12  13
           [n,  n,  cO, cO, n,  n,  n,  n,  cO, cO, n,  n,  n,  n ],   // 0
           [n,  n,  cM, cL, n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 1
           [n,  n,  cM, cL, n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 2
           [n,  n,  cM, cL, cO, cO, cO, cO, cM, cL, n,  n,  n,  n ],   // 3 right arm top wall
           [n,  n,  cM, cL, cM, cM, cM, cM, cM, cL, n,  n,  n,  n ],   // 4 right arm body
           [n,  n,  cM, cL, cO, cO, cO, cO, cM, cL, n,  n,  n,  n ],   // 5 right arm bottom
           [cO, cO, cM, cL, n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 6 left arm tip
           [cM, cL, cM, cL, n,  n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 7 left arm tip
           [cO, cO, cO, cM, cL, n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 8 left arm top
           [cM, cM, cM, cM, cL, n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 9 left arm body
           [cO, cO, cO, cM, cL, n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 10 left arm bottom
           [n,  n,  n,  cM, cL, n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 11
           [n,  n,  n,  cM, cL, n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 12
           [n,  n,  n,  cM, cL, n,  n,  n,  cM, cL, n,  n,  n,  n ],   // 13
           [n, cO, cO, cO, cO, cO, cO,  cO, cO, cO, cO, cO, cO,  n ],  // 14 base top
           [n, cM, cM, cM, cM, cL, cH,  cM, cM, cM, cL, cH, cO,  n ],  // 15 base
           [n, cM, cM, cM, cM, cL, cH,  cM, cM, cM, cL, cH, cO,  n ],  // 16 base mid
           [n, cO, cO, cO, cO, cO, cO,  cO, cO, cO, cO, cO, cO,  n ],  // 17 base bottom
]]

// MARK: - Bird  (12 × 7, 2-frame wing flap)

// Frame 0 — wings level
private let birdF0: [[Px]] = [
    // col: 0   1   2   3   4   5   6   7   8   9   10  11
           [n,  bO, bM, bO, n,  n,  n,  n,  bO, bM, bO, n  ],  // 0 wing tips
           [bO, bM, bM, bM, bO, n,  n,  bO, bM, bM, bM, bO ],  // 1 wings
           [n,  bO, bM, bM, bM, bO, bO, bM, bM, bM, bO, n  ],  // 2 wing inner
           [n,  n,  bO, bM, bL, bM, bM, bL, bM, bO, n,  n  ],  // 3 body
           [n,  n,  n,  bO, bM, bM, bM, bM, bO, n,  n,  n  ],  // 4 body
           [n,  n,  n,  n,  bO, bM, bM, bO, n,  n,  n,  n  ],  // 5 tail
           [n,  n,  n,  n,  bO, bO, bO, bO, n,  n,  n,  n  ],  // 6 tail tip
]

// Frame 1 — wings dipped
private let birdF1: [[Px]] = [
    // col: 0   1   2   3   4   5   6   7   8   9   10  11
           [n,  n,  n,  bO, bM, bM, bM, bM, bO, n,  n,  n  ],  // 0 body top
           [n,  n,  bO, bM, bL, bM, bM, bL, bM, bO, n,  n  ],  // 1 body
           [n,  bO, bM, bM, bM, bO, bO, bM, bM, bM, bO, n  ],  // 2 wing inner
           [bO, bM, bM, bM, bO, n,  n,  bO, bM, bM, bM, bO ],  // 3 wings out
           [n,  bO, bM, bO, n,  n,  n,  n,  bO, bM, bO, n  ],  // 4 wing tips down
           [n,  n,  n,  n,  bO, bM, bM, bO, n,  n,  n,  n  ],  // 5 tail
           [n,  n,  n,  n,  bO, bO, bO, bO, n,  n,  n,  n  ],  // 6 tail tip
]

// MARK: - Public API

enum ObstacleKind {
    case cactusSmall, cactusDouble, bird

    /// Ground obstacles only after score threshold for aerial.
    static func random(score: Int) -> ObstacleKind {
        if score > 300, Int.random(in: 0..<4) == 0 { return .bird }
        return Bool.random() ? .cactusSmall : .cactusDouble
    }
}

func obstacleSprite(for kind: ObstacleKind) -> ObstacleSprite {
    switch kind {
    case .cactusSmall:
        return ObstacleSprite(frames: cactusAFrames, pixelSize: 3.5, groundOffset: 0)
    case .cactusDouble:
        return ObstacleSprite(frames: cactusBFrames, pixelSize: 3.5, groundOffset: 0)
    case .bird:
        return ObstacleSprite(frames: [birdF0, birdF1], pixelSize: 3.5, groundOffset: 55)
    }
}
