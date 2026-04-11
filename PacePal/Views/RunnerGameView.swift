import SwiftUI

// MARK: - Game types

private enum GamePhase { case ready, playing, dead }

private struct GameObstacle: Identifiable {
    let id = UUID()
    var x: Double
    let kind: ObstacleKind
    var animFrame: Int = 0
    var animTimer: Double = 0

    var sprite: ObstacleSprite { obstacleSprite(for: kind) }
}

// MARK: - Constants

private let petPixelSize: Double = 3.0          // pt per pet pixel → 72×72pt sprite
private let groundFraction: Double = 0.62       // ground Y as fraction of screen height
private let petX: Double = 90                   // pet horizontal center
private let jumpVelocity: Double = 560          // pt/s upward
private let gravity: Double = 1600              // pt/s² downward
private let fastFallGravity: Double = 4800      // pt/s² when ducking mid-air
private let startSpeed: Double = 220            // pt/s initial obstacle speed
private let maxSpeed: Double  = 700
private let bestScoreKey = "runnerBestScore"
private let groundTileW: Double = 32            // scrolling ground dash width
private let birdAnimInterval: Double = 0.18

// MARK: - RunnerGameView

struct RunnerGameView: View {
    let dna: PetDNA
    var onExit: () -> Void

    // Game state
    @State private var phase: GamePhase = .ready
    @State private var petAlt: Double = 0         // pt above ground (0 = on ground)
    @State private var petVel: Double = 0         // vertical velocity (+ = up)
    @State private var isDucking = false
    @State private var obstacles: [GameObstacle] = []
    @State private var score: Int = 0
    @State private var bestScore: Int = UserDefaults.standard.integer(forKey: bestScoreKey)
    @State private var speed: Double = startSpeed
    @State private var lastDate: Date? = nil
    @State private var groundScroll: Double = 0
    @State private var flashRed = false
    @State private var newBest = false

    // Pet animation
    @State private var petPose: PetPose = .running

    var body: some View {
        GeometryReader { geo in
            let gY = geo.size.height * groundFraction
            let petH = Double(GRID_SIZE) * petPixelSize

            ZStack {
                // Background
                Color(hex: "#F9F496").ignoresSafeArea()

                // Ground + obstacles (Canvas)
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: phase != .playing)) { tl in
                    Canvas { ctx, size in
                        drawGround(ctx: ctx, size: size, groundY: gY)
                        drawObstacles(ctx: ctx, groundY: gY)
                    }
                    .onChange(of: tl.date) { _, date in
                        tick(date: date, size: geo.size, groundY: gY)
                    }
                }
                .ignoresSafeArea()

                // Pet sprite
                PetAnimationView(dna: dna, pose: petPose,
                                 pixelSize: CGFloat(petPixelSize), fps: 8)
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: CGFloat(Double(GRID_SIZE) * petPixelSize),
                           height: CGFloat(petH))
                    .position(x: petX,
                              y: gY - petAlt - petH / 2)
                    .animation(nil, value: petAlt)

                // Score
                scoreOverlay

                // Red flash on death
                if flashRed {
                    Color.red.opacity(0.18).ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                // Ready overlay
                if phase == .ready { readyOverlay }

                // Dead overlay
                if phase == .dead { deadOverlay }
            }
        }
        .ignoresSafeArea()
        .gesture(
            DragGesture(minimumDistance: 8)
                .onChanged { value in
                    if phase == .ready { startGame(); return }
                    guard phase == .playing else { return }
                    if value.translation.height < -10 {
                        jump()
                    } else if value.translation.height > 10 {
                        isDucking = true
                    }
                }
                .onEnded { _ in isDucking = false }
        )
        .onTapGesture {
            if phase == .ready { startGame() }
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
                    .foregroundStyle(Color(hex: "#F9703E"))
                Text("Tap o desliza para empezar")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#486581"))
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
                Button {
                    resetGame()
                } label: {
                    Label("Reintentar", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 14)
                        .background(Color(hex: "#F9703E"))
                        .clipShape(Capsule())
                }
                Button {
                    onExit()
                } label: {
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

    // MARK: - Canvas rendering

    private func drawGround(ctx: GraphicsContext, size: CGSize, groundY: Double) {
        // Solid ground line
        ctx.fill(Path(CGRect(x: 0, y: groundY, width: size.width, height: 2.5)),
                 with: .color(Color(hex: "#486581")))
        // Scrolling pixel dashes
        let step: Double = 52
        var x = (groundScroll.truncatingRemainder(dividingBy: step)) - step
        while x < size.width {
            ctx.fill(Path(CGRect(x: x, y: groundY + 5, width: 18, height: 2.5)),
                     with: .color(Color(hex: "#9AA5B4").opacity(0.45)))
            x += step
        }
        // Second row of dashes offset
        var x2 = (groundScroll.truncatingRemainder(dividingBy: step * 1.5)) - step
        while x2 < size.width {
            ctx.fill(Path(CGRect(x: x2, y: groundY + 10, width: 8, height: 2)),
                     with: .color(Color(hex: "#9AA5B4").opacity(0.25)))
            x2 += step * 1.5
        }
    }

    private func drawObstacles(ctx: GraphicsContext, groundY: Double) {
        for obs in obstacles {
            let spr = obs.sprite
            let frame = spr.frames[obs.animFrame % spr.frameCount]
            let px = spr.pixelSize
            let obsBottomY = groundY - spr.groundOffset
            for (row, pixels) in frame.enumerated() {
                let py = obsBottomY - Double(frame.count - row) * px
                for (col, pixel) in pixels.enumerated() {
                    guard let color = pixel else { continue }
                    let rect = CGRect(x: obs.x + Double(col) * px,
                                     y: py, width: px, height: px)
                    ctx.fill(Path(rect), with: .color(color))
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

        // Score & speed
        score += max(1, Int(speed * dt / 8))
        speed = min(maxSpeed, startSpeed + Double(score / 400) * 28)

        // Physics — fast-fall when ducking in the air
        let activeGravity = (isDucking && petAlt > 0) ? fastFallGravity : gravity
        petVel -= activeGravity * dt
        petAlt = max(0, petAlt + petVel * dt)
        if petAlt <= 0 { petVel = 0 }

        // Ground scroll
        groundScroll += speed * dt

        // Pet pose
        let newPose: PetPose
        if isDucking && petAlt <= 0 {
            newPose = .tired
        } else if petAlt > 2 {
            newPose = .jump
        } else {
            newPose = .running
        }
        if newPose != petPose { petPose = newPose }

        // Move & animate obstacles
        for i in obstacles.indices {
            obstacles[i].x -= speed * dt
            if obstacles[i].kind == .bird {
                obstacles[i].animTimer += dt
                if obstacles[i].animTimer >= birdAnimInterval {
                    obstacles[i].animTimer = 0
                    obstacles[i].animFrame ^= 1
                }
            }
        }
        obstacles.removeAll { $0.x + $0.sprite.width < -10 }

        // Spawn
        let minGap = max(size.width * 0.38, size.width * 0.8 - speed * 0.18)
        if obstacles.isEmpty || (obstacles.last.map { $0.x < size.width - minGap } ?? false) {
            let roll = Double.random(in: 0...1)
            if roll < 0.55 || obstacles.isEmpty {
                spawnObstacle(score: score, screenWidth: size.width)
            }
        }

        // Collision
        if checkCollision(groundY: groundY) {
            endGame()
        }
    }

    private func checkCollision(groundY: Double) -> Bool {
        // Pet hitbox — tighter than sprite
        let hitW: Double = 22
        let hitH: Double = isDucking ? 28 : 52
        let petLeft  = petX - hitW / 2
        let petRight = petX + hitW / 2
        let petBottomY = groundY - petAlt         // screen Y (larger = lower)
        let petTopY    = petBottomY - hitH

        for obs in obstacles {
            let spr = obs.sprite
            let obsLeft   = obs.x + spr.width  * 0.1
            let obsRight  = obs.x + spr.width  * 0.9
            let obsBottomY = groundY - spr.groundOffset
            let obsTopY    = obsBottomY - spr.height * 0.9

            let horizOverlap = petRight > obsLeft  && petLeft  < obsRight
            let vertOverlap  = petBottomY > obsTopY && petTopY < obsBottomY

            if horizOverlap && vertOverlap { return true }
        }
        return false
    }

    // MARK: - Game control

    private func startGame() {
        score = 0
        speed = startSpeed
        petAlt = 0
        petVel = 0
        isDucking = false
        obstacles = []
        groundScroll = 0
        lastDate = nil
        newBest = false
        phase = .playing
    }

    private func resetGame() {
        startGame()
    }

    private func endGame() {
        phase = .dead
        petPose = .dead
        if score > bestScore {
            bestScore = score
            newBest = true
            UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
        }
        withAnimation(.easeIn(duration: 0.1)) { flashRed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation { flashRed = false }
        }
    }

    private func jump() {
        guard phase == .playing, petAlt <= 2 else { return }
        petVel = jumpVelocity
        isDucking = false
    }

    private func spawnObstacle(score: Int, screenWidth: Double) {
        let kind = ObstacleKind.random(score: score)
        obstacles.append(GameObstacle(x: screenWidth + 10, kind: kind))
    }

    // MARK: - Helpers

    private func scoreString(_ n: Int) -> String {
        String(format: "%05d", n)
    }
}
