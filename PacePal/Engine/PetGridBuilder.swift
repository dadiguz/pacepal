import Foundation

// MARK: - Grid helpers
func makeEmptyGrid() -> PetGrid {
    Array(repeating: Array(repeating: PetCell.empty, count: GRID_SIZE), count: GRID_SIZE)
}

func pset(_ grid: inout PetGrid, x: Int, y: Int, cell: PetCell) {
    guard x >= 0, x < GRID_SIZE, y >= 0, y < GRID_SIZE else { return }
    grid[y][x] = cell
}

// nil = out of bounds (not empty), .empty = in-bounds empty
func pget(_ grid: PetGrid, x: Int, y: Int) -> PetCell? {
    guard x >= 0, x < GRID_SIZE, y >= 0, y < GRID_SIZE else { return nil }
    return grid[y][x]
}

func fillEllipse(_ grid: inout PetGrid, cx: Double, cy: Double, rx: Double, ry: Double, cell: PetCell) {
    guard rx > 0, ry > 0 else { return }
    for y in Int(floor(cy - ry))...Int(ceil(cy + ry)) {
        for x in Int(floor(cx - rx))...Int(ceil(cx + rx)) {
            let dx = (Double(x) - cx) / rx
            let dy = (Double(y) - cy) / ry
            if dx * dx + dy * dy <= 1.0 { pset(&grid, x: x, y: y, cell: cell) }
        }
    }
}

func addOutline(_ grid: inout PetGrid) {
    let dirs = [(-1,0),(1,0),(0,-1),(0,1),(-1,-1),(1,-1),(-1,1),(1,1)]
    var edges: [(Int, Int)] = []
    for y in 0..<GRID_SIZE {
        for x in 0..<GRID_SIZE {
            guard grid[y][x] == .body else { continue }
            for (dx, dy) in dirs {
                if pget(grid, x: x+dx, y: y+dy) == .empty {
                    edges.append((x, y)); break
                }
            }
        }
    }
    for (x, y) in edges { grid[y][x] = .outline }
}

// MARK: - Main builder (faithful port of JS buildCharacterGrid)
func buildCharacterGrid(dna: PetDNA, pose: PetPose = .idle, frame: Int = 0) -> PetGrid {
    var g = makeEmptyGrid()

    let bodyCx  = dna.bodyCx
    let bodyRy  = dna.bodyRy
    let bodyRx  = dna.bodyRx
    let bodyCy  = dna.bodyCy
    let earTopY = dna.earTopY
    let earSp   = dna.earSp
    let bunnyEarH = dna.bunnyEarH
    let bearEarR  = dna.bearEarR

    // ── Body ────────────────────────────────────────────────────────────────────
    if dna.bodyShape == .pear {
        fillEllipse(&g, cx: bodyCx, cy: bodyCy, rx: bodyRx - 1, ry: (bodyRy * 0.55).rounded(), cell: .body)
        fillEllipse(&g, cx: bodyCx, cy: bodyCy + (bodyRy * 0.35).rounded(), rx: bodyRx + 1, ry: (bodyRy * 0.7).rounded(), cell: .body)
    } else {
        fillEllipse(&g, cx: bodyCx, cy: bodyCy, rx: bodyRx, ry: bodyRy, cell: .body)
    }

    // ── Animal features ─────────────────────────────────────────────────────────
    let lEarX = bodyCx - earSp
    let rEarX = bodyCx + earSp

    switch dna.animalType {
    case .bunny:
        fillEllipse(&g, cx: lEarX, cy: earTopY - bunnyEarH, rx: 1.5, ry: bunnyEarH, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY - bunnyEarH, rx: 1.5, ry: bunnyEarH, cell: .body)
    case .cat:
        let eT = Int(earTopY)
        pset(&g, x: Int(lEarX), y: eT, cell: .body);  pset(&g, x: Int(lEarX), y: eT-1, cell: .body)
        pset(&g, x: max(0, Int(lEarX)-1), y: max(0, eT-2), cell: .body)
        pset(&g, x: Int(rEarX), y: eT, cell: .body);  pset(&g, x: Int(rEarX), y: eT-1, cell: .body)
        pset(&g, x: min(GRID_SIZE-1, Int(rEarX)+1), y: max(0, eT-2), cell: .body)
    case .bear:
        fillEllipse(&g, cx: lEarX, cy: earTopY, rx: bearEarR, ry: bearEarR, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY, rx: bearEarR, ry: bearEarR, cell: .body)
    case .dog:
        // Floppy ear on the right side (body-facing back), columns earRX and earRX+1
        let earRX    = Int((bodyCx + bodyRx).rounded())
        let dogEarTop = Int(bodyCy - (bodyRy * 0.3).rounded()) + 1
        let dogEarBot = Int(bodyCy + (bodyRy * 0.55).rounded()) + 1
        for y in dogEarTop...dogEarBot {
            pset(&g, x: earRX,   y: y, cell: .body)
            pset(&g, x: earRX+1, y: y, cell: .body)
        }
        pset(&g, x: earRX, y: dogEarBot+1, cell: .body)
    case .mouse:
        fillEllipse(&g, cx: lEarX-1, cy: earTopY+1, rx: 2.3, ry: 2.3, cell: .body)
        fillEllipse(&g, cx: rEarX+1, cy: earTopY+1, rx: 2.3, ry: 2.3, cell: .body)
    case .frog:
        let muzzY = bodyCy + (bodyRy * 0.1).rounded()
        let muzzL = Int((bodyCx - bodyRx).rounded()) - 3
        let muzzR = Int(bodyCx) - 1
        for y in Int(muzzY-1)...Int(muzzY+2) { for x in muzzL...muzzR { pset(&g, x: x, y: y, cell: .body) } }
    case .duck:
        // Zigzag wing: even rows 4-wide, odd rows 1-cell tip
        let wY = Int((bodyCy + (bodyRy * 0.1).rounded()).rounded()) - 2
        let wX = Int((bodyCx - bodyRx).rounded()) + 1
        for i in 0..<5 {
            if i % 2 == 0 {
                pset(&g,x:wX-3,y:wY+i,cell:.body); pset(&g,x:wX-2,y:wY+i,cell:.body)
                pset(&g,x:wX-1,y:wY+i,cell:.body); pset(&g,x:wX,  y:wY+i,cell:.body)
            } else {
                pset(&g, x: wX-4, y: wY+i, cell: .body)
            }
        }
    case .axolotl:
        // 3 gill spikes per side, branching outward
        let gBase = Int((bodyCy - (bodyRy * 0.1).rounded()).rounded())
        let lEdge = Int((bodyCx - bodyRx).rounded())
        let rEdge = Int((bodyCx + bodyRx).rounded())
        for o in [-3, 0, 3] {
            let p = gBase + o
            pset(&g,x:lEdge-1,y:p,  cell:.body)
            pset(&g,x:lEdge-2,y:p-1,cell:.body)
            pset(&g,x:lEdge-2,y:p-2,cell:.body)
            pset(&g,x:rEdge+1,y:p,  cell:.body)
            pset(&g,x:rEdge+2,y:p-1,cell:.body)
            pset(&g,x:rEdge+2,y:p-2,cell:.body)
        }
    case .smooth: break
    }

    // ── Arms ────────────────────────────────────────────────────────────────────
    let armY = bodyCy + (bodyRy * 0.1).rounded()
    let lArmX = (bodyCx - bodyRx).rounded() - 1
    let rArmX = (bodyCx + bodyRx).rounded()
    let aY = Int(armY); let lX = Int(lArmX); let rX = Int(rArmX)

    if dna.animalType != .duck {
        switch pose {
        case .happy:
            let hi = frame % 2 == 0
            pset(&g, x: lX, y: hi ? aY-2 : aY-1, cell: .body); pset(&g, x: lX, y: hi ? aY-1 : aY, cell: .body)
            pset(&g, x: rX, y: hi ? aY-2 : aY-1, cell: .body); pset(&g, x: rX, y: hi ? aY-1 : aY, cell: .body)
        case .sad:
            let droop = frame <= 1 ? 1 : 2
            pset(&g, x: lX, y: aY+droop, cell: .body); pset(&g, x: lX, y: aY+droop+1, cell: .body)
            if frame == 3 {
                pset(&g, x: rX, y: aY-1, cell: .body); pset(&g, x: rX, y: aY, cell: .body)
            } else {
                pset(&g, x: rX, y: aY+droop, cell: .body); pset(&g, x: rX, y: aY+droop+1, cell: .body)
            }
        case .running:
            if frame % 2 == 0 {
                pset(&g, x: lX, y: aY+1, cell: .body); pset(&g, x: lX, y: aY+2, cell: .body)
                pset(&g, x: rX, y: aY-2, cell: .body); pset(&g, x: rX, y: aY-1, cell: .body)
            } else {
                pset(&g, x: lX, y: aY-2, cell: .body); pset(&g, x: lX, y: aY-1, cell: .body)
                pset(&g, x: rX, y: aY+1, cell: .body); pset(&g, x: rX, y: aY+2, cell: .body)
            }
        case .jump:
            switch frame {
            case 0: pset(&g, x: lX, y: aY+2, cell: .body); pset(&g, x: lX, y: aY+3, cell: .body)
                    pset(&g, x: rX, y: aY+2, cell: .body); pset(&g, x: rX, y: aY+3, cell: .body)
            case 1: pset(&g, x: lX-1, y: aY, cell: .body); pset(&g, x: lX-1, y: aY-1, cell: .body)
                    pset(&g, x: rX+1, y: aY, cell: .body); pset(&g, x: rX+1, y: aY-1, cell: .body)
            case 2: pset(&g, x: lX, y: aY-2, cell: .body); pset(&g, x: lX, y: aY-1, cell: .body)
                    pset(&g, x: rX, y: aY-2, cell: .body); pset(&g, x: rX, y: aY-1, cell: .body)
            default: pset(&g, x: lX-1, y: aY+1, cell: .body); pset(&g, x: lX, y: aY+2, cell: .body)
                     pset(&g, x: rX+1, y: aY+1, cell: .body); pset(&g, x: rX, y: aY+2, cell: .body)
            }
        case .dead:
            pset(&g, x: lX-1, y: aY, cell: .body); pset(&g, x: lX, y: aY, cell: .body); pset(&g, x: lX, y: aY+1, cell: .body)
            pset(&g, x: rX+1, y: aY, cell: .body); pset(&g, x: rX, y: aY, cell: .body); pset(&g, x: rX, y: aY+1, cell: .body)
        case .hurt:
            switch frame {
            case 0: pset(&g, x: lX, y: aY-2, cell: .body); pset(&g, x: lX, y: aY-1, cell: .body)
                    pset(&g, x: rX, y: aY-2, cell: .body); pset(&g, x: rX, y: aY-1, cell: .body)
            case 1: pset(&g, x: lX-1, y: aY-1, cell: .body); pset(&g, x: lX-2, y: aY-2, cell: .body)
                    pset(&g, x: rX+1, y: aY-1, cell: .body); pset(&g, x: rX+2, y: aY-2, cell: .body)
            case 2: pset(&g, x: lX, y: aY-1, cell: .body); pset(&g, x: lX, y: aY, cell: .body)
                    pset(&g, x: rX, y: aY-1, cell: .body); pset(&g, x: rX+1, y: aY, cell: .body)
            default: pset(&g, x: lX, y: aY, cell: .body); pset(&g, x: lX, y: aY+1, cell: .body)
                     pset(&g, x: rX, y: aY+1, cell: .body); pset(&g, x: rX+1, y: aY+1, cell: .body)
            }
        case .idle:
            switch dna.armStyle {
            case 0: pset(&g, x: lX, y: aY, cell: .body); pset(&g, x: lX, y: aY+1, cell: .body)
            case 1: pset(&g, x: lX, y: aY-1, cell: .body); pset(&g, x: lX, y: aY, cell: .body)
            default: pset(&g, x: lX, y: aY, cell: .body); pset(&g, x: lX-1, y: aY, cell: .body)
            }
            pset(&g, x: rX, y: aY, cell: .body); pset(&g, x: rX, y: aY+1, cell: .body)
        }
    }

    // ── Tail (idle only) ─────────────────────────────────────────────────────────
    // Dog & axolotl always have tail; others only if hasTail is set
    let showTail = (dna.animalType == .dog || dna.animalType == .axolotl)
        ? pose == .idle
        : (dna.hasTail && pose == .idle)

    if showTail {
        let ty = Int(bodyCy) + dna.tailOffset
        switch dna.animalType {
        case .axolotl:
            // Dorsal fin shape
            pset(&g,x:rX+1,y:ty-1,cell:.body); pset(&g,x:rX+1,y:ty,cell:.body); pset(&g,x:rX+1,y:ty+1,cell:.body)
            pset(&g,x:rX+2,y:ty-1,cell:.body); pset(&g,x:rX+2,y:ty,cell:.body); pset(&g,x:rX+3,y:ty,cell:.body)
        case .dog:
            // Curved upward tail
            pset(&g,x:rX+1,y:ty,  cell:.body); pset(&g,x:rX+2,y:ty-1,cell:.body)
            pset(&g,x:rX+2,y:ty-2,cell:.body); pset(&g,x:rX+1,y:ty-3,cell:.body)
        default:
            pset(&g, x: rX, y: ty, cell: .body); pset(&g, x: rX+1, y: ty-1, cell: .body)
        }
    }

    // ── Feet ─────────────────────────────────────────────────────────────────────
    for y in 19...21 { for x in 0..<GRID_SIZE { if g[y][x] == .body { g[y][x] = .empty } } }

    switch pose {
    case .running:
        let leftUp = frame == 0, rightUp = frame == 2
        if leftUp  { pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body);pset(&g,x:9,y:19,cell:.body) }
        else       { pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body) }
        if rightUp { pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body);pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body);pset(&g,x:15,y:19,cell:.body) }
        else       { pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body) }
    case .jump:
        if frame == 0 || frame == 3 {
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        }
    case .dead: break
    case .hurt:
        let sh = (frame == 1 || frame == 2) ? 1 : 0
        pset(&g,x:8-sh,y:19,cell:.body);pset(&g,x:10-sh,y:19,cell:.body);pset(&g,x:8-sh,y:20,cell:.body);pset(&g,x:10-sh,y:20,cell:.body);pset(&g,x:9-sh,y:21,cell:.body)
        pset(&g,x:14+sh,y:19,cell:.body);pset(&g,x:16+sh,y:19,cell:.body);pset(&g,x:14+sh,y:20,cell:.body);pset(&g,x:16+sh,y:20,cell:.body);pset(&g,x:15+sh,y:21,cell:.body)
    default:
        pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
        pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
    }

    // ── Outline ──────────────────────────────────────────────────────────────────
    addOutline(&g)

    // ── Face patch ───────────────────────────────────────────────────────────────
    let faceCx     = bodyCx - 1
    let muzzleBaseY = bodyCy + (bodyRy * 0.2).rounded()
    let eyeY       = bodyCy - (bodyRy * 0.15).rounded()
    let mouthY     = bodyCy + (bodyRy * 0.35).rounded()
    let facePatchCy = ((eyeY + mouthY) / 2).rounded()
    let faceRy     = (mouthY - eyeY) / 2 + 1
    let faceRx     = max(faceRy * 0.65, min(bodyRx * 0.52, faceRy * 0.9))
    fillEllipse(&g, cx: faceCx, cy: facePatchCy, rx: faceRx, ry: faceRy, cell: .face)

    if dna.animalType == .frog {
        let muzzL = Int((bodyCx - bodyRx).rounded()) - 3
        let muzzR = Int(bodyCx) - 1
        let muzzY = bodyCy + (bodyRy * 0.1).rounded()
        for y in Int(muzzY-1)...Int(muzzY+2) {
            for x in muzzL...muzzR {
                let c = pget(g, x: x, y: y)
                if c == .body || c == .outline { pset(&g, x: x, y: y, cell: .face) }
            }
        }
        pset(&g, x: muzzR-1, y: Int(muzzY), cell: .eyePupil)
        pset(&g, x: muzzR-3, y: Int(muzzY), cell: .eyePupil)
    } else if dna.hasMuzzle {
        fillEllipse(&g, cx: faceCx-1, cy: muzzleBaseY+1, rx: 2.5, ry: 1.8, cell: .face)
        pset(&g, x: Int(faceCx)-1, y: Int(muzzleBaseY), cell: .eyePupil)
    }

    // ── Eyes ─────────────────────────────────────────────────────────────────────
    let maxEyeSp = max(1, Int(faceRx - 0.3))
    let eyeSpUsed = min(Int(dna.eyeSp), maxEyeSp)
    let eyeLX = Int(faceCx) - eyeSpUsed
    let eyeRX = Int(faceCx) + eyeSpUsed
    let eyeYI = Int(eyeY)

    for dy in -1...1 { for dx in -1...1 {
        if pget(g, x: eyeLX+dx, y: eyeYI+dy) != .empty { pset(&g, x: eyeLX+dx, y: eyeYI+dy, cell: .face) }
        if pget(g, x: eyeRX+dx, y: eyeYI+dy) != .empty { pset(&g, x: eyeRX+dx, y: eyeYI+dy, cell: .face) }
    }}

    switch pose {
    case .dead:
        for (ex, ey) in [(eyeLX, eyeYI), (eyeRX, eyeYI)] {
            pset(&g,x:ex-1,y:ey-1,cell:.eyePupil); pset(&g,x:ex+1,y:ey-1,cell:.eyePupil)
            pset(&g,x:ex,  y:ey,  cell:.eyePupil)
            pset(&g,x:ex-1,y:ey+1,cell:.eyePupil); pset(&g,x:ex+1,y:ey+1,cell:.eyePupil)
        }
    case .happy:
        pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI-1,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
        pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI-1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
    case .sad:
        if frame == 3 {
            pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        }
    case .hurt:
        if frame < 2 {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        } else {
            for (ex, ey) in [(eyeLX, eyeYI), (eyeRX, eyeYI)] {
                pset(&g,x:ex-1,y:ey-1,cell:.eyePupil); pset(&g,x:ex+1,y:ey-1,cell:.eyePupil)
                pset(&g,x:ex,  y:ey,  cell:.eyePupil)
                pset(&g,x:ex-1,y:ey+1,cell:.eyePupil); pset(&g,x:ex+1,y:ey+1,cell:.eyePupil)
            }
        }
    default:
        switch dna.eyeStyle {
        case 0:
            pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil)
        case 1:
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        case 2:
            pset(&g,x:eyeLX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX-1,y:eyeYI-1,cell:.eyeShine)
        default:
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI-1,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI-1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        }
    }

    if dna.hasNose && pose != .dead {
        pset(&g, x: Int(faceCx), y: eyeYI+2, cell: .eyePupil)
    }

    // ── Mouth ────────────────────────────────────────────────────────────────────
    let mY: Int = dna.hasMuzzle ? Int(muzzleBaseY)+1
                : dna.animalType == .frog ? Int(bodyCy + (bodyRy * 0.12).rounded()) + 2
                : Int(bodyCy + (bodyRy * 0.35).rounded())
    let fCx = Int(faceCx)

    switch pose {
    case .happy:
        pset(&g,x:fCx-2,y:mY,cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY,cell:.mouth)
    case .sad:
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
    case .dead: break
    case .hurt:
        pset(&g,x:fCx-2,y:mY+1,cell:.mouth); pset(&g,x:fCx-1,y:mY,cell:.mouth)
        pset(&g,x:fCx,  y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
    default:
        switch dna.mouthStyle {
        case 0: pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
        case 1: pset(&g,x:fCx,y:mY,cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        case 2: pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
        default: pset(&g,x:fCx,y:mY,cell:.mouth)
        }
    }

    // ── Cheeks ───────────────────────────────────────────────────────────────────
    if dna.hasCheeks && pose != .dead {
        let ckY  = eyeYI + 1
        let ckLX = Int((faceCx - (bodyRx * 0.58)).rounded())
        let ckRX = Int((faceCx + (bodyRx * 0.58)).rounded())
        pset(&g,x:ckLX-1,y:ckY,cell:.cheek); pset(&g,x:ckLX,y:ckY,cell:.cheek)
        pset(&g,x:ckRX,  y:ckY,cell:.cheek); pset(&g,x:ckRX+1,y:ckY,cell:.cheek)
    }

    // ── Body marking (idle) ──────────────────────────────────────────────────────
    if dna.hasMarking && pose == .idle {
        let pY = Int((bodyCy + bodyRy * 0.3).rounded())
        if dna.markingStyle == 0 {
            let sx = Int((faceCx - bodyRx * 0.42).rounded())
            let rx2 = Int((faceCx + bodyRx * 0.42).rounded())
            if pY >= 0 && pY < GRID_SIZE {
                if sx >= 0 && sx < GRID_SIZE && g[pY][sx] == .face { g[pY][sx] = .shade }
                if rx2 >= 0 && rx2 < GRID_SIZE && g[pY][rx2] == .face { g[pY][rx2] = .shade }
            }
        } else {
            let xMin = Int((bodyCx - bodyRx * 0.6).rounded())
            let xMax = Int((bodyCx + bodyRx * 0.6).rounded())
            if pY >= 0 && pY < GRID_SIZE {
                for x in max(0, xMin)...min(GRID_SIZE-1, xMax) {
                    if g[pY][x] == .face || g[pY][x] == .body { g[pY][x] = .shade }
                }
            }
        }
    }

    // ── Bow (idle) ───────────────────────────────────────────────────────────────
    if dna.hasBow && pose == .idle {
        let bY = Int(earTopY) - 1
        pset(&g,x:10,y:bY,  cell:.shade); pset(&g,x:11,y:bY-1,cell:.shade)
        pset(&g,x:12,y:bY,  cell:.eyePupil); pset(&g,x:13,y:bY-1,cell:.shade); pset(&g,x:14,y:bY,cell:.shade)
        pset(&g,x:10,y:bY-1,cell:.shade); pset(&g,x:14,y:bY-1,cell:.shade)
    }

    // ── Happy sparkles ───────────────────────────────────────────────────────────
    if pose == .happy {
        let sets: [[(Int,Int)]] = [
            [(eyeRX+2, eyeYI-2), (lX-1, aY-2)],
            [(Int(faceCx)+4, Int(bodyCy)), (eyeLX-2, eyeYI-1)],
            [(eyeRX+3, Int(bodyCy)-1), (Int(faceCx)-1, Int(earTopY)+1)],
            [(eyeLX-1, eyeYI-3), (rX+1, aY-2)],
        ]
        for (sx, sy) in sets[frame % 4] {
            pset(&g,x:sx,  y:sy-1,cell:.gold); pset(&g,x:sx-1,y:sy,cell:.gold)
            pset(&g,x:sx,  y:sy,  cell:.gold); pset(&g,x:sx+1,y:sy,cell:.gold); pset(&g,x:sx,y:sy+1,cell:.gold)
        }
    }

    // ── Sad tears ────────────────────────────────────────────────────────────────
    if pose == .sad {
        let tearX = frame < 2 ? eyeLX : eyeRX
        let tearY = eyeYI + 1 + (frame % 2) * 2
        pset(&g,x:tearX,y:tearY,  cell:.tear)
        pset(&g,x:tearX,y:tearY+1,cell:.tear)
    }

    // ── Dead: halo + fly ─────────────────────────────────────────────────────────
    if pose == .dead {
        let haloY = max(1, Int(earTopY) - 2)
        for dx in -3...3 {
            let dy = (dx == 0 || dx == -1 || dx == 1) ? -1 : 0
            pset(&g, x: Int(bodyCx)+dx, y: haloY+dy, cell: .gold)
        }
        let flyPos = [(Int(faceCx)+4, Int(bodyCy)-3),(Int(faceCx)+2, Int(bodyCy)-5),
                      (Int(faceCx)-2, Int(bodyCy)-5),(Int(faceCx)-4, Int(bodyCy)-3)]
        let (fx, fy) = flyPos[frame % 4]
        pset(&g,x:fx-1,y:fy,  cell:.gray); pset(&g,x:fx+1,y:fy,cell:.gray); pset(&g,x:fx,y:fy+1,cell:.gray)
    }

    // ── Jump effects ─────────────────────────────────────────────────────────────
    if pose == .jump {
        if frame == 1 || frame == 2 {
            pset(&g,x:Int(bodyCx)-1,y:22,cell:.shade); pset(&g,x:Int(bodyCx),y:22,cell:.shade); pset(&g,x:Int(bodyCx)+1,y:22,cell:.shade)
        }
        if frame == 2 {
            pset(&g,x:lX-1,y:aY-3,cell:.gold); pset(&g,x:lX,y:aY-4,cell:.gold)
            pset(&g,x:rX+1,y:aY-3,cell:.gold); pset(&g,x:rX,y:aY-4,cell:.gold)
        }
        if frame == 3 {
            pset(&g,x:7,y:22,cell:.shade); pset(&g,x:9,y:22,cell:.shade)
            pset(&g,x:15,y:22,cell:.shade); pset(&g,x:17,y:22,cell:.shade)
        }
    }

    // ── Running speed lines ──────────────────────────────────────────────────────
    if pose == .running {
        let lineYs = [Int(bodyCy)-1, Int(bodyCy)+1, Int(bodyCy)+3]
        let lenTable = [[3,1,3],[1,3,1],[3,1,3],[1,3,1]]
        let xShift = frame % 2
        for (i, ly) in lineYs.enumerated() {
            for dx in 0..<lenTable[frame % 4][i] { pset(&g, x: rX+1+xShift+dx, y: ly, cell: .speedLine) }
        }
    }

    // ── Hurt effects ─────────────────────────────────────────────────────────────
    if pose == .hurt {
        if frame == 0 || frame == 1 {
            let sx = Int(faceCx)-3, sy = eyeYI-3
            pset(&g,x:sx,  y:sy-1,cell:.gold); pset(&g,x:sx-1,y:sy,cell:.gold)
            pset(&g,x:sx,  y:sy,  cell:.gold); pset(&g,x:sx+1,y:sy,cell:.gold); pset(&g,x:sx,y:sy+1,cell:.gold)
            pset(&g,x:rX+1,y:aY-2,cell:.gold); pset(&g,x:rX+2,y:aY-3,cell:.gold); pset(&g,x:rX+3,y:aY-2,cell:.gold)
        }
        if frame == 2 || frame == 3 {
            let drop = frame - 2
            pset(&g,x:eyeLX,y:eyeYI+2+drop*2,cell:.tear); pset(&g,x:eyeLX,y:eyeYI+3+drop*2,cell:.tear)
            pset(&g,x:eyeRX,y:eyeYI+2+drop*2,cell:.tear); pset(&g,x:eyeRX,y:eyeYI+3+drop*2,cell:.tear)
        }
    }

    // ── Alebrije accents ─────────────────────────────────────────────────────────
    let aleLX = Int(bodyCx - earSp), aleRX = Int(bodyCx + earSp)
    switch dna.animalType {
    case .bunny where bunnyEarH > 1:
        fillEllipse(&g, cx: Double(aleLX), cy: earTopY-bunnyEarH, rx: 0.7, ry: bunnyEarH-1, cell: .accent1)
        fillEllipse(&g, cx: Double(aleRX), cy: earTopY-bunnyEarH, rx: 0.7, ry: bunnyEarH-1, cell: .accent1)
    case .bear:
        pset(&g,x:aleLX,y:Int(earTopY),cell:.accent1); pset(&g,x:aleRX,y:Int(earTopY),cell:.accent1)
    case .cat:
        // Inner tip accent (updated: offset outward)
        pset(&g,x:aleLX-1,y:Int(earTopY)-1,cell:.accent1)
        pset(&g,x:aleRX+1,y:Int(earTopY)-1,cell:.accent1)
    case .axolotl:
        // Accent tips on outermost gill spike points
        let gBase = Int((bodyCy - (bodyRy * 0.1).rounded()).rounded())
        let lEdge = Int((bodyCx - bodyRx).rounded())
        let rEdge = Int((bodyCx + bodyRx).rounded())
        for o in [-3, 0, 3] {
            pset(&g, x: lEdge-2, y: gBase+o-2, cell: .accent1)
            pset(&g, x: rEdge+2, y: gBase+o-2, cell: .accent1)
        }
    default: break
    }

    for spot in dna.spots {
        let px = Int(bodyCx)+spot.dx, py = Int(bodyCy)+spot.dy
        let c = pget(g, x: px, y: py)
        if c == .body || c == .outline { pset(&g, x: px, y: py, cell: spot.colorIndex == 0 ? .accent1 : .accent2) }
    }

    return g
}
