import SwiftUI

// MARK: - 16-bit color renderer

/// Decomposes a hex color string into (r, g, b) in 0–255 range
private func rgb(_ hex: String) -> (Double, Double, Double) {
    let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var n: UInt64 = 0
    Scanner(string: h).scanHexInt64(&n)
    return (Double((n >> 16) & 0xFF), Double((n >> 8) & 0xFF), Double(n & 0xFF))
}

/// Shifts brightness of an rgb triple, clamping to 0–255
private func tone(_ r: Double, _ g: Double, _ b: Double, _ amt: Double) -> Color {
    Color(.sRGB,
          red:   max(0, min(1, (r + amt) / 255)),
          green: max(0, min(1, (g + amt) / 255)),
          blue:  max(0, min(1, (b + amt) / 255)))
}

/// Maps a grid cell to its 16-bit shaded color.
/// Body and face cells receive sphere shading (top-right light) with checkerboard dithering.
/// Outline cells get a dark tinted version of the body color instead of solid body color.
func colorForCell(_ cell: PetCell, gx: Int, gy: Int, dna: PetDNA) -> Color? {
    let palette = dna.palette

    switch cell {
    case .empty, .eyeWhite:
        return nil

    case .outline:
        let (r, g, b) = rgb(palette.body)
        return tone(r, g, b, -70)   // darkened outline

    case .body, .accent1, .accent2:
        let hexColor: String
        switch cell {
        case .accent1: hexColor = palette.accent1
        case .accent2: hexColor = palette.accent2
        default:       hexColor = palette.body
        }
        let (r, g, b) = rgb(hexColor)
        // Sphere shading: light source top-right
        let dx = (Double(gx) - dna.bodyCx) / max(1, dna.bodyRx)
        let dy = (Double(gy) - dna.bodyCy) / max(1, dna.bodyRy)
        let light = dx - dy          // high = bright (top-right)
        let ck = (gx + gy) % 2
        let T0 = tone(r, g, b,  90)
        let T1 = tone(r, g, b,  42)
        let T2 = tone(r, g, b,   0)
        let T3 = tone(r, g, b, -55)
        if      light >  0.65 { return T0 }
        else if light >  0.50 { return ck == 0 ? T0 : T1 }
        else if light >  0.25 { return T1 }
        else if light >  0.10 { return ck == 0 ? T1 : T2 }
        else if light > -0.15 { return T2 }
        else if light > -0.30 { return ck == 0 ? T2 : T3 }
        else                  { return T3 }

    case .face:
        let (r, g, b) = rgb(palette.face)
        let dx = (Double(gx) - dna.bodyCx) / max(1, dna.bodyRx)
        let dy = (Double(gy) - dna.bodyCy) / max(1, dna.bodyRy)
        let light = dx - dy
        let ck = (gx + gy) % 2
        let F0 = tone(r, g, b, -15)
        let F1 = tone(r, g, b, -40)
        let F2 = tone(r, g, b, -60)
        if      light >  0.25 { return ck == 0 ? F0 : F1 }
        else if light > -0.10 { return F1 }
        else                  { return ck == 0 ? F1 : F2 }

    case .eyePupil:  return Color(hex: palette.eyeP)
    case .eyeShine:  return Color(.sRGB, red: 0.88, green: 0.93, blue: 1.0)
    case .mouth:     return Color(hex: palette.eyeP)
    case .cheek:     return Color(hex: palette.cheek)
    case .shade:     return Color(hex: palette.shade)
    case .nose:      return Color(hex: palette.eyeP)
    case .tear:      return Color(hex: "#5599ff")
    case .gold:      return Color(hex: "#ffcc00")
    case .speedLine: return Color(hex: "#ff7700")
    case .gray:      return Color(hex: "#888888")
    case .lightning: return Color(hex: "#00cfff")
    }
}

// MARK: - Accessories

enum PetAccessory: String, CaseIterable {
    case medal66
}

/// Pixel-art accessory definitions. Each has multiple frames for animation.
private struct AccessorySprite {
    let frames: [[[(r: UInt8, g: UInt8, b: UInt8)?]]]  // [frame][row][col]
    let offsetX: Int
    let offsetY: Int
    var frameCount: Int { frames.count }
}

private let medal66Sprite: AccessorySprite = {
    let B: (UInt8, UInt8, UInt8)? = (0x1B, 0x50, 0xE5) // vivid cobalt blue ribbon
    let S: (UInt8, UInt8, UInt8)? = (0x0E, 0x36, 0xA8) // ribbon shadow
    let G: (UInt8, UInt8, UInt8)? = (0xFF, 0xCC, 0x00) // gold
    let D: (UInt8, UInt8, UInt8)? = (0xDA, 0xA5, 0x00) // gold dark
    let W: (UInt8, UInt8, UInt8)? = (0xFF, 0xE5, 0x66) // gold highlight
    let H: (UInt8, UInt8, UInt8)? = (0xFF, 0xFF, 0xFF) // white sparkle
    let n: (UInt8, UInt8, UInt8)? = nil

    // 4 frames: sparkle moves across the medal
    return AccessorySprite(
        frames: [
            // Frame 0: sparkle top-left
            [
                [B, n, B],
                [n, S, n],
                [H, W, G],
                [G, D, G],
            ],
            // Frame 1: no sparkle
            [
                [B, n, B],
                [n, S, n],
                [G, W, G],
                [G, D, G],
            ],
            // Frame 2: sparkle bottom-right
            [
                [B, n, B],
                [n, S, n],
                [G, W, G],
                [G, D, H],
            ],
            // Frame 3: no sparkle
            [
                [B, n, B],
                [n, S, n],
                [G, W, G],
                [G, D, G],
            ],
        ],
        offsetX: -2,
        offsetY: 3
    )
}()

private func spriteFor(_ accessory: PetAccessory) -> AccessorySprite {
    switch accessory {
    case .medal66: return medal66Sprite
    }
}

/// Returns accessory pixel data for external renderers (e.g. widget PNG).
/// Each entry: (gridX, gridY, r, g, b) for frame 0.
func accessoryPixels(for accessories: [PetAccessory], bodyCx: Int, bodyCy: Int) -> [(x: Int, y: Int, r: UInt8, g: UInt8, b: UInt8)] {
    var result: [(x: Int, y: Int, r: UInt8, g: UInt8, b: UInt8)] = []
    for acc in accessories {
        let sprite = spriteFor(acc)
        let pixels = sprite.frames[0]
        for (row, line) in pixels.enumerated() {
            for (col, pixel) in line.enumerated() {
                guard let p = pixel else { continue }
                let gx = bodyCx + sprite.offsetX + col
                let gy = bodyCy + sprite.offsetY + row
                guard gx >= 0, gx < GRID_SIZE, gy >= 0, gy < GRID_SIZE else { continue }
                result.append((gx, gy, p.r, p.g, p.b))
            }
        }
    }
    return result
}

// MARK: - Single-frame canvas
struct PetSpriteView: View {
    let grid: PetGrid
    let dna: PetDNA
    let pixelSize: CGFloat
    var accessories: [PetAccessory] = []
    var accessoryFrame: Int = 0

    var body: some View {
        Canvas { ctx, _ in
            let hideGold = !accessories.isEmpty
            // Draw pet
            for y in 0..<GRID_SIZE {
                for x in 0..<GRID_SIZE {
                    let cell = grid[y][x]
                    if hideGold && cell == .gold { continue }
                    guard let color = colorForCell(cell, gx: x, gy: y, dna: dna) else { continue }
                    let rect = CGRect(x: CGFloat(x) * pixelSize,
                                     y: CGFloat(y) * pixelSize,
                                     width: pixelSize, height: pixelSize)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
            // Draw accessories on top
            let cx = Int(dna.bodyCx)
            let cy = Int(dna.bodyCy)
            for acc in accessories {
                let sprite = spriteFor(acc)
                let f = accessoryFrame % sprite.frameCount
                let pixels = sprite.frames[f]
                for (row, line) in pixels.enumerated() {
                    for (col, pixel) in line.enumerated() {
                        guard let p = pixel else { continue }
                        let gx = cx + sprite.offsetX + col
                        let gy = cy + sprite.offsetY + row
                        guard gx >= 0, gx < GRID_SIZE, gy >= 0, gy < GRID_SIZE else { continue }
                        let rect = CGRect(x: CGFloat(gx) * pixelSize,
                                         y: CGFloat(gy) * pixelSize,
                                         width: pixelSize, height: pixelSize)
                        ctx.fill(Path(rect), with: .color(Color(
                            .sRGB,
                            red: Double(p.r) / 255,
                            green: Double(p.g) / 255,
                            blue: Double(p.b) / 255
                        )))
                    }
                }
            }
        }
        .frame(width: CGFloat(GRID_SIZE) * pixelSize,
               height: CGFloat(GRID_SIZE) * pixelSize)
    }
}

// MARK: - Animated canvas (cycles frames at pose-dependent fps)
struct PetAnimationView: View {
    let dna: PetDNA
    let pose: PetPose
    let pixelSize: CGFloat
    var fps: Double = 6
    var accessories: [PetAccessory] = []

    @State private var frame: Int = 0
    @State private var accessoryFrame: Int = 0
    @State private var grids: [PetGrid]

    // Idle uses 8 frames (frame 6 = parpadeo) a 3 fps → ciclo ~2.67s
    // Resto usa 4 frames al fps solicitado
    private static func frameCount(for pose: PetPose) -> Int { pose == .idle ? 8 : 4 }
    private func interval() -> Double { pose == .idle ? 1.0 / 3.0 : 1.0 / fps }

    init(dna: PetDNA, pose: PetPose = .idle, pixelSize: CGFloat, fps: Double = 6, accessories: [PetAccessory] = []) {
        self.dna = dna
        self.pose = pose
        self.pixelSize = pixelSize
        self.fps = fps
        self.accessories = accessories
        let count = Self.frameCount(for: pose)
        self._grids = State(initialValue: (0..<count).map {
            buildCharacterGrid(dna: dna, pose: pose, frame: $0)
        })
    }

    var body: some View {
        PetSpriteView(grid: grids[min(frame, grids.count - 1)], dna: dna, pixelSize: pixelSize,
                       accessories: accessories, accessoryFrame: accessoryFrame)
            .task(id: pose) {
                let count = Self.frameCount(for: pose)
                frame = 0
                grids = (0..<count).map { buildCharacterGrid(dna: dna, pose: pose, frame: $0) }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(interval()))
                    frame = (frame + 1) % count
                }
            }
            .task {
                // Accessory sparkle animation — slower than pet animation
                guard !accessories.isEmpty else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(0.4))
                    accessoryFrame += 1
                }
            }
    }
}

// MARK: - Preview card (carousel)
struct PetPreviewCard: View {
    let dna: PetDNA
    var isSelected: Bool = false
    let size: CGFloat

    private var pixelSize: CGFloat { size / CGFloat(GRID_SIZE) }
    private var bodyColor: Color { Color(hex: dna.palette.body) }
    // Feet are around row 20 of 24; offset from canvas bottom = (24-20)/24 * size
    private var footOffset: CGFloat { size * 4.0 / 24.0 }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                // Foot glow — only when selected
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [bodyColor.opacity(isSelected ? 0.55 : 0), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.35
                        )
                    )
                    .frame(width: size * 0.75, height: size * 0.22)
                    .blur(radius: 6)
                    .padding(.bottom, footOffset - 4)
                    .animation(.spring(duration: 0.3), value: isSelected)

                PetAnimationView(dna: dna, pose: isSelected ? .running : .idle, pixelSize: pixelSize)
            }
            .frame(width: size + 24, height: size + 24)

            Text(dna.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(isSelected ? bodyColor : Color(hex: "#616E7C"))
        }
    }
}

// MARK: - Hex color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a,r,g,b) = (255,(int>>8)*17,(int>>4 & 0xF)*17,(int & 0xF)*17)
        case 6:  (a,r,g,b) = (255,int>>16,int>>8 & 0xFF,int & 0xFF)
        case 8:  (a,r,g,b) = (int>>24,int>>16 & 0xFF,int>>8 & 0xFF,int & 0xFF)
        default: (a,r,g,b) = (255,0,0,0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Shared app background
/// Pass `imageName` to overlay a photo background; nil (default) uses the standard gradient.
struct AppBackground: View {
    var imageName: String? = nil

    var body: some View {
        ZStack {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                LinearGradient(
                    colors: [.black.opacity(0.08), .black.opacity(0.50)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                Color(hex: "#F5F8FC")
                RadialGradient(
                    colors: [Color(hex: "#F9703E").opacity(0.07), .clear],
                    center: .init(x: 0.5, y: -0.05),
                    startRadius: 0,
                    endRadius: 420
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}
