import SwiftUI

// MARK: – Frame capture

struct TutorialFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

// MARK: – Steps definition

struct TutorialStep {
    let frameKey: String
    let titleKey: String
    let bodyKey: String
    var title: String { L(titleKey) }
    var body: String { L(bodyKey) }
}

let tutorialSteps: [TutorialStep] = [
    TutorialStep(
        frameKey: "energy",
        titleKey: "tutorial.energy_title",
        bodyKey: "tutorial.energy_body"
    ),
    TutorialStep(
        frameKey: "km",
        titleKey: "tutorial.km_title",
        bodyKey: "tutorial.km_body"
    ),
]

// MARK: – Overlay

struct TutorialOverlayView: View {
    let step: Int
    let frames: [String: CGRect]
    let onNext: () -> Void
    let onSkip: () -> Void

    @Environment(AppState.self) private var appState

    private var current: TutorialStep { tutorialSteps[step] }

    private var currentBody: String {
        if current.bodyKey == "tutorial.km_body" {
            let pct = Int(appState.challengeLevel.energyPerKm * 100)
            return L("tutorial.km_body", pct)
        }
        return current.body
    }
    private var isLast: Bool { step == tutorialSteps.count - 1 }

    private var highlight: CGRect {
        let base = frames[current.frameKey] ?? .zero
        return base.insetBy(dx: -14, dy: -10)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Dimmed overlay with spotlight cutout ────────────────
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .mask(
                        ZStack {
                            Rectangle()
                            if highlight != .zero {
                                RoundedRectangle(cornerRadius: 16)
                                    .frame(width: highlight.width, height: highlight.height)
                                    .position(x: highlight.midX, y: highlight.midY)
                                    .blendMode(.destinationOut)
                            }
                        }
                        .compositingGroup()
                    )

                // ── Orange border around highlight ──────────────────────
                if highlight != .zero {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(hex: "#F9703E"), lineWidth: 2)
                        .frame(width: highlight.width, height: highlight.height)
                        .position(x: highlight.midX, y: highlight.midY)
                }

                // ── Callout card ────────────────────────────────────────
                let putBelow = highlight.midY < geo.size.height / 2

                VStack(spacing: 0) {
                    if putBelow {
                        Spacer().frame(height: max(highlight.maxY + 20, 0))
                    } else {
                        Spacer()
                    }

                    calloutCard(step: step, isLast: isLast)
                        .padding(.horizontal, 24)
                        .transition(.move(edge: putBelow ? .bottom : .top).combined(with: .opacity))

                    if putBelow {
                        Spacer()
                    } else {
                        Spacer().frame(height: max(geo.size.height - highlight.minY + 20, 0))
                    }
                }
                .animation(.spring(duration: 0.35), value: step)
            }
        }
        .ignoresSafeArea()
    }

    private func calloutCard(step: Int, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Step dots
            HStack(spacing: 5) {
                ForEach(0..<tutorialSteps.count, id: \.self) { i in
                    Circle()
                        .fill(i == step ? Color(hex: "#F9703E") : Color(hex: "#CBD2D9"))
                        .frame(width: i == step ? 7 : 5, height: i == step ? 7 : 5)
                }
            }

            Text(current.title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))

            Text(currentBody)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#4A5568"))
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Button(L("tutorial.skip")) { onSkip() }
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))

                Spacer()

                Button(isLast ? L("tutorial.done") : L("tutorial.next")) { onNext() }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Color(hex: "#F9703E"))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.14), radius: 24, y: 8)
    }
}
