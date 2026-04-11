import SwiftUI

// MARK: - Types

private enum FlipPhase { case ready, playing, dead }

private struct FlipPillar: Identifiable {
    let id = UUID()
    var x: Double
    let fromFloor: Bool      // true = pillar rises from floor, pet must be on ceiling
    let heightFrac: Double   // fraction of corridor height (0.35–0.60)
}

// MARK: - Constants

private let flipPetPixelSize: Double = 3.0
private let flipPetX: Double         = 90
private let flipStartSpeed: Double   = 230
private let flipMaxSpeed: Double     = 660
private let flipPillarW: Double      = 46
private let flipSpikeH: Double       = 16
private let flipStartInterval: Double = 2.0
private let flipMinInterval: Double   = 0.65
private let flipBestScoreKey          = "gravityFlipBestScore"

// MARK: - GravityFlipView

struct GravityFlipView: View {
    let dna: PetDNA
    var onExit: () -> Void

    @State private var phase: FlipPhase = .ready
    @State private var onFloor = true
    @State private var petY: Double = 0
    @State private var petFlipped = false
    @State private var screenH: Double = 0
    @State private var pillars: [FlipPillar] = []
    @State private var score: Int = 0
    @State private var bestScore = UserDefaults.standard.integer(forKey: flipBestScoreKey)
    @State private var speed = flipStartSpeed
    @State private var spawnCountdown = 1.0
    @State private var lastDate: Date? = nil
    @State private var groundScroll: Double = 0
    @State private var flashRed = false
    @State private var newBest = false
    @State private var petPose: PetPose = .running

    private var floorY:  Double { screenH * 0.82 }
    private var ceilY:   Double { screenH * 0.18 }
    private var petH:    Double { Double(GRID_SIZE) * flipPetPixelSize }
    private var corridor: Double { floorY - ceilY }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#F2EEE8").ignoresSafeArea()

                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: phase != .playing)) { tl in
                    Canvas { ctx, size in
                        drawSurfaces(ctx: ctx, size: size)
                        drawPillars(ctx: ctx)
                    }
                    .onChange(of: tl.date) { _, date in
                        tick(date: date, size: geo.size)
                    }
                }
                .ignoresSafeArea()

                PetAnimationView(dna: dna, pose: petPose,
                                 pixelSize: CGFloat(flipPetPixelSize), fps: 8)
                    .scaleEffect(x: -1, y: petFlipped ? -1 : 1)
                    .frame(width: CGFloat(Double(GRID_SIZE) * flipPetPixelSize),
                           height: CGFloat(petH))
                    .position(x: flipPetX, y: petY)

                scoreOverlay

                if flashRed {
                    Color.red.opacity(0.18).ignoresSafeArea().allowsHitTesting(false)
                }
                if phase == .ready { readyOverlay }
                if phase == .dead  { deadOverlay  }
            }
            .onAppear {
                screenH = geo.size.height
                petY    = geo.size.height * 0.82 - petH / 2
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            switch phase {
            case .ready:   startGame()
            case .playing: flip()
            case .dead:    break
            }
        }
    }

    // MARK: - Overlays

    private var scoreOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(scoreString(score))
                        .font(.system(size: 22, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    if bestScore > 0 {
                        Text("HI \(scoreString(bestScore))")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#9AA5B4"))
                    }
                }
                .padding(.trailing, 28)
                .padding(.top, 60)
            }
            Spacer()
        }
    }

    private var readyOverlay: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: "#8E44AD"))
                Text("Toca para cambiar gravedad")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#8E44AD"))
            }
            .padding(.bottom, 120)
        }
    }

    private var deadOverlay: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 6) {
                if newBest {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(Color(hex: "#F9703E"))
                        Text("¡Nuevo récord!")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#F9703E"))
                    }
                }
                Text(scoreString(score))
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundStyle(Color(hex: "#1F2933"))
            }
            HStack(spacing: 16) {
                Button { startGame() } label: {
                    Label("Reintentar", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(Color(hex: "#8E44AD"))
                        .clipShape(Capsule())
                }
                Button { onExit() } label: {
                    Label("Salir", systemImage: "xmark")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#486581"))
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(Color(hex: "#486581").opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            Spacer().frame(height: 80)
        }
    }

    // MARK: - Canvas

    private func drawSurfaces(ctx: GraphicsContext, size: CGSize) {
        let lineColor  = Color(hex: "#486581")
        let dashColor  = Color(hex: "#9AA5B4").opacity(0.4)
        let step: Double = 52
        let offset = (groundScroll.truncatingRemainder(dividingBy: step)) - step

        // Floor
        ctx.fill(Path(CGRect(x: 0, y: floorY, width: size.width, height: 2.5)),
                 with: .color(lineColor))
        // Ceiling
        ctx.fill(Path(CGRect(x: 0, y: ceilY - 2.5, width: size.width, height: 2.5)),
                 with: .color(lineColor))

        // Scrolling dashes on both surfaces
        var x = offset
        while x < size.width {
            ctx.fill(Path(CGRect(x: x, y: floorY + 5, width: 18, height: 2)), with: .color(dashColor))
            ctx.fill(Path(CGRect(x: x, y: ceilY - 8,  width: 18, height: 2)), with: .color(dashColor))
            x += step
        }
    }

    private func drawPillars(ctx: GraphicsContext) {
        let body  = Color(hex: "#37474F")
        let spike = Color(hex: "#78909C")

        for p in pillars {
            let h = corridor * p.heightFrac

            if p.fromFloor {
                // Body from floor upward
                let bodyY = floorY - h
                ctx.fill(Path(CGRect(x: p.x, y: bodyY, width: flipPillarW, height: h)),
                         with: .color(body))
                // Spikes at top edge (pointing up)
                drawSpikes(ctx: ctx, x: p.x, y: bodyY, w: flipPillarW,
                           pointUp: true, color: spike)
            } else {
                // Body from ceiling downward
                ctx.fill(Path(CGRect(x: p.x, y: ceilY, width: flipPillarW, height: h)),
                         with: .color(body))
                // Spikes at bottom edge (pointing down)
                drawSpikes(ctx: ctx, x: p.x, y: ceilY + h, w: flipPillarW,
                           pointUp: false, color: spike)
            }
        }
    }

    private func drawSpikes(ctx: GraphicsContext, x: Double, y: Double,
                            w: Double, pointUp: Bool, color: Color) {
        let sw: Double = 11   // spike tooth width
        var sx = x
        while sx < x + w {
            let tw = min(sw, x + w - sx)
            var path = Path()
            if pointUp {
                path.move(to:    CGPoint(x: sx,        y: y))
                path.addLine(to: CGPoint(x: sx + tw,   y: y))
                path.addLine(to: CGPoint(x: sx + tw/2, y: y - flipSpikeH))
            } else {
                path.move(to:    CGPoint(x: sx,        y: y))
                path.addLine(to: CGPoint(x: sx + tw,   y: y))
                path.addLine(to: CGPoint(x: sx + tw/2, y: y + flipSpikeH))
            }
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
            sx += sw
        }
    }

    // MARK: - Game loop

    private func tick(date: Date, size: CGSize) {
        guard phase == .playing else { lastDate = nil; return }
        guard let last = lastDate else { lastDate = date; return }
        let dt = min(date.timeIntervalSince(last), 1.0 / 20.0)
        lastDate = date

        // Score & speed
        score += max(1, Int(speed * dt / 8))
        speed = min(flipMaxSpeed, flipStartSpeed + Double(score / 400) * 28)

        // Scroll
        groundScroll += speed * dt

        // Move pillars
        for i in pillars.indices { pillars[i].x -= speed * dt }
        pillars.removeAll { $0.x + flipPillarW < -10 }

        // Spawn
        spawnCountdown -= dt
        if spawnCountdown <= 0 {
            let interval = max(flipMinInterval,
                               flipStartInterval - Double(score) / 3200.0)
            spawnCountdown = interval + Double.random(in: -0.12...0.12)
            spawnPillar(screenWidth: size.width)
        }

        // Collision
        if checkCollision() { endGame() }
    }

    private func checkCollision() -> Bool {
        let petLeft  = flipPetX - 18
        let petRight = flipPetX + 18

        for p in pillars {
            let pLeft  = p.x + flipPillarW * 0.08
            let pRight = p.x + flipPillarW * 0.92
            guard petRight > pLeft && petLeft < pRight else { continue }
            // Pillar is on the same surface as the pet → hit
            if p.fromFloor == onFloor { return true }
        }
        return false
    }

    // MARK: - Control

    private func startGame() {
        onFloor        = true
        petFlipped     = false
        petY           = floorY - petH / 2
        pillars        = []
        score          = 0
        speed          = flipStartSpeed
        spawnCountdown = 1.0
        lastDate       = nil
        newBest        = false
        petPose        = .running
        phase          = .playing
    }

    private func flip() {
        onFloor.toggle()
        petFlipped = !onFloor
        withAnimation(.easeInOut(duration: 0.13)) {
            petY = onFloor ? (floorY - petH / 2) : (ceilY + petH / 2)
        }
    }

    private func endGame() {
        phase   = .dead
        petPose = .dead
        if score > bestScore {
            bestScore = score
            newBest   = true
            UserDefaults.standard.set(bestScore, forKey: flipBestScoreKey)
        }
        withAnimation(.easeIn(duration: 0.1)) { flashRed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { flashRed = false }
        }
    }

    private func spawnPillar(screenWidth: Double) {
        let fromFloor = Bool.random()
        let frac = Double.random(in: 0.35...0.58)
        pillars.append(FlipPillar(x: screenWidth + 10,
                                   fromFloor: fromFloor,
                                   heightFrac: frac))

        // At higher scores, occasionally add a second pillar from the opposite side
        // close behind — forces a rapid flip
        if score > 600, Int.random(in: 0..<3) == 0 {
            let gap = Double.random(in: 55...90)
            pillars.append(FlipPillar(x: screenWidth + 10 + gap,
                                       fromFloor: !fromFloor,
                                       heightFrac: Double.random(in: 0.35...0.55)))
        }
    }

    private func scoreString(_ n: Int) -> String { String(format: "%05d", n) }
}
