import SwiftUI

// MARK: - Color mapping
func colorForCell(_ cell: PetCell, palette: PetPalette) -> Color? {
    switch cell {
    case .empty:     return nil
    case .body:      return Color(hex: palette.body)
    case .outline:   return Color(hex: palette.body)
    case .eyeWhite:  return nil  // transparent, like EW in JS
    case .eyePupil:  return Color(hex: palette.eyeP)
    case .eyeShine:  return .white
    case .mouth:     return Color(hex: palette.eyeP)
    case .cheek:     return Color(hex: palette.cheek)
    case .shade:     return Color(hex: palette.shade)
    case .nose:      return Color(hex: palette.eyeP)
    case .face:      return Color(hex: palette.face)
    case .tear:      return Color(hex: "#5599ff")
    case .gold:      return Color(hex: "#ffcc00")
    case .speedLine: return Color(hex: "#ff7700")
    case .gray:      return Color(hex: "#888888")
    case .accent1:   return Color(hex: palette.accent1)
    case .accent2:   return Color(hex: palette.accent2)
    }
}

// MARK: - Single-frame canvas
struct PetSpriteView: View {
    let grid: PetGrid
    let palette: PetPalette
    let pixelSize: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            for y in 0..<GRID_SIZE {
                for x in 0..<GRID_SIZE {
                    guard let color = colorForCell(grid[y][x], palette: palette) else { continue }
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

// MARK: - Animated canvas (cycles through 4 frames)
struct PetAnimationView: View {
    let dna: PetDNA
    let pose: PetPose
    let pixelSize: CGFloat
    var fps: Double = 6

    @State private var frame: Int = 0
    @State private var grids: [PetGrid]

    // Grids computed eagerly in init so the view renders immediately
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
        PetSpriteView(grid: grids[frame], palette: dna.palette, pixelSize: pixelSize)
            // SwiftUI-idiomatic timer — no manual Timer management needed
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

// MARK: - Small preview card (used in character select)
struct PetPreviewCard: View {
    let dna: PetDNA
    var isSelected: Bool = false
    let size: CGFloat

    private var pixelSize: CGFloat { size / CGFloat(GRID_SIZE) }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#F0F4F8"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                isSelected ? Color(hex: "#F9703E") : Color.clear,
                                lineWidth: 3
                            )
                    )
                    .shadow(color: isSelected ? Color(hex: "#F9703E").opacity(0.3) : .black.opacity(0.06),
                            radius: isSelected ? 12 : 6, y: 4)

                PetAnimationView(dna: dna, pose: .idle, pixelSize: pixelSize)
            }
            .frame(width: size + 24, height: size + 24)

            Text(dna.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: isSelected ? "#F9703E" : "#616E7C"))

            Text(dna.animalType.rawValue.capitalized)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
        }
    }
}

// MARK: - Color from hex (shared extension)
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
