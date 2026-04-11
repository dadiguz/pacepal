import SwiftUI

// MARK: - Game types

private enum RainPhase { case ready, playing, dead }

private struct RainDrop: Identifiable {
    let id = UUID()
    var x: Double       // left edge, screen coords
    var y: Double       // top edge, screen coords (0 = top)
    let kind: RainKind
    let speed: Double   // pt/s downward
    let scale: Double   // sprite size multiplier (small=0.6, mid=1.0, big=1.5)
}

// MARK: - Constants

private let rainPetPixelSize: Double  = 3.0
private let rainGroundFraction: Double = 0.78
private let rainStartSpeed: Double    = 200
private let rainMaxSpeed: Double      = 580
private let rainStartInterval: Double = 1.3
private let rainMinInterval: Double   = 0.26
private let rainBestScoreKey          = "dodgeRainBestScore"

// MARK: - DodgeRainView

struct DodgeRainView: View {
    let dna: PetDNA
    var onExit: () -> Void

    @State private var phase: RainPhase = .ready
    @State private var petX: Double = 200
    @State private var targetX: Double = 200
    @State private var screenW: Double = 375
    @State private var drops: [RainDrop] = []
    @State private var score: Int = 0
    @State private var bestScore: Int = UserDefaults.standard.integer(forKey: rainBestScoreKey)
    @State private var fallSpeed: Double = rainStartSpeed
    @State private var spawnCountdown: Double = 0.6
    @State private var lastDate: Date? = nil
    @State private var groundScroll: Double = 0
    @State private var flashRed = false
    @State private var newBest = false
    @State private var petPose: PetPose = .idle
    @State private var facingRight = false
    @State private var dragStartPetX: Double = 200

    var body: some View {
        GeometryReader { geo in
            let gY = geo.size.height * rainGroundFraction
            let petH = Double(GRID_SIZE) * rainPetPixelSize

            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [Color(hex: "#B8D9F5"), Color(hex: "#DCF0FF")],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()

                // Game canvas
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: phase != .playing)) { tl in
                    Canvas { ctx, size in
                        drawGround(ctx: ctx, size: size, groundY: gY)
                        drawDrops(ctx: ctx)
                    }
                    .onChange(of: tl.date) { _, date in
                        tick(date: date, size: geo.size, groundY: gY)
                    }
                }
                .ignoresSafeArea()

                // Pet
                PetAnimationView(dna: dna, pose: petPose,
                                 pixelSize: CGFloat(rainPetPixelSize), fps: 8)
                    .scaleEffect(x: facingRight ? -1 : 1, y: 1)
                    .frame(width: CGFloat(Double(GRID_SIZE) * rainPetPixelSize),
                           height: CGFloat(petH))
                    .position(x: petX, y: gY - petH / 2)
                    .animation(nil, value: petX)

                scoreOverlay

                if flashRed {
                    Color.red.opacity(0.18).ignoresSafeArea().allowsHitTesting(false)
                }
                if phase == .ready { readyOverlay }
                if phase == .dead  { deadOverlay  }
            }
            .onAppear {
                screenW  = geo.size.width
                petX     = geo.size.width / 2
                targetX  = geo.size.width / 2
            }
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { val in
                        if phase == .ready { startGame() }
                        guard phase == .playing else { return }
                        targetX = dragStartPetX + val.translation.width
                    }
                    .onEnded { _ in
                        dragStartPetX = petX
                    }
            )
            .onTapGesture {
                if phase == .ready { startGame() }
            }
        }
        .ignoresSafeArea()
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
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: "#2E86C1"))
                Text("Desliza para esquivar")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#2E86C1"))
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
                        .background(Color(hex: "#2E86C1"))
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

    private func drawGround(ctx: GraphicsContext, size: CGSize, groundY: Double) {
        ctx.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 2.5)),
                 with: .color(Color(hex: "#2E86C1").opacity(0.5)))
        let step: Double = 52
        var x = (groundScroll.truncatingRemainder(dividingBy: step)) - step
        while x < size.width {
            ctx.fill(Path(CGRect(x: x, y: groundY + 5, width: 18, height: 2.5)),
                     with: .color(Color(hex: "#85C1E9").opacity(0.45)))
            x += step
        }
    }

    private func drawDrops(ctx: GraphicsContext) {
        for drop in drops {
            let spr = rainSprite(for: drop.kind)
            let px  = spr.pixelSize * drop.scale
            for (row, pixels) in spr.frame.enumerated() {
                let py = drop.y + Double(row) * px
                for (col, pixel) in pixels.enumerated() {
                    guard let color = pixel else { continue }
                    ctx.fill(Path(CGRect(x: drop.x + Double(col) * px,
                                        y: py,
                                        width: px, height: px)),
                             with: .color(color))
                }
            }
        }
    }

    // MARK: - Game loop

    private func tick(date: Date, size: CGSize, groundY: Double) {
        guard phase == .playing else { lastDate = nil; return }
        guard let last = lastDate else { lastDate = date; return }
        let dt = min(date.timeIntervalSince(last), 1.0 / 20.0)
        lastDate = date

        // Score & speed ramp
        score += max(1, Int(fallSpeed * dt / 10))
        fallSpeed = min(rainMaxSpeed, rainStartSpeed + Double(score / 300) * 18)

        // Pet follows swipe, clamped to screen
        let halfW = Double(GRID_SIZE) * rainPetPixelSize / 2
        let prevX = petX
        petX = max(halfW, min(size.width - halfW, targetX))

        // Facing direction (deadzone ±4 to avoid flicker when still)
        let dx = petX - prevX
        if dx > 4  { facingRight = true  }
        if dx < -4 { facingRight = false }

        // Pose: running when moving, idle when still
        let moving = abs(dx) > 2
        let newPose: PetPose = moving ? .running : .idle
        if newPose != petPose { petPose = newPose }

        // Ground scroll (visual only)
        groundScroll += fallSpeed * dt

        // Move drops downward
        for i in drops.indices {
            drops[i].y += drops[i].speed * dt
        }
        drops.removeAll { $0.y > groundY + 30 }

        // Spawn
        spawnCountdown -= dt
        if spawnCountdown <= 0 {
            let interval = max(rainMinInterval,
                               rainStartInterval - Double(score) / 2800.0)
            spawnCountdown = interval + Double.random(in: -0.08...0.08)
            spawnDrop(screenWidth: size.width)
            // Second simultaneous drop at high scores
            if score > 1200, Bool.random() {
                spawnDrop(screenWidth: size.width)
            }
        }

        // Collision
        if checkCollision(groundY: groundY) { endGame() }
    }

    private func checkCollision(groundY: Double) -> Bool {
        let petH   = Double(GRID_SIZE) * rainPetPixelSize
        let hitW: Double = 20
        let petLeft   = petX - hitW / 2
        let petRight  = petX + hitW / 2
        let petTopY   = groundY - petH * 0.85
        let petBotY   = groundY

        for drop in drops {
            let spr    = rainSprite(for: drop.kind)
            let w      = spr.width  * drop.scale
            let h      = spr.height * drop.scale
            let dLeft  = drop.x + w * 0.12
            let dRight = drop.x + w * 0.88
            let dTopY  = drop.y
            let dBotY  = drop.y + h * 0.9

            if petRight > dLeft && petLeft < dRight &&
               petBotY  > dTopY && petTopY < dBotY {
                return true
            }
        }
        return false
    }

    // MARK: - Control

    private func startGame() {
        petX          = screenW / 2
        targetX       = screenW / 2
        dragStartPetX = screenW / 2
        drops         = []
        score         = 0
        fallSpeed     = rainStartSpeed
        spawnCountdown = 0.6
        lastDate      = nil
        newBest       = false
        petPose       = .running
        phase         = .playing
    }

    private func endGame() {
        phase   = .dead
        petPose = .dead
        if score > bestScore {
            bestScore = score
            newBest   = true
            UserDefaults.standard.set(bestScore, forKey: rainBestScoreKey)
        }
        withAnimation(.easeIn(duration: 0.1)) { flashRed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { flashRed = false }
        }
    }

    private func spawnDrop(screenWidth: Double) {
        let kind  = RainKind.random(score: score)
        let spr   = rainSprite(for: kind)
        // Weighted random size: 35% small, 40% medium, 25% large
        let scale: Double = {
            let r = Double.random(in: 0...1)
            if r < 0.35 { return Double.random(in: 0.55...0.75) }
            if r < 0.75 { return Double.random(in: 0.90...1.10) }
            return Double.random(in: 1.35...1.65)
        }()
        let w    = spr.width * scale
        let h    = spr.height * scale
        let maxX = max(20, screenWidth - w - 20)
        let x    = Double.random(in: 20...maxX)
        // Larger objects fall a bit slower, smaller ones faster — feels physical
        let speedMult = max(0.75, min(1.4, 1.0 / scale))
        drops.append(RainDrop(
            x: x, y: -h - 4, kind: kind,
            speed: fallSpeed * Double.random(in: 0.85...1.15) * speedMult,
            scale: scale
        ))
    }

    private func scoreString(_ n: Int) -> String { String(format: "%05d", n) }
}
