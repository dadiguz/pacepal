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
    case .raccoon:
        // Small rounded ears
        fillEllipse(&g, cx: lEarX, cy: earTopY, rx: 1.7, ry: 1.7, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY, rx: 1.7, ry: 1.7, cell: .body)
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
    case .capuchin:
        fillEllipse(&g, cx: lEarX, cy: earTopY + 1, rx: 1.5, ry: 1.5, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY + 1, rx: 1.5, ry: 1.5, cell: .body)
        // Dark cap on top of head
        let capBot = Int((bodyCy - (bodyRy * 0.25).rounded()).rounded())
        for y in Int(earTopY)...capBot {
            for x in Int((bodyCx - bodyRx * 0.75).rounded())...Int((bodyCx + bodyRx * 0.75).rounded()) {
                let c = pget(g, x: x, y: y)
                if c == .body || c == .outline { pset(&g, x: x, y: y, cell: .shade) }
            }
        }
    case .mandrill:
        fillEllipse(&g, cx: lEarX, cy: earTopY + 1, rx: 1.4, ry: 1.4, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY + 1, rx: 1.4, ry: 1.4, cell: .body)
    case .fox:
        let t = Int(earTopY)
        pset(&g,x:Int(lEarX)-1,y:t,     cell:.body); pset(&g,x:Int(lEarX),y:t,     cell:.body)
        pset(&g,x:Int(lEarX)-1,y:t-1,   cell:.body); pset(&g,x:Int(lEarX),y:t-1,   cell:.body)
        pset(&g,x:Int(lEarX),  y:max(0,t-2),cell:.body)
        pset(&g,x:Int(lEarX),  y:max(0,t-3),cell:.body)
        pset(&g,x:Int(rEarX),  y:t,     cell:.body); pset(&g,x:Int(rEarX)+1,y:t,   cell:.body)
        pset(&g,x:Int(rEarX),  y:t-1,   cell:.body); pset(&g,x:Int(rEarX)+1,y:t-1, cell:.body)
        pset(&g,x:Int(rEarX),  y:max(0,t-2),cell:.body)
        pset(&g,x:Int(rEarX),  y:max(0,t-3),cell:.body)
    case .lion:
        fillEllipse(&g, cx: lEarX, cy: earTopY, rx: 1.8, ry: 1.8, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY, rx: 1.8, ry: 1.8, cell: .body)
        // Mane: ring of body around face area
        let mCx = bodyCx - 1, mCy = bodyCy
        let mRx = (bodyRx * 0.95).rounded(), mRy = (bodyRy * 0.85).rounded()
        for dy in Int(-mRy)...Int(mRy) {
            for dx in Int(-mRx)...Int(mRx) {
                let dist = (Double(dx)/mRx)*(Double(dx)/mRx) + (Double(dy)/mRy)*(Double(dy)/mRy)
                if dist <= 1.0 && dist >= 0.55 && pget(g, x: Int(mCx)+dx, y: Int(mCy)+dy) == .empty {
                    pset(&g, x: Int(mCx)+dx, y: Int(mCy)+dy, cell: .body)
                }
            }
        }
    case .dog:
        // Floppy ears hanging on each side
        fillEllipse(&g, cx: lEarX - 1.5, cy: earTopY + 2.5, rx: 1.8, ry: 2.8, cell: .body)
        fillEllipse(&g, cx: rEarX + 1.5, cy: earTopY + 2.5, rx: 1.8, ry: 2.8, cell: .body)
    case .tiger:
        // Small rounded ears with pointed feel
        fillEllipse(&g, cx: lEarX, cy: earTopY - 0.5, rx: 1.6, ry: 1.6, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY - 0.5, rx: 1.6, ry: 1.6, cell: .body)
    case .panda:
        // Big round ears on top (recolored dark in accents pass)
        fillEllipse(&g, cx: lEarX, cy: earTopY, rx: 2.2, ry: 2.2, cell: .body)
        fillEllipse(&g, cx: rEarX, cy: earTopY, rx: 2.2, ry: 2.2, cell: .body)
    case .domo: break  // Flat square head, no ears
    case .pou:  break  // Rounded head, no ears
    case .smooth: break
    case .corgi:
        let eT = Int(earTopY)
        // Large upright triangle ears
        pset(&g, x: Int(lEarX)-1, y: eT,   cell: .body); pset(&g, x: Int(lEarX), y: eT,   cell: .body); pset(&g, x: Int(lEarX)+1, y: eT,   cell: .body)
        pset(&g, x: Int(lEarX)-1, y: eT-1, cell: .body); pset(&g, x: Int(lEarX), y: eT-1, cell: .body)
        pset(&g, x: Int(lEarX),   y: eT-2, cell: .body); pset(&g, x: Int(lEarX), y: eT-3, cell: .body)
        pset(&g, x: Int(rEarX)-1, y: eT,   cell: .body); pset(&g, x: Int(rEarX), y: eT,   cell: .body); pset(&g, x: Int(rEarX)+1, y: eT,   cell: .body)
        pset(&g, x: Int(rEarX),   y: eT-1, cell: .body); pset(&g, x: Int(rEarX)+1, y: eT-1, cell: .body)
        pset(&g, x: Int(rEarX),   y: eT-2, cell: .body); pset(&g, x: Int(rEarX),   y: eT-3, cell: .body)
    case .dragon:
        // Horns (recolored accent1 later)
        let hBase = Int(earTopY)
        pset(&g, x: Int(lEarX),     y: hBase,           cell: .body)
        pset(&g, x: Int(lEarX) - 1, y: hBase - 1,       cell: .body)
        pset(&g, x: Int(lEarX) - 1, y: max(0,hBase-2),  cell: .body)
        pset(&g, x: Int(rEarX),     y: hBase,           cell: .body)
        pset(&g, x: Int(rEarX) + 1, y: hBase - 1,       cell: .body)
        pset(&g, x: Int(rEarX) + 1, y: max(0,hBase-2),  cell: .body)
        // Small wing nubs
        let wY = Int((bodyCy - bodyRy * 0.25).rounded())
        pset(&g, x: Int((bodyCx-bodyRx).rounded())-1, y: wY,   cell: .body)
        pset(&g, x: Int((bodyCx-bodyRx).rounded())-2, y: wY-1, cell: .body)
        pset(&g, x: Int((bodyCx+bodyRx).rounded())+1, y: wY,   cell: .body)
        pset(&g, x: Int((bodyCx+bodyRx).rounded())+2, y: wY-1, cell: .body)
    }

    // ── Arms ────────────────────────────────────────────────────────────────────
    let armY = bodyCy + (bodyRy * 0.1).rounded()
    let lArmX = (bodyCx - bodyRx).rounded() - 1
    let rArmX = (bodyCx + bodyRx).rounded()
    let aY = Int(armY); let lX = Int(lArmX); let rX = Int(rArmX)

    if dna.animalType != .duck {
        switch pose {
        case .hype:
            switch frame {
            case 0: // charging: fists raised near shoulders
                pset(&g,x:lX,   y:aY-2,cell:.body); pset(&g,x:lX,   y:aY-1,cell:.body)
                pset(&g,x:rX,   y:aY-2,cell:.body); pset(&g,x:rX,   y:aY-1,cell:.body)
            case 1: // building power: arms spread diagonal upward
                pset(&g,x:lX-1,y:aY-2,cell:.body); pset(&g,x:lX-2,y:aY-1,cell:.body)
                pset(&g,x:rX+1,y:aY-2,cell:.body); pset(&g,x:rX+2,y:aY-1,cell:.body)
            case 2: // peak power scream: arms thrust high and wide
                pset(&g,x:lX-1,y:aY-3,cell:.body); pset(&g,x:lX,   y:aY-2,cell:.body)
                pset(&g,x:rX+1,y:aY-3,cell:.body); pset(&g,x:rX,   y:aY-2,cell:.body)
            default: // sustained: classic flex — arms bent outward
                pset(&g,x:lX-1,y:aY-2,cell:.body); pset(&g,x:lX-1,y:aY-1,cell:.body)
                pset(&g,x:rX+1,y:aY-2,cell:.body); pset(&g,x:rX+1,y:aY-1,cell:.body)
            }
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
        case .angry:
            let hi = frame % 2 == 0
            // Left arm: tense at side, alternates puff
            pset(&g, x: hi ? lX : lX-1, y: aY-1, cell: .body)
            pset(&g, x: hi ? lX : lX-1, y: aY,   cell: .body)
            // Right arm: raised to hold sign
            let rArmTop = hi ? aY-3 : aY-2
            pset(&g, x: hi ? rX : rX+1, y: rArmTop,   cell: .body)
            pset(&g, x: hi ? rX : rX+1, y: rArmTop+1, cell: .body)
        case .sign:
            let bob = frame % 2 == 0
            // Left arm: raised in excitement, bounces up/down
            pset(&g, x: lX-1, y: bob ? aY-3 : aY-2, cell: .body)
            pset(&g, x: lX-1, y: bob ? aY-2 : aY-1, cell: .body)
            // Right arm: raised to hold sign, bobs with animation
            let sArmTop = bob ? aY-3 : aY-2
            pset(&g, x: bob ? rX : rX+1, y: sArmTop,   cell: .body)
            pset(&g, x: bob ? rX : rX+1, y: sArmTop+1, cell: .body)
        case .running:
            switch frame {
            case 0: // left arm far back/low, right arm far forward/high
                pset(&g, x: lX-1, y: aY+2, cell: .body); pset(&g, x: lX,   y: aY+3, cell: .body)
                pset(&g, x: rX,   y: aY-3, cell: .body); pset(&g, x: rX,   y: aY-2, cell: .body)
            case 1: // arms crossing mid
                pset(&g, x: lX,   y: aY+1, cell: .body); pset(&g, x: lX,   y: aY+2, cell: .body)
                pset(&g, x: rX,   y: aY-1, cell: .body); pset(&g, x: rX,   y: aY,   cell: .body)
            case 2: // left arm far forward/high, right arm far back/low
                pset(&g, x: lX,   y: aY-3, cell: .body); pset(&g, x: lX,   y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY+2, cell: .body); pset(&g, x: rX,   y: aY+3, cell: .body)
            default: // arms crossing mid (other direction)
                pset(&g, x: lX,   y: aY-1, cell: .body); pset(&g, x: lX,   y: aY,   cell: .body)
                pset(&g, x: rX,   y: aY+1, cell: .body); pset(&g, x: rX,   y: aY+2, cell: .body)
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
        case .dizzy:
            // One arm raised & flailing, other drooping — alternates sway each frame
            let sway = frame % 2 == 0
            pset(&g, x: sway ? lX-1 : lX,   y: aY-2, cell: .body)
            pset(&g, x: sway ? lX-1 : lX,   y: aY-1, cell: .body)
            pset(&g, x: sway ? rX   : rX+1, y: aY+1, cell: .body)
            pset(&g, x: sway ? rX   : rX+1, y: aY+2, cell: .body)
        case .cheer:
            // Both arms raised high, waving alternately
            let hiC = frame % 2 == 0
            pset(&g, x: hiC ? lX-1 : lX, y: aY-3, cell: .body)
            pset(&g, x: hiC ? lX-1 : lX, y: aY-2, cell: .body)
            pset(&g, x: hiC ? rX+1 : rX, y: aY-3, cell: .body)
            pset(&g, x: hiC ? rX+1 : rX, y: aY-2, cell: .body)
        case .spin:
            // Arms sweep around in a circle each frame
            switch frame {
            case 0:
                pset(&g, x: lX-2, y: aY,   cell: .body); pset(&g, x: lX-1, y: aY,   cell: .body)
                pset(&g, x: rX+1, y: aY,   cell: .body); pset(&g, x: rX+2, y: aY,   cell: .body)
            case 1:
                pset(&g, x: lX-2, y: aY-1, cell: .body); pset(&g, x: lX-1, y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY-2, cell: .body); pset(&g, x: rX+2, y: aY-1, cell: .body)
            case 2:
                pset(&g, x: lX,   y: aY-3, cell: .body); pset(&g, x: lX,   y: aY-2, cell: .body)
                pset(&g, x: rX,   y: aY-3, cell: .body); pset(&g, x: rX,   y: aY-2, cell: .body)
            default:
                pset(&g, x: lX-2, y: aY,   cell: .body); pset(&g, x: lX-1, y: aY+1, cell: .body)
                pset(&g, x: rX+1, y: aY+1, cell: .body); pset(&g, x: rX+2, y: aY,   cell: .body)
            }
        case .bounce:
            // Arms swing: up at peak, down on landing
            let hiB = frame == 1 || frame == 3
            pset(&g, x: lX, y: hiB ? aY-2 : aY+1, cell: .body)
            pset(&g, x: lX, y: hiB ? aY-1 : aY+2, cell: .body)
            pset(&g, x: rX, y: hiB ? aY-2 : aY+1, cell: .body)
            pset(&g, x: rX, y: hiB ? aY-1 : aY+2, cell: .body)
        case .dance:
            // Alternating one arm up, one arm down
            switch frame {
            case 0:
                pset(&g, x: lX-1, y: aY-3, cell: .body); pset(&g, x: lX,   y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY,   cell: .body); pset(&g, x: rX+1, y: aY+1, cell: .body)
            case 2:
                pset(&g, x: lX-1, y: aY,   cell: .body); pset(&g, x: lX-1, y: aY+1, cell: .body)
                pset(&g, x: rX+1, y: aY-3, cell: .body); pset(&g, x: rX,   y: aY-2, cell: .body)
            default:
                pset(&g, x: lX-1, y: aY-1, cell: .body); pset(&g, x: lX-1, y: aY,   cell: .body)
                pset(&g, x: rX+1, y: aY-1, cell: .body); pset(&g, x: rX+1, y: aY,   cell: .body)
            }
        case .wave:
            // Champion wave: alternate which arm is raised high
            if frame < 2 {
                // Left arm waves high, right arm rests low
                pset(&g, x: lX,   y: aY-4, cell: .body); pset(&g, x: lX,   y: aY-3, cell: .body)
                pset(&g, x: lX-1, y: frame == 0 ? aY-4 : aY-3, cell: .body)
                pset(&g, x: rX,   y: aY+1, cell: .body); pset(&g, x: rX,   y: aY+2, cell: .body)
            } else {
                // Right arm waves high, left arm rests low
                pset(&g, x: rX,   y: aY-4, cell: .body); pset(&g, x: rX,   y: aY-3, cell: .body)
                pset(&g, x: rX+1, y: frame == 2 ? aY-4 : aY-3, cell: .body)
                pset(&g, x: lX,   y: aY+1, cell: .body); pset(&g, x: lX,   y: aY+2, cell: .body)
            }
        case .flex:
            // Victory flex: both arms in muscle pose
            switch frame {
            case 0: // arms bent up, fists near shoulders
                pset(&g, x: lX,   y: aY-2, cell: .body); pset(&g, x: lX,   y: aY-1, cell: .body)
                pset(&g, x: rX,   y: aY-2, cell: .body); pset(&g, x: rX,   y: aY-1, cell: .body)
            case 1: // arms spread wide flex
                pset(&g, x: lX-2, y: aY-1, cell: .body); pset(&g, x: lX-1, y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY-2, cell: .body); pset(&g, x: rX+2, y: aY-1, cell: .body)
            case 2: // arms high and bent outward
                pset(&g, x: lX-1, y: aY-3, cell: .body); pset(&g, x: lX-1, y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY-3, cell: .body); pset(&g, x: rX+1, y: aY-2, cell: .body)
            default: // back to shoulders
                pset(&g, x: lX,   y: aY-2, cell: .body); pset(&g, x: lX-1, y: aY-1, cell: .body)
                pset(&g, x: rX,   y: aY-2, cell: .body); pset(&g, x: rX+1, y: aY-1, cell: .body)
            }
        case .star:
            // Star jump: both arms spread wide upward
            let spread = frame % 2 == 0 ? 2 : 1
            pset(&g, x: lX-spread, y: aY-2, cell: .body); pset(&g, x: lX-spread+1, y: aY-1, cell: .body)
            pset(&g, x: rX+spread, y: aY-2, cell: .body); pset(&g, x: rX+spread-1, y: aY-1, cell: .body)
        case .finish:
            switch frame {
            case 0: // running — left arm back, right arm forward
                pset(&g, x: lX-1, y: aY+2, cell: .body); pset(&g, x: lX,   y: aY+3, cell: .body)
                pset(&g, x: rX,   y: aY-3, cell: .body); pset(&g, x: rX,   y: aY-2, cell: .body)
            case 1: // arms crossing mid
                pset(&g, x: lX,   y: aY+1, cell: .body); pset(&g, x: lX,   y: aY+2, cell: .body)
                pset(&g, x: rX,   y: aY-1, cell: .body); pset(&g, x: rX,   y: aY,   cell: .body)
            default: // tape broken — arms thrust high in triumph
                pset(&g, x: lX-1, y: aY-3, cell: .body); pset(&g, x: lX,   y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY-3, cell: .body); pset(&g, x: rX,   y: aY-2, cell: .body)
            }
        case .victory:
            let alt = frame % 2 == 0
            pset(&g, x: alt ? lX-2 : lX-1, y: aY-3, cell: .body)
            pset(&g, x: alt ? lX-1 : lX,   y: aY-2, cell: .body)
            pset(&g, x: alt ? rX+2 : rX+1, y: aY-3, cell: .body)
            pset(&g, x: alt ? rX+1 : rX,   y: aY-2, cell: .body)
        case .clap:
            let close = frame % 2 == 0
            pset(&g, x: close ? lX+2 : lX+1, y: aY-1, cell: .body)
            pset(&g, x: close ? lX+2 : lX+1, y: aY,   cell: .body)
            pset(&g, x: close ? rX-2 : rX-1, y: aY-1, cell: .body)
            pset(&g, x: close ? rX-2 : rX-1, y: aY,   cell: .body)
        case .skip:
            switch frame {
            case 0:
                pset(&g, x: lX-1, y: aY+3, cell: .body); pset(&g, x: lX,   y: aY+4, cell: .body)
                pset(&g, x: rX,   y: aY-3, cell: .body); pset(&g, x: rX+1, y: aY-4, cell: .body)
            case 1:
                pset(&g, x: lX,   y: aY+1, cell: .body); pset(&g, x: lX,   y: aY+2, cell: .body)
                pset(&g, x: rX,   y: aY-1, cell: .body); pset(&g, x: rX,   y: aY,   cell: .body)
            case 2:
                pset(&g, x: lX+1, y: aY-4, cell: .body); pset(&g, x: lX,   y: aY-3, cell: .body)
                pset(&g, x: rX+1, y: aY+3, cell: .body); pset(&g, x: rX,   y: aY+4, cell: .body)
            default:
                pset(&g, x: lX,   y: aY-1, cell: .body); pset(&g, x: lX,   y: aY,   cell: .body)
                pset(&g, x: rX,   y: aY+1, cell: .body); pset(&g, x: rX,   y: aY+2, cell: .body)
            }
        case .stretch:
            let w = frame % 2 == 0 ? 3 : 2
            pset(&g, x: lX-w,   y: aY, cell: .body); pset(&g, x: lX-w+1, y: aY, cell: .body)
            pset(&g, x: rX+w-1, y: aY, cell: .body); pset(&g, x: rX+w,   y: aY, cell: .body)
        case .stomp:
            let hiS = frame % 2 == 0
            pset(&g, x: lX, y: hiS ? aY-3 : aY-2, cell: .body)
            pset(&g, x: lX, y: hiS ? aY-2 : aY-1, cell: .body)
            pset(&g, x: rX, y: hiS ? aY-3 : aY-2, cell: .body)
            pset(&g, x: rX, y: hiS ? aY-2 : aY-1, cell: .body)
        case .leap:
            switch frame {
            case 0, 2:
                pset(&g, x: lX-2, y: aY-2, cell: .body); pset(&g, x: lX-1, y: aY-1, cell: .body)
                pset(&g, x: rX+1, y: aY-2, cell: .body); pset(&g, x: rX+2, y: aY-1, cell: .body)
            default:
                pset(&g, x: lX-1, y: aY-3, cell: .body); pset(&g, x: lX,   y: aY-2, cell: .body)
                pset(&g, x: rX,   y: aY-3, cell: .body); pset(&g, x: rX+1, y: aY-2, cell: .body)
            }
        case .salute:
            let altS = frame % 2 == 0
            pset(&g, x: lX, y: aY, cell: .body); pset(&g, x: lX, y: aY+1, cell: .body)
            pset(&g, x: altS ? rX+1 : rX, y: aY-2, cell: .body)
            pset(&g, x: rX,               y: aY-1, cell: .body)
            if altS { pset(&g, x: rX+2, y: aY-2, cell: .body) }
        case .shimmy:
            let sw = frame % 2 == 0
            pset(&g, x: sw ? lX-1 : lX, y: aY,   cell: .body)
            pset(&g, x: sw ? lX-1 : lX, y: aY+1, cell: .body)
            pset(&g, x: sw ? rX+1 : rX, y: aY,   cell: .body)
            pset(&g, x: sw ? rX+1 : rX, y: aY+1, cell: .body)
        case .kick:
            switch frame {
            case 0, 2:
                pset(&g, x: lX, y: aY+1, cell: .body); pset(&g, x: lX, y: aY+2, cell: .body)
                pset(&g, x: rX, y: aY-3, cell: .body); pset(&g, x: rX, y: aY-2, cell: .body)
            default:
                pset(&g, x: lX, y: aY-3, cell: .body); pset(&g, x: lX, y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY+1, cell: .body); pset(&g, x: rX, y: aY+2, cell: .body)
            }
        case .pump:
            switch frame {
            case 0, 2:
                pset(&g, x: lX, y: aY-3, cell: .body); pset(&g, x: lX, y: aY-2, cell: .body)
                pset(&g, x: rX, y: aY,   cell: .body); pset(&g, x: rX, y: aY+1, cell: .body)
            default:
                pset(&g, x: lX, y: aY,   cell: .body); pset(&g, x: lX, y: aY+1, cell: .body)
                pset(&g, x: rX, y: aY-3, cell: .body); pset(&g, x: rX, y: aY-2, cell: .body)
            }
        case .twirl:
            switch frame {
            case 0:
                pset(&g, x: lX-1, y: aY-2, cell: .body); pset(&g, x: lX-2, y: aY-1, cell: .body)
                pset(&g, x: rX+2, y: aY,   cell: .body); pset(&g, x: rX+1, y: aY+1, cell: .body)
            case 1:
                pset(&g, x: lX,   y: aY-3, cell: .body); pset(&g, x: lX-1, y: aY-2, cell: .body)
                pset(&g, x: rX+1, y: aY-1, cell: .body); pset(&g, x: rX+2, y: aY,   cell: .body)
            case 2:
                pset(&g, x: lX+1, y: aY-1, cell: .body); pset(&g, x: lX+2, y: aY,   cell: .body)
                pset(&g, x: rX,   y: aY-3, cell: .body); pset(&g, x: rX-1, y: aY-2, cell: .body)
            default:
                pset(&g, x: lX,   y: aY+2, cell: .body); pset(&g, x: lX+1, y: aY+1, cell: .body)
                pset(&g, x: rX-1, y: aY-2, cell: .body); pset(&g, x: rX,   y: aY-3, cell: .body)
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
    // These types always show tail at idle; others only if hasTail is set
    let showTail = (dna.animalType == .raccoon || dna.animalType == .axolotl ||
                    dna.animalType == .capuchin || dna.animalType == .mandrill ||
                    dna.animalType == .fox || dna.animalType == .lion ||
                    dna.animalType == .dog || dna.animalType == .tiger)
        ? pose == .idle
        : (dna.hasTail && pose == .idle)

    if showTail {
        let ty = Int(bodyCy) + dna.tailOffset
        switch dna.animalType {
        case .axolotl:
            // Dorsal fin shape
            pset(&g,x:rX+1,y:ty-1,cell:.body); pset(&g,x:rX+1,y:ty,cell:.body); pset(&g,x:rX+1,y:ty+1,cell:.body)
            pset(&g,x:rX+2,y:ty-1,cell:.body); pset(&g,x:rX+2,y:ty,cell:.body); pset(&g,x:rX+3,y:ty,cell:.body)
        case .raccoon:
            // Ringed tail: alternating body/face (face renders bright outside body sphere)
            pset(&g,x:rX+1,y:ty,  cell:.body);  pset(&g,x:rX+2,y:ty,  cell:.body)
            pset(&g,x:rX+2,y:ty-1,cell:.face);  pset(&g,x:rX+3,y:ty-1,cell:.face)
            pset(&g,x:rX+3,y:ty-2,cell:.body);  pset(&g,x:rX+2,y:ty-2,cell:.body)
            pset(&g,x:rX+2,y:ty-3,cell:.face);  pset(&g,x:rX+1,y:ty-3,cell:.face)
            pset(&g,x:rX+1,y:ty-4,cell:.body);  pset(&g,x:rX,  y:ty-4,cell:.body)
        case .capuchin:
            // Long curled tail
            pset(&g,x:rX+1,y:ty,  cell:.body); pset(&g,x:rX+2,y:ty-1,cell:.body)
            pset(&g,x:rX+3,y:ty-2,cell:.body); pset(&g,x:rX+3,y:ty-3,cell:.body)
            pset(&g,x:rX+2,y:ty-4,cell:.body); pset(&g,x:rX+1,y:ty-4,cell:.body)
            pset(&g,x:rX+1,y:ty-3,cell:.body)
        case .mandrill:
            // Short upright tail
            pset(&g,x:rX+1,y:ty,  cell:.body)
            pset(&g,x:rX+1,y:ty-1,cell:.body)
            pset(&g,x:rX,  y:ty-2,cell:.body)
        case .fox:
            // Big fluffy curved tail with accent tip
            pset(&g,x:rX+1,y:ty,  cell:.body); pset(&g,x:rX+2,y:ty,  cell:.body)
            pset(&g,x:rX+2,y:ty-1,cell:.body); pset(&g,x:rX+3,y:ty-2,cell:.body)
            pset(&g,x:rX+3,y:ty-3,cell:.body); pset(&g,x:rX+2,y:ty-4,cell:.body)
            pset(&g,x:rX+1,y:ty-5,cell:.body); pset(&g,x:rX+1,y:ty-4,cell:.body)
            pset(&g,x:rX+1,y:ty-6,cell:.accent1); pset(&g,x:rX+2,y:ty-5,cell:.accent1)
        case .lion:
            // Long tail with accent tassel
            pset(&g,x:rX+1,y:ty,  cell:.body); pset(&g,x:rX+2,y:ty-1,cell:.body)
            pset(&g,x:rX+3,y:ty-2,cell:.body); pset(&g,x:rX+3,y:ty-3,cell:.body)
            pset(&g,x:rX+2,y:ty-4,cell:.body)
            pset(&g,x:rX+2,y:ty-5,cell:.accent1); pset(&g,x:rX+1,y:ty-5,cell:.accent1)
            pset(&g,x:rX+3,y:ty-5,cell:.accent1); pset(&g,x:rX+2,y:ty-6,cell:.accent1)
        case .dog:
            // Short wagging tail curving up
            pset(&g,x:rX+1,y:ty,  cell:.body)
            pset(&g,x:rX+2,y:ty-1,cell:.body)
            pset(&g,x:rX+2,y:ty-2,cell:.body)
            pset(&g,x:rX+1,y:ty-3,cell:.body)
        case .tiger:
            // Long striped tail curving outward
            pset(&g,x:rX+1,y:ty,  cell:.body); pset(&g,x:rX+2,y:ty-1,cell:.body)
            pset(&g,x:rX+3,y:ty-2,cell:.body); pset(&g,x:rX+3,y:ty-3,cell:.body)
            pset(&g,x:rX+2,y:ty-4,cell:.body); pset(&g,x:rX+1,y:ty-4,cell:.body)
            pset(&g,x:rX+2,y:ty-5,cell:.shade); pset(&g,x:rX+1,y:ty-5,cell:.shade)
            pset(&g,x:rX+2,y:ty-6,cell:.accent1); pset(&g,x:rX+1,y:ty-6,cell:.accent1)
        default:
            pset(&g, x: rX, y: ty, cell: .body); pset(&g, x: rX+1, y: ty-1, cell: .body)
        }
    }

    // ── Feet ─────────────────────────────────────────────────────────────────────
    for y in 19...21 { for x in 0..<GRID_SIZE { if g[y][x] == .body { g[y][x] = .empty } } }

    switch pose {
    case .running:
        // Left foot: frame 0=UP, frame 1=MID, frames 2-3=DOWN
        switch frame {
        case 0: pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body);pset(&g,x:9,y:19,cell:.body)
        case 1: pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body);pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:9,y:20,cell:.body)
        default:pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
        }
        // Right foot: frames 0-1=DOWN, frame 2=UP, frame 3=MID
        switch frame {
        case 2: pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body);pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body);pset(&g,x:15,y:19,cell:.body)
        case 3: pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body);pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body)
        default:pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        }
    case .jump:
        if frame == 0 || frame == 3 {
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        }
    case .hype:
        pset(&g,x:7, y:19,cell:.body); pset(&g,x:9, y:19,cell:.body)
        pset(&g,x:7, y:20,cell:.body); pset(&g,x:9, y:20,cell:.body); pset(&g,x:8, y:21,cell:.body)
        pset(&g,x:15,y:19,cell:.body); pset(&g,x:17,y:19,cell:.body)
        pset(&g,x:15,y:20,cell:.body); pset(&g,x:17,y:20,cell:.body); pset(&g,x:16,y:21,cell:.body)
    case .dead: break
    case .hurt:
        let sh = (frame == 1 || frame == 2) ? 1 : 0
        pset(&g,x:8-sh,y:19,cell:.body);pset(&g,x:10-sh,y:19,cell:.body);pset(&g,x:8-sh,y:20,cell:.body);pset(&g,x:10-sh,y:20,cell:.body);pset(&g,x:9-sh,y:21,cell:.body)
        pset(&g,x:14+sh,y:19,cell:.body);pset(&g,x:16+sh,y:19,cell:.body);pset(&g,x:14+sh,y:20,cell:.body);pset(&g,x:16+sh,y:20,cell:.body);pset(&g,x:15+sh,y:21,cell:.body)
    case .bounce:
        // Feet tucked at peak, landing-wide at ground
        if frame == 1 || frame == 3 {
            pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body)
            pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body);pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body)
        } else {
            pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
            pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
        }
    case .dance:
        // Step left on frame 0, step right on frame 2, center on 1/3
        switch frame {
        case 0:
            pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
            pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        case 2:
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
        default:
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        }
    case .flex:
        // Wide stance flex
        pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
        pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
    case .star:
        // Super wide star stance, alternating width
        if frame % 2 == 0 {
            pset(&g,x:6,y:19,cell:.body);pset(&g,x:8,y:19,cell:.body);pset(&g,x:6,y:20,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:7,y:21,cell:.body)
            pset(&g,x:16,y:19,cell:.body);pset(&g,x:18,y:19,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:18,y:20,cell:.body);pset(&g,x:17,y:21,cell:.body)
        } else {
            pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
            pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
        }
    case .finish:
        // Running feet for frames 0-1, wide triumph stance for 2-3
        if frame < 2 {
            switch frame {
            case 0:
                pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body);pset(&g,x:9,y:19,cell:.body)
                pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
            default:
                pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body);pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:9,y:20,cell:.body)
                pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body);pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body)
            }
        } else {
            // Wide celebratory stance after crossing
            pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
            pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
        }
    case .skip:
        // Exaggerated skip — big alternating leg lift
        switch frame {
        case 0: // Left leg kicked forward/high, right planted
            pset(&g,x:8,y:16,cell:.body);pset(&g,x:10,y:16,cell:.body);pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:9,y:18,cell:.body)
            pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        case 2: // Right leg kicked forward/high, left planted
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:14,y:16,cell:.body);pset(&g,x:16,y:16,cell:.body);pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body);pset(&g,x:15,y:18,cell:.body)
        default: // Both mid-transition
            pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body);pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body)
            pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body);pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body)
        }
    case .stomp:
        // Alternating heavy stomp — one foot slams, other lifts
        if frame % 2 == 0 {
            pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
            pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body);pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body)
        } else {
            pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body)
            pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
        }
    case .leap:
        // Both feet tucked high — soaring in the air
        if frame == 0 || frame == 2 {
            pset(&g,x:8,y:16,cell:.body);pset(&g,x:10,y:16,cell:.body);pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body)
            pset(&g,x:14,y:16,cell:.body);pset(&g,x:16,y:16,cell:.body);pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body)
        } else {
            pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body);pset(&g,x:8,y:18,cell:.body);pset(&g,x:10,y:18,cell:.body)
            pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body);pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body)
        }
    case .kick:
        // Left foot planted, right foot kicks wide
        switch frame {
        case 0, 2: // Kick extended
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:17,y:15,cell:.body);pset(&g,x:19,y:15,cell:.body);pset(&g,x:17,y:16,cell:.body);pset(&g,x:19,y:16,cell:.body)
        default: // Kick retracting
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:14,y:18,cell:.body);pset(&g,x:16,y:18,cell:.body);pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body)
        }
    case .twirl:
        // Feet sweep in a circle — spinning ballet
        switch frame {
        case 0:
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:14,y:16,cell:.body);pset(&g,x:16,y:16,cell:.body);pset(&g,x:14,y:17,cell:.body);pset(&g,x:16,y:17,cell:.body)
        case 1:
            pset(&g,x:7,y:19,cell:.body);pset(&g,x:9,y:19,cell:.body);pset(&g,x:7,y:20,cell:.body);pset(&g,x:9,y:20,cell:.body);pset(&g,x:8,y:21,cell:.body)
            pset(&g,x:15,y:19,cell:.body);pset(&g,x:17,y:19,cell:.body);pset(&g,x:15,y:20,cell:.body);pset(&g,x:17,y:20,cell:.body);pset(&g,x:16,y:21,cell:.body)
        case 2:
            pset(&g,x:8,y:16,cell:.body);pset(&g,x:10,y:16,cell:.body);pset(&g,x:8,y:17,cell:.body);pset(&g,x:10,y:17,cell:.body)
            pset(&g,x:14,y:19,cell:.body);pset(&g,x:16,y:19,cell:.body);pset(&g,x:14,y:20,cell:.body);pset(&g,x:16,y:20,cell:.body);pset(&g,x:15,y:21,cell:.body)
        default:
            pset(&g,x:8,y:19,cell:.body);pset(&g,x:10,y:19,cell:.body);pset(&g,x:8,y:20,cell:.body);pset(&g,x:10,y:20,cell:.body);pset(&g,x:9,y:21,cell:.body)
            pset(&g,x:15,y:16,cell:.body);pset(&g,x:17,y:16,cell:.body);pset(&g,x:15,y:17,cell:.body);pset(&g,x:17,y:17,cell:.body)
        }
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

    if dna.animalType == .domo {
        // Replace face patch with body color (dark face, no light patch)
        for y in 0..<GRID_SIZE { for x in 0..<GRID_SIZE { if g[y][x] == .face { g[y][x] = .body } } }
    } else if dna.animalType == .frog {
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
    } else if dna.animalType == .mandrill {
        // Prominent jaw muzzle
        fillEllipse(&g, cx: faceCx-1, cy: muzzleBaseY+1, rx: 2.8, ry: 2, cell: .face)
        pset(&g, x: Int(faceCx)-3, y: Int(muzzleBaseY), cell: .eyePupil)
        pset(&g, x: Int(faceCx)-2, y: Int(muzzleBaseY), cell: .eyePupil)
    } else if dna.animalType == .fox {
        // Pointy fox muzzle
        fillEllipse(&g, cx: faceCx-2, cy: muzzleBaseY+1, rx: 2.8, ry: 1.8, cell: .face)
        pset(&g, x: Int(faceCx)-4, y: Int(muzzleBaseY),   cell: .eyePupil)
        pset(&g, x: Int(faceCx)-5, y: Int(muzzleBaseY),   cell: .eyePupil)
        pset(&g, x: Int(faceCx)-4, y: Int(muzzleBaseY)+1, cell: .eyePupil)
    } else if dna.animalType == .lion {
        // Wide lion muzzle
        fillEllipse(&g, cx: faceCx-1, cy: muzzleBaseY+1, rx: 3.5, ry: 2.2, cell: .face)
        pset(&g, x: Int(faceCx)-3, y: Int(muzzleBaseY),   cell: .eyePupil)
        pset(&g, x: Int(faceCx)-4, y: Int(muzzleBaseY),   cell: .eyePupil)
        pset(&g, x: Int(faceCx)-3, y: Int(muzzleBaseY)+1, cell: .eyePupil)
        pset(&g, x: Int(faceCx)-4, y: Int(muzzleBaseY)+1, cell: .eyePupil)
    } else if dna.animalType == .pou {
        // Pou freckles beside nose
        pset(&g, x: Int(faceCx)-3, y: Int(muzzleBaseY),   cell: .shade)
        pset(&g, x: Int(faceCx)-3, y: Int(muzzleBaseY)+1, cell: .shade)
        pset(&g, x: Int(faceCx)+1, y: Int(muzzleBaseY),   cell: .shade)
        pset(&g, x: Int(faceCx)+1, y: Int(muzzleBaseY)+1, cell: .shade)
    } else if dna.animalType == .dog {
        // Dog snout — wide oval + double nose dot
        fillEllipse(&g, cx: faceCx-1, cy: muzzleBaseY+1, rx: 2.8, ry: 2.0, cell: .face)
        pset(&g, x: Int(faceCx)-1, y: Int(muzzleBaseY), cell: .eyePupil)
        pset(&g, x: Int(faceCx),   y: Int(muzzleBaseY), cell: .eyePupil)
    } else if dna.animalType == .tiger {
        // Tiger muzzle — wide, flat
        fillEllipse(&g, cx: faceCx-1, cy: muzzleBaseY+1, rx: 3.0, ry: 1.8, cell: .face)
        pset(&g, x: Int(faceCx)-1, y: Int(muzzleBaseY), cell: .eyePupil)
    } else if dna.hasMuzzle {
        fillEllipse(&g, cx: faceCx-1, cy: muzzleBaseY+1, rx: 2.5, ry: 1.8, cell: .face)
        pset(&g, x: Int(faceCx)-1, y: Int(muzzleBaseY), cell: .eyePupil)
    }

    // ── Raccoon eye mask ─────────────────────────────────────────────────────────
    if dna.animalType == .raccoon && pose != .dead {
        let maskEyeSp = min(Int(dna.eyeSp), max(1, Int(faceRx - 0.3)))
        let maskLX = Int(faceCx) - maskEyeSp
        let maskRX = Int(faceCx) + maskEyeSp
        let maskY  = Int(eyeY)
        for dy in -2...2 { for dx in -3...3 {
            if pget(g, x: maskLX+dx, y: maskY+dy) == .face { pset(&g, x: maskLX+dx, y: maskY+dy, cell: .shade) }
            if pget(g, x: maskRX+dx, y: maskY+dy) == .face { pset(&g, x: maskRX+dx, y: maskY+dy, cell: .shade) }
        }}
    }

    // ── Panda eye patches ────────────────────────────────────────────────────────
    if dna.animalType == .panda && pose != .dead {
        let maxEyeSpP = max(1, Int(faceRx - 0.3))
        let pEyeSp = min(Int(dna.eyeSp), maxEyeSpP)
        let pEyeLX = Double(Int(faceCx) - pEyeSp)
        let pEyeRX = Double(Int(faceCx) + pEyeSp)
        fillEllipse(&g, cx: pEyeLX, cy: eyeY, rx: 2.2, ry: 1.8, cell: .shade)
        fillEllipse(&g, cx: pEyeRX, cy: eyeY, rx: 2.2, ry: 1.8, cell: .shade)
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
    case .hype:
        // Happy sparkly eyes — big 2×2, shine twinkles between frames
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:frame%2==0 ? eyeLX-1 : eyeLX, y:eyeYI-1, cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:frame%2==0 ? eyeRX : eyeRX+1,   y:eyeYI-1, cell:.eyeShine)
    case .dead:
        for (ex, ey) in [(eyeLX, eyeYI), (eyeRX, eyeYI)] {
            pset(&g,x:ex-1,y:ey-1,cell:.eyePupil); pset(&g,x:ex+1,y:ey-1,cell:.eyePupil)
            pset(&g,x:ex,  y:ey,  cell:.eyePupil)
            pset(&g,x:ex-1,y:ey+1,cell:.eyePupil); pset(&g,x:ex+1,y:ey+1,cell:.eyePupil)
        }
    case .happy:
        // Kirby 2×2 + shine — same as idle so it looks consistent
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
    case .sad:
        // 2×2 shifted down; frame 3 → tiny single pupil
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        if frame == 3 {
            pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil)
        }
    case .angry:
        // Slanted inward: outer corner high, inner corner low → angry V-brow feel
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX,  y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
    case .sign:
        // Big happy wide eyes with shine — excited and welcoming
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
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
    case .dizzy:
        // Spinning X↔+ alternating each frame to simulate spiral/dizzy eyes
        for (ex, ey) in [(eyeLX, eyeYI), (eyeRX, eyeYI)] {
            if frame % 2 == 0 {
                // X pattern
                pset(&g,x:ex-1,y:ey-1,cell:.eyePupil); pset(&g,x:ex+1,y:ey-1,cell:.eyePupil)
                pset(&g,x:ex,  y:ey,  cell:.eyePupil)
                pset(&g,x:ex-1,y:ey+1,cell:.eyePupil); pset(&g,x:ex+1,y:ey+1,cell:.eyePupil)
            } else {
                // + pattern
                pset(&g,x:ex,  y:ey-1,cell:.eyePupil)
                pset(&g,x:ex-1,y:ey,  cell:.eyePupil); pset(&g,x:ex,y:ey,cell:.eyePupil); pset(&g,x:ex+1,y:ey,cell:.eyePupil)
                pset(&g,x:ex,  y:ey+1,cell:.eyePupil)
            }
        }
    case .cheer:
        // Happy wide eyes with shine
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
    case .bounce:
        // Wide eyes at peak, happy eyes on landing
        if frame == 1 || frame == 3 {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        }
    case .spin:
        // Alternating open/squint eyes
        if frame % 2 == 0 {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        }
    case .dance:
        // Wink alternating sides
        if frame == 0 {
            // Wink left (left eye = closed bar)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        } else if frame == 2 {
            // Wink right (right eye = closed bar)
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        } else {
            // Both eyes open happy
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        }
    case .wave:
        // Happy eyes with shine
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
    case .flex:
        // Intense hype-style 2×2 eyes — fierce and determined
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
    case .star:
        // Wide excited eyes with double shine
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeLX,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeRX+1,y:eyeYI-1,cell:.eyeShine)
    case .finish:
        if frame < 2 {
            // Fierce focused eyes while running (like hype)
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        } else {
            // Wide joyful eyes with double shine after crossing
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeLX,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeRX+1,y:eyeYI-1,cell:.eyeShine)
        }
    case .victory:
        // Wide eyes, double shine — triumphant
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeLX,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeRX+1,y:eyeYI-1,cell:.eyeShine)
    case .clap:
        // Squinting excited eyes — clapping energy
        if frame % 2 == 0 {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        }
    case .skip:
        // Happy wide eyes with shine — light and bouncy
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
    case .stretch:
        // Half-closed relaxed eyes — zen stretch
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
    case .stomp:
        // Alternating wide/squint for stomping intensity
        if frame % 2 == 0 {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        }
    case .leap:
        // Wide excited eyes with double shine — soaring
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeLX,y:eyeYI-1,cell:.eyeShine)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine); pset(&g,x:eyeRX+1,y:eyeYI-1,cell:.eyeShine)
    case .salute:
        // Determined focused eyes, no shine — proud
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
    case .shimmy:
        // Alternating wink left/right — groovy
        if frame % 2 == 0 {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil) // wink right
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil) // wink left
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        }
    case .kick:
        // Fierce intense eyes — powerful
        pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
        pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
    case .pump:
        // Alternating squint/wide with pumping energy
        if frame % 2 == 0 {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        }
    case .twirl:
        // Spinning open/squint alternating like spin
        if frame % 2 == 0 {
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
        } else {
            pset(&g,x:eyeLX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeLX+1,y:eyeYI,cell:.eyePupil)
            pset(&g,x:eyeRX-1,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX,y:eyeYI,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,cell:.eyePupil)
        }
    default:
        if pose == .idle && frame == 6 {
            // Blink: ojos cerrados (barra horizontal)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
        } else {
            // Kirby-style 2×2 blocks with shine — faithful to JS
            pset(&g,x:eyeLX-1,y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeLX,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeLX-1,y:eyeYI-1,cell:.eyeShine)
            pset(&g,x:eyeRX,  y:eyeYI,  cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI,  cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI+1,cell:.eyePupil); pset(&g,x:eyeRX+1,y:eyeYI+1,cell:.eyePupil)
            pset(&g,x:eyeRX,  y:eyeYI-1,cell:.eyeShine)
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

    if dna.animalType == .domo {
        // Wide rectangular Domo mouth with teeth, always open
        let dmTop = mY - 1
        let openH = (pose == .happy || pose == .hype) ? 4 : (pose == .sad) ? 2 : 3
        // Upper teeth (alternating face color)
        var dx = -3; while dx <= 3 { pset(&g, x: fCx+dx, y: dmTop, cell: .face); dx += 2 }
        // Dark interior
        for row in 0..<openH { for dx2 in -4...4 { pset(&g, x: fCx+dx2, y: dmTop+1+row, cell: .eyePupil) } }
        // Lower teeth
        var dx3 = -2; while dx3 <= 2 { pset(&g, x: fCx+dx3, y: dmTop+1+openH, cell: .face); dx3 += 2 }
    } else {
    switch pose {
    case .hype:
        // Huge excited open smile
        pset(&g,x:fCx-3,y:mY,cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth); pset(&g,x:fCx+3,y:mY,cell:.mouth)
    case .happy:
        pset(&g,x:fCx-2,y:mY,cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY,cell:.mouth)
    case .sad:
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
    case .angry:
        // Flat gritted line
        pset(&g,x:fCx-2,y:mY,cell:.mouth); pset(&g,x:fCx-1,y:mY,cell:.mouth)
        pset(&g,x:fCx,  y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
    case .dead: break
    case .hurt:
        pset(&g,x:fCx-2,y:mY+1,cell:.mouth); pset(&g,x:fCx-1,y:mY,cell:.mouth)
        pset(&g,x:fCx,  y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
    case .dizzy:
        // Wavy nauseous mouth — zigzag flips phase each frame
        if frame % 2 == 0 {
            pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+2,y:mY,  cell:.mouth)
        } else {
            pset(&g,x:fCx-2,y:mY+1,cell:.mouth); pset(&g,x:fCx-1,y:mY,  cell:.mouth)
            pset(&g,x:fCx,  y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,  cell:.mouth)
            pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        }
    case .cheer:
        // Big open excited smile (same arc as hype)
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .bounce, .spin:
        // Happy curve
        pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+2,y:mY,  cell:.mouth)
    case .dance:
        // Big smile on wink frames, normal smile on other frames
        if frame == 0 || frame == 2 {
            pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+2,y:mY,  cell:.mouth)
        } else {
            pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
        }
    case .wave:
        // Happy curve
        pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+2,y:mY,  cell:.mouth)
    case .flex:
        // Big open power smile
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .star:
        // Wide open excited mouth
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .finish:
        // Big open smile all frames, extra wide after crossing
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .victory:
        // Wide open triumphant smile
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .clap:
        // Open excited smile — alternates full/mid
        if frame % 2 == 0 {
            pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
            pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
            pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+3,y:mY,  cell:.mouth)
        } else {
            pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+2,y:mY,  cell:.mouth)
        }
    case .skip:
        // Light happy bounce smile
        pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+2,y:mY,  cell:.mouth)
    case .stretch:
        // Relaxed content smile — calm stretch
        pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
    case .stomp:
        // Big power open mouth — stomping intensity
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .leap:
        // Wide open mouth — soaring rush
        pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
        pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+3,y:mY,  cell:.mouth)
    case .salute:
        // Proud small smile — dignified
        pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
    case .shimmy:
        // Groovy alternating smile/grin
        if frame % 2 == 0 {
            pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+2,y:mY,  cell:.mouth)
        } else {
            pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
        }
    case .kick:
        // Open power mouth — high kick battle cry
        pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+2,y:mY,  cell:.mouth)
    case .pump:
        // Alternating open shout / happy smile
        if frame % 2 == 0 {
            pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
            pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
            pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+3,y:mY,  cell:.mouth)
        } else {
            pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+2,y:mY,  cell:.mouth)
        }
    case .twirl:
        // Happy spinning smile — graceful
        pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        pset(&g,x:fCx+2,y:mY,  cell:.mouth)
    case .sign:
        // Big open smile alternating — beaming with happiness
        if frame % 2 == 0 {
            pset(&g,x:fCx-3,y:mY,  cell:.mouth); pset(&g,x:fCx-2,y:mY+1,cell:.mouth)
            pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx,  y:mY+1,cell:.mouth)
            pset(&g,x:fCx+1,y:mY+1,cell:.mouth); pset(&g,x:fCx+2,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+3,y:mY,  cell:.mouth)
        } else {
            pset(&g,x:fCx-2,y:mY,  cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx,  y:mY,  cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
            pset(&g,x:fCx+2,y:mY,  cell:.mouth)
        }
    default:
        switch dna.mouthStyle {
        case 0: pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
        case 1: pset(&g,x:fCx,y:mY,cell:.mouth); pset(&g,x:fCx-1,y:mY+1,cell:.mouth); pset(&g,x:fCx+1,y:mY+1,cell:.mouth)
        case 2: pset(&g,x:fCx-1,y:mY,cell:.mouth); pset(&g,x:fCx,y:mY,cell:.mouth); pset(&g,x:fCx+1,y:mY,cell:.mouth)
        default: pset(&g,x:fCx,y:mY,cell:.mouth)
        }
    } // end switch pose
    } // end else (non-Domo mouth)

    // ── Cheeks ───────────────────────────────────────────────────────────────────
    if dna.hasCheeks && pose != .dead && dna.animalType != .domo {
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

    // ── Hype aura — 11 spiky rays + lightning (faithful port of JS) ─────────────
    // ── Sad tears ────────────────────────────────────────────────────────────────
    if pose == .sad {
        let tearX = frame < 2 ? eyeLX : eyeRX
        let tearY = eyeYI + 1 + (frame % 2) * 2
        pset(&g,x:tearX,y:tearY,  cell:.tear)
        pset(&g,x:tearX,y:tearY+1,cell:.tear)
    }

    // ── Angry sign + vein ────────────────────────────────────────────────────────
    if pose == .angry {
        let hi = frame % 2 == 0
        let stickX = hi ? rX : rX + 1
        let punchY = hi ? aY - 3 : aY - 2

        // Stick (3 cells up from punch point)
        for dy in 1...3 { pset(&g, x: stickX, y: punchY - dy, cell: .body) }

        // Sign frame
        let sX1 = max(0, stickX - 2)
        let sX2 = min(GRID_SIZE - 1, stickX + 2)
        let sY2 = punchY - 4
        let sY1 = max(0, sY2 - 3)

        // Border
        for x in sX1...sX2 {
            pset(&g, x: x, y: sY1, cell: .outline)
            pset(&g, x: x, y: sY2, cell: .outline)
        }
        for y in sY1...sY2 {
            pset(&g, x: sX1, y: y, cell: .outline)
            pset(&g, x: sX2, y: y, cell: .outline)
        }

        // Fill interior
        if sX1 + 1 <= sX2 - 1 && sY1 + 1 <= sY2 - 1 {
            for y in (sY1 + 1)...(sY2 - 1) {
                for x in (sX1 + 1)...(sX2 - 1) { pset(&g, x: x, y: y, cell: .face) }
            }
        }

        // "!" — alternates color between eyePupil and accent1
        let bangColor: PetCell = hi ? .eyePupil : .accent1
        pset(&g, x: stickX, y: sY1 + 1, cell: bangColor)
        pset(&g, x: stickX, y: sY2 - 1, cell: bangColor)

        // Anger vein on left temple (Z-shape)
        let vx = eyeLX - 2, vy = eyeYI - 4
        pset(&g, x: vx,   y: vy,   cell: .speedLine)
        pset(&g, x: vx+1, y: vy+1, cell: .speedLine)
        pset(&g, x: vx,   y: vy+2, cell: .speedLine)
    }

    // ── Happy sign + sparkles ────────────────────────────────────────────────────
    if pose == .sign {
        let bob = frame % 2 == 0
        let stickX = bob ? rX : rX + 1
        let punchY = bob ? aY - 3 : aY - 2

        // Stick
        for dy in 1...3 { pset(&g, x: stickX, y: punchY - dy, cell: .body) }

        // Sign frame with accent1 border (cheerful, not angry)
        let sX1 = max(0, stickX - 2)
        let sX2 = min(GRID_SIZE - 1, stickX + 2)
        let sY2 = punchY - 4
        let sY1 = max(0, sY2 - 3)

        for x in sX1...sX2 {
            pset(&g, x: x, y: sY1, cell: .accent1)
            pset(&g, x: x, y: sY2, cell: .accent1)
        }
        for y in sY1...sY2 {
            pset(&g, x: sX1, y: y, cell: .accent1)
            pset(&g, x: sX2, y: y, cell: .accent1)
        }

        // Fill interior
        if sX1 + 1 <= sX2 - 1 && sY1 + 1 <= sY2 - 1 {
            for y in (sY1 + 1)...(sY2 - 1) {
                for x in (sX1 + 1)...(sX2 - 1) { pset(&g, x: x, y: y, cell: .face) }
            }
        }

        // Bell icon: top row = bell body (3px), bottom-center = clapper dot
        let signCx = (sX1 + sX2) / 2
        if sY1 + 1 < sY2 {
            pset(&g, x: signCx - 1, y: sY1 + 1, cell: bob ? .accent1 : .gold)
            pset(&g, x: signCx,     y: sY1 + 1, cell: bob ? .accent1 : .gold)
            pset(&g, x: signCx + 1, y: sY1 + 1, cell: bob ? .accent1 : .gold)
        }
        if sY2 - 1 > sY1 {
            pset(&g, x: signCx, y: sY2 - 1, cell: bob ? .gold : .accent1)
        }

        // Sparkles alternating corners
        if bob {
            pset(&g, x: sX1 - 1, y: sY1,     cell: .gold)
            pset(&g, x: sX2 + 1, y: sY2 - 1, cell: .gold)
        } else {
            pset(&g, x: sX2 + 1, y: sY1,     cell: .accent2)
            pset(&g, x: sX1 - 1, y: sY2 - 1, cell: .accent2)
        }
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

    // ── Running speed lines + dust ───────────────────────────────────────────────
    if pose == .running {
        let lineYs = [Int(bodyCy)-2, Int(bodyCy), Int(bodyCy)+2, Int(bodyCy)+4]
        let lenTable = [[4,1,3,1],[2,3,1,2],[3,1,4,1],[1,2,2,3]]
        let xShift = frame % 2
        for (i, ly) in lineYs.enumerated() {
            for dx in 0..<lenTable[frame][i] { pset(&g, x: rX+1+xShift+dx, y: ly, cell: .speedLine) }
        }
        // Dust puff on foot strike
        if frame == 0 { // right foot just planted
            pset(&g,x:13,y:22,cell:.shade); pset(&g,x:14,y:22,cell:.shade); pset(&g,x:15,y:22,cell:.shade); pset(&g,x:16,y:22,cell:.shade)
            pset(&g,x:12,y:21,cell:.shade); pset(&g,x:17,y:21,cell:.shade)
        } else if frame == 2 { // left foot just planted
            pset(&g,x:7,y:22,cell:.shade); pset(&g,x:8,y:22,cell:.shade); pset(&g,x:9,y:22,cell:.shade); pset(&g,x:10,y:22,cell:.shade)
            pset(&g,x:6,y:21,cell:.shade); pset(&g,x:11,y:21,cell:.shade)
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

    // ── Cheer sparkles ────────────────────────────────────────────────────────────
    if pose == .cheer {
        let sparkPos: [(Int, Int)] = [
            (lX-2, aY-5), (rX+2, aY-5),
            (lX-3, aY-3), (rX+3, aY-3)
        ]
        let (sx, sy) = sparkPos[frame % 4]
        pset(&g,x:sx,  y:sy-1,cell:.gold); pset(&g,x:sx-1,y:sy,cell:.gold)
        pset(&g,x:sx,  y:sy,  cell:.gold); pset(&g,x:sx+1,y:sy,cell:.gold); pset(&g,x:sx,y:sy+1,cell:.gold)
    }

    // ── Spin effects (rotating star + speed lines) ────────────────────────────────
    if pose == .spin {
        let spinPos: [(Int, Int)] = [
            (lX-3, aY-2), (Int(bodyCx), Int(earTopY)-3), (rX+3, aY-2), (rX+2, Int(bodyCy)+3)
        ]
        let (sx, sy) = spinPos[frame % 4]
        pset(&g,x:sx,  y:sy-1,cell:.gold); pset(&g,x:sx-1,y:sy,cell:.gold)
        pset(&g,x:sx,  y:sy,  cell:.gold); pset(&g,x:sx+1,y:sy,cell:.gold); pset(&g,x:sx,y:sy+1,cell:.gold)
        for sdy in [-1, 0, 1] {
            if pget(g, x: lX-1, y: aY+sdy) == .empty { pset(&g, x: lX-1, y: aY+sdy, cell: .speedLine) }
            if pget(g, x: rX+1, y: aY+sdy) == .empty { pset(&g, x: rX+1, y: aY+sdy, cell: .speedLine) }
        }
    }

    // ── Bounce effects (peak sparks / landing dust) ───────────────────────────────
    if pose == .bounce {
        if frame == 1 || frame == 3 {
            pset(&g,x:lX,  y:aY-4,cell:.gold); pset(&g,x:lX-1,y:aY-5,cell:.gold)
            pset(&g,x:rX,  y:aY-4,cell:.gold); pset(&g,x:rX+1,y:aY-5,cell:.gold)
        } else {
            pset(&g,x:7,y:22,cell:.shade); pset(&g,x:9,y:22,cell:.shade)
            pset(&g,x:6,y:21,cell:.shade); pset(&g,x:10,y:21,cell:.shade)
            pset(&g,x:14,y:22,cell:.shade); pset(&g,x:16,y:22,cell:.shade)
            pset(&g,x:13,y:21,cell:.shade); pset(&g,x:17,y:21,cell:.shade)
        }
    }

    // ── Dance effects (gold note near raised arm) ──────────────────────────────────
    if pose == .dance {
        let noteX: Int
        let noteY = aY - 4
        switch frame {
        case 0: noteX = rX + 3
        case 2: noteX = lX - 3
        default: noteX = frame == 1 ? rX + 2 : lX - 2
        }
        pset(&g,x:noteX,  y:noteY,   cell:.gold)
        pset(&g,x:noteX,  y:noteY-1, cell:.gold)
        pset(&g,x:noteX+1,y:noteY,   cell:.gold)
    }

    // ── Wave effects (sparkle near raised hand) ────────────────────────────────────
    if pose == .wave {
        let wx = frame < 2 ? lX - 2 : rX + 2
        let wy = aY - 5
        pset(&g,x:wx,  y:wy-1,cell:.gold); pset(&g,x:wx-1,y:wy,cell:.gold)
        pset(&g,x:wx,  y:wy,  cell:.gold); pset(&g,x:wx+1,y:wy,cell:.gold)
        pset(&g,x:wx,  y:wy+1,cell:.gold)
    }

    // ── Flex effects (power aura — lightning bolts) ────────────────────────────────
    if pose == .flex {
        if frame == 1 || frame == 3 {
            pset(&g,x:lX-2,y:aY-3,cell:.lightning); pset(&g,x:lX-3,y:aY-4,cell:.lightning)
            pset(&g,x:lX-2,y:aY-5,cell:.lightning)
            pset(&g,x:rX+2,y:aY-3,cell:.lightning); pset(&g,x:rX+3,y:aY-4,cell:.lightning)
            pset(&g,x:rX+2,y:aY-5,cell:.lightning)
        } else {
            pset(&g,x:lX-1,y:aY-3,cell:.gold); pset(&g,x:lX-2,y:aY-2,cell:.gold)
            pset(&g,x:rX+1,y:aY-3,cell:.gold); pset(&g,x:rX+2,y:aY-2,cell:.gold)
        }
    }

    // ── Star burst effects ─────────────────────────────────────────────────────────
    if pose == .star {
        let burstR: [(Int, Int)] = [
            (Int(bodyCx), Int(earTopY)-3),
            (lX-3, aY-3),
            (rX+3, aY-3),
            (Int(bodyCx), Int(bodyCy)+Int(bodyRy)+2)
        ]
        let (bx, by) = burstR[frame % 4]
        pset(&g,x:bx,  y:by-1,cell:.gold); pset(&g,x:bx-1,y:by,cell:.gold)
        pset(&g,x:bx,  y:by,  cell:.gold); pset(&g,x:bx+1,y:by,cell:.gold)
        pset(&g,x:bx,  y:by+1,cell:.gold)
        // Speed lines radiating out
        if frame % 2 == 0 {
            pset(&g,x:lX-1,y:aY-1,cell:.speedLine); pset(&g,x:rX+1,y:aY-1,cell:.speedLine)
            pset(&g,x:lX-1,y:aY+1,cell:.speedLine); pset(&g,x:rX+1,y:aY+1,cell:.speedLine)
        }
    }

    // ── Finish line crossing effects ──────────────────────────────────────────────
    if pose == .finish {
        if frame < 2 {
            // Gold finish-line tape (vertical band just ahead of the pet)
            let tapeX = rX + 4
            for ty in (aY - 5)...(aY + 5) {
                if ty >= 0 && ty < GRID_SIZE && pget(g, x: tapeX, y: ty) == .empty {
                    pset(&g, x: tapeX, y: ty, cell: .gold)
                }
            }
            // Speed lines charging toward the tape
            for sly in [Int(bodyCy)-2, Int(bodyCy), Int(bodyCy)+2] {
                for sdx in 1...3 {
                    if pget(g, x: rX+sdx, y: sly) == .empty { pset(&g, x: rX+sdx, y: sly, cell: .speedLine) }
                }
            }
        } else {
            // Tape broken — gold fragments burst outward
            let fragments: [(Int, Int)] = [
                (rX+5, aY-5), (rX+6, aY-3), (rX+5, aY-1),
                (lX-4, aY-5), (lX-5, aY-3), (Int(bodyCx), Int(earTopY)-4),
                (rX+4, aY-7), (lX-3, aY-7)
            ]
            for (fx, fy) in fragments {
                if fy >= 0 && fy < GRID_SIZE && fx >= 0 && fx < GRID_SIZE {
                    if pget(g, x: fx, y: fy) == .empty { pset(&g, x: fx, y: fy, cell: .gold) }
                }
            }
            // Lightning burst
            pset(&g, x: rX+5, y: aY-4, cell: .lightning); pset(&g, x: rX+6, y: aY-5, cell: .lightning)
            pset(&g, x: lX-4, y: aY-4, cell: .lightning); pset(&g, x: lX-5, y: aY-5, cell: .lightning)
            // Speed lines trailing behind
            let trailLen = frame == 2 ? 4 : 6
            for sly in [Int(bodyCy)-3, Int(bodyCy)-1, Int(bodyCy)+1, Int(bodyCy)+3] {
                for sdx in 1...trailLen {
                    if pget(g, x: rX+sdx, y: sly) == .empty { pset(&g, x: rX+sdx, y: sly, cell: .speedLine) }
                }
            }
        }
    }

    // ── Victory effects (V-burst gold sparkles) ───────────────────────────────────
    if pose == .victory {
        let altV = frame % 2 == 0
        let vLx = altV ? lX-3 : lX-2
        let vRx = altV ? rX+3 : rX+2
        pset(&g,x:vLx,  y:aY-4,cell:.gold); pset(&g,x:vLx-1,y:aY-5,cell:.gold)
        pset(&g,x:vRx,  y:aY-4,cell:.gold); pset(&g,x:vRx+1,y:aY-5,cell:.gold)
        pset(&g,x:Int(bodyCx),y:Int(earTopY)-3,cell:.gold)
    }

    // ── Clap effects (impact burst between hands) ─────────────────────────────────
    if pose == .clap {
        if frame % 2 == 0 {
            // Hands together — star burst at center
            let cx2 = Int(bodyCx)
            pset(&g,x:cx2,  y:aY-2,cell:.gold); pset(&g,x:cx2-1,y:aY-1,cell:.gold)
            pset(&g,x:cx2+1,y:aY-1,cell:.gold); pset(&g,x:cx2,  y:aY,  cell:.gold)
            pset(&g,x:cx2,  y:aY-3,cell:.speedLine)
        }
    }

    // ── Skip effects (trail sparkles at foot peak) ─────────────────────────────────
    if pose == .skip {
        let skipPos: [(Int, Int)] = [(lX-1, aY-4), (Int(bodyCx), Int(earTopY)-2), (rX+1, aY-4), (lX-2, aY-2)]
        let (sx, sy) = skipPos[frame % 4]
        pset(&g,x:sx,  y:sy-1,cell:.gold); pset(&g,x:sx-1,y:sy,cell:.gold)
        pset(&g,x:sx,  y:sy,  cell:.gold); pset(&g,x:sx+1,y:sy,cell:.gold); pset(&g,x:sx,y:sy+1,cell:.gold)
    }

    // ── Stretch effects (calming aura rings) ──────────────────────────────────────
    if pose == .stretch {
        if frame % 2 == 0 {
            pset(&g,x:lX-2,y:aY,cell:.speedLine); pset(&g,x:lX-3,y:aY,cell:.speedLine)
            pset(&g,x:rX+2,y:aY,cell:.speedLine); pset(&g,x:rX+3,y:aY,cell:.speedLine)
        }
    }

    // ── Stomp effects (shockwave dust on stomp) ────────────────────────────────────
    if pose == .stomp {
        if frame % 2 == 0 {
            // Left foot stomp impact
            pset(&g,x:6,y:22,cell:.shade); pset(&g,x:7,y:22,cell:.shade); pset(&g,x:8,y:22,cell:.shade); pset(&g,x:9,y:22,cell:.shade)
            pset(&g,x:5,y:21,cell:.shade); pset(&g,x:10,y:21,cell:.shade)
        } else {
            // Right foot stomp impact
            pset(&g,x:15,y:22,cell:.shade); pset(&g,x:16,y:22,cell:.shade); pset(&g,x:17,y:22,cell:.shade); pset(&g,x:18,y:22,cell:.shade)
            pset(&g,x:14,y:21,cell:.shade); pset(&g,x:19,y:21,cell:.shade)
        }
    }

    // ── Leap effects (speed lines upward + soar sparks) ───────────────────────────
    if pose == .leap {
        let bLeft2 = Int((bodyCx - bodyRx).rounded()) - 1
        let bRight2 = Int((bodyCx + bodyRx).rounded()) + 1
        for sdy in [-2, -1, 0, 1, 2] {
            if pget(g, x: bLeft2-1, y: Int(bodyCy)+sdy) == .empty { pset(&g, x: bLeft2-1, y: Int(bodyCy)+sdy, cell: .speedLine) }
            if pget(g, x: bLeft2-2, y: Int(bodyCy)+sdy) == .empty { pset(&g, x: bLeft2-2, y: Int(bodyCy)+sdy, cell: .speedLine) }
            if pget(g, x: bRight2+1, y: Int(bodyCy)+sdy) == .empty { pset(&g, x: bRight2+1, y: Int(bodyCy)+sdy, cell: .speedLine) }
        }
        if frame == 0 || frame == 2 {
            pset(&g,x:lX-3,y:aY-3,cell:.gold); pset(&g,x:rX+3,y:aY-3,cell:.gold)
        }
    }

    // ── Salute effects (respect sparkle near forehead) ─────────────────────────────
    if pose == .salute {
        let altSal = frame % 2 == 0
        let sx2 = altSal ? rX+2 : rX+3
        pset(&g,x:sx2,  y:aY-4,cell:.gold); pset(&g,x:sx2+1,y:aY-5,cell:.gold)
        pset(&g,x:sx2,  y:aY-3,cell:.gold)
    }

    // ── Shimmy effects (groovy music notes) ───────────────────────────────────────
    if pose == .shimmy {
        let notePos: [(Int, Int)] = [(lX-2, aY-3), (rX+2, aY-4), (Int(bodyCx)-1, Int(earTopY)-2), (rX+3, aY-2)]
        let (nx, ny) = notePos[frame % 4]
        pset(&g,x:nx,  y:ny,   cell:.gold)
        pset(&g,x:nx,  y:ny-1, cell:.gold)
        pset(&g,x:nx+1,y:ny,   cell:.gold)
    }

    // ── Kick effects (impact burst at foot + speed lines) ─────────────────────────
    if pose == .kick {
        if frame == 0 || frame == 2 {
            pset(&g,x:20,y:14,cell:.gold); pset(&g,x:21,y:15,cell:.gold); pset(&g,x:20,y:16,cell:.gold)
            pset(&g,x:19,y:14,cell:.speedLine); pset(&g,x:19,y:16,cell:.speedLine)
        }
    }

    // ── Pump effects (fist lightning on pump frames) ───────────────────────────────
    if pose == .pump {
        if frame == 0 || frame == 2 {
            pset(&g,x:lX-1,y:aY-4,cell:.lightning); pset(&g,x:lX-2,y:aY-5,cell:.lightning)
            pset(&g,x:lX-1,y:aY-6,cell:.lightning)
        } else {
            pset(&g,x:rX+1,y:aY-4,cell:.lightning); pset(&g,x:rX+2,y:aY-5,cell:.lightning)
            pset(&g,x:rX+1,y:aY-6,cell:.lightning)
        }
    }

    // ── Twirl effects (swirling gold trail) ───────────────────────────────────────
    if pose == .twirl {
        let twirls: [(Int, Int)] = [
            (lX-3, aY-2), (Int(bodyCx), Int(earTopY)-3), (rX+3, aY-2), (Int(bodyCx)+2, Int(bodyCy)+2)
        ]
        let (tx, ty) = twirls[frame % 4]
        pset(&g,x:tx,  y:ty-1,cell:.gold); pset(&g,x:tx-1,y:ty,cell:.gold)
        pset(&g,x:tx,  y:ty,  cell:.gold); pset(&g,x:tx+1,y:ty,cell:.gold); pset(&g,x:tx,y:ty+1,cell:.gold)
        for sdy in [-1, 0, 1] {
            if pget(g, x: lX-1, y: aY+sdy) == .empty { pset(&g, x: lX-1, y: aY+sdy, cell: .speedLine) }
            if pget(g, x: rX+1, y: aY+sdy) == .empty { pset(&g, x: rX+1, y: aY+sdy, cell: .speedLine) }
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
    case .raccoon:
        // Inner ear dot accent
        pset(&g, x: aleLX, y: Int(earTopY), cell: .accent1)
        pset(&g, x: aleRX, y: Int(earTopY), cell: .accent1)
    case .capuchin:
        // Cap border accent
        pset(&g, x: aleLX, y: Int(earTopY), cell: .accent1)
        pset(&g, x: aleRX, y: Int(earTopY), cell: .accent1)
    case .mandrill:
        // Colored stripes on muzzle sides (distinctive mandrill feature)
        let eyeYF = bodyCy - (bodyRy * 0.15).rounded()
        pset(&g, x: Int(faceCx)-4, y: Int(eyeYF)+1, cell: .accent1)
        pset(&g, x: Int(faceCx)-4, y: Int(eyeYF)+2, cell: .accent1)
        pset(&g, x: Int(faceCx)-4, y: Int(eyeYF)+3, cell: .accent2)
        pset(&g, x: Int(faceCx)-1, y: Int(eyeYF)+1, cell: .accent1)
        pset(&g, x: Int(faceCx)-1, y: Int(eyeYF)+2, cell: .accent1)
        pset(&g, x: Int(faceCx)-1, y: Int(eyeYF)+3, cell: .accent2)
    case .fox:
        // Ear interior and tip accents
        pset(&g, x: aleLX,   y: Int(earTopY)-1, cell: .accent1)
        pset(&g, x: aleRX,   y: Int(earTopY)-1, cell: .accent1)
        pset(&g, x: aleLX-1, y: Int(earTopY),   cell: .accent2)
        pset(&g, x: aleRX+1, y: Int(earTopY),   cell: .accent2)
    case .lion:
        // Accent outer ring of mane
        let mCxL = bodyCx - 1, mCyL = bodyCy
        let mRxL = (bodyRx * 0.95).rounded(), mRyL = (bodyRy * 0.85).rounded()
        for dy in Int(-mRyL)...Int(mRyL) {
            for dx in Int(-mRxL)...Int(mRxL) {
                let dist = (Double(dx)/mRxL)*(Double(dx)/mRxL) + (Double(dy)/mRyL)*(Double(dy)/mRyL)
                if dist <= 1.0 && dist >= 0.7 && pget(g, x: Int(mCxL)+dx, y: Int(mCyL)+dy) == .body {
                    pset(&g, x: Int(mCxL)+dx, y: Int(mCyL)+dy, cell: .accent1)
                }
            }
        }
        pset(&g, x: aleLX, y: Int(earTopY), cell: .accent2)
        pset(&g, x: aleRX, y: Int(earTopY), cell: .accent2)
    case .dog:
        // Inner ear warm highlight
        pset(&g, x: aleLX, y: Int(earTopY)+2, cell: .accent1)
        pset(&g, x: aleRX, y: Int(earTopY)+2, cell: .accent1)
    case .tiger:
        // Three vertical body stripes
        let stripeYs = [Int(bodyCy)-2, Int(bodyCy), Int(bodyCy)+2]
        for sy in stripeYs {
            let xl = Int((bodyCx - bodyRx * 0.5).rounded())
            let xr = Int((bodyCx + bodyRx * 0.5).rounded())
            for x in max(0, xl)...min(GRID_SIZE-1, xr) {
                if pget(g, x: x, y: sy) == .body { pset(&g, x: x, y: sy, cell: .accent1) }
            }
        }
    case .panda:
        // Dark ears (shade fill over body-colored ears)
        fillEllipse(&g, cx: Double(aleLX), cy: earTopY, rx: 2.0, ry: 2.0, cell: .shade)
        fillEllipse(&g, cx: Double(aleRX), cy: earTopY, rx: 2.0, ry: 2.0, cell: .shade)
    case .dragon:
        // Horns in accent1
        let hBase = Int(earTopY)
        for (hx, hy) in [(Int(lEarX), hBase), (Int(lEarX)-1, hBase-1), (Int(lEarX)-1, max(0,hBase-2)),
                         (Int(rEarX), hBase), (Int(rEarX)+1, hBase-1), (Int(rEarX)+1, max(0,hBase-2))] {
            if let c = pget(g, x: hx, y: hy), c == .body || c == .outline { pset(&g, x: hx, y: hy, cell: .accent1) }
        }
    case .domo, .pou: break
    default: break
    }

    for spot in dna.spots {
        let px = Int(bodyCx)+spot.dx, py = Int(bodyCy)+spot.dy
        let c = pget(g, x: px, y: py)
        if c == .body || c == .outline { pset(&g, x: px, y: py, cell: spot.colorIndex == 0 ? .accent1 : .accent2) }
    }

    // ── Hype aura — pixel-art outline alternating orange ↔ yellow each frame ──────
    if pose == .hype {
        let auraColor: PetCell = frame % 2 == 0 ? .lightning : .gold
        let silhouette: Set<PetCell> = [.body, .outline, .face, .eyeWhite, .eyePupil,
                                        .eyeShine, .mouth, .cheek, .shade, .nose, .accent1, .accent2]
        var toMark: [(Int, Int)] = []
        let dirs = [(-1,0),(1,0),(0,-1),(0,1)]
        for y in 0..<GRID_SIZE {
            for x in 0..<GRID_SIZE {
                guard g[y][x] == .empty else { continue }
                for (dx, dy) in dirs {
                    if let cell = pget(g, x: x+dx, y: y+dy), silhouette.contains(cell) {
                        toMark.append((x, y)); break
                    }
                }
            }
        }
        for (x, y) in toMark { pset(&g, x: x, y: y, cell: auraColor) }
    }

    return g
}
