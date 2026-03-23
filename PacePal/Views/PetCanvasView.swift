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
        let F0 = tone(r, g, b,  28)
        let F1 = tone(r, g, b,   0)
        let F2 = tone(r, g, b, -22)
        if      light >  0.25 { return ck == 0 ? F0 : F1 }
        else if light > -0.10 { return F1 }
        else                  { return ck == 0 ? F1 : F2 }

    case .eyePupil:  return Color(hex: palette.eyeP)
    case .eyeShine:  return .white
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

// MARK: - Single-frame canvas
struct PetSpriteView: View {
    let grid: PetGrid
    let dna: PetDNA
    let pixelSize: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            for y in 0..<GRID_SIZE {
                for x in 0..<GRID_SIZE {
                    guard let color = colorForCell(grid[y][x], gx: x, gy: y, dna: dna) else { continue }
                    let rect = CGRect(x: CGFloat(x) * pixelSize,
                                     y: CGFloat(y) * pixelSize,
                                     width: pixelSize, height: pixelSize)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(GRID_SIZE) * pixelSize,
               height: CGFloat(GRID_SIZE) * pixelSize)
    }
}

// MARK: - Animated canvas (cycles 4 frames at fps)
struct PetAnimationView: View {
    let dna: PetDNA
    let pose: PetPose
    let pixelSize: CGFloat
    var fps: Double = 6

    @State private var frame: Int = 0
    @State private var grids: [PetGrid]

    init(dna: PetDNA, pose: PetPose = .idle, pixelSize: CGFloat, fps: Double = 6) {
        self.dna = dna
        self.pose = pose
        self.pixelSize = pixelSize
        self.fps = fps
        self._grids = State(initialValue: (0..<4).map {
            buildCharacterGrid(dna: dna, pose: pose, frame: $0)
        })
    }

    var body: some View {
        PetSpriteView(grid: grids[frame], dna: dna, pixelSize: pixelSize)
            .onReceive(
                Timer.publish(every: 1.0 / fps, on: .main, in: .common).autoconnect()
            ) { _ in
                frame = (frame + 1) % 4
            }
            .onChange(of: pose) { _, newPose in
                frame = 0
                grids = (0..<4).map { buildCharacterGrid(dna: dna, pose: newPose, frame: $0) }
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
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#F0F4F8"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? bodyColor : Color.clear,
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: isSelected ? bodyColor.opacity(0.35) : .black.opacity(0.06),
                            radius: isSelected ? 14 : 6, y: 4)

                ZStack(alignment: .bottom) {
                    // Foot glow for selected card
                    if isSelected {
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [bodyColor.opacity(0.55), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: size * 0.35
                                )
                            )
                            .frame(width: size * 0.75, height: size * 0.22)
                            .blur(radius: 6)
                            .padding(.bottom, footOffset - 4)
                    }

                    PetAnimationView(dna: dna, pose: .idle, pixelSize: pixelSize)
                }
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
