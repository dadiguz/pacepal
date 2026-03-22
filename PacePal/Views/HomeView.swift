import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var currentPose: PetPose = .idle
    @State private var showCharacterSelect = false

    private var dna: PetDNA { appState.selectedCharacter! }
    private var accentColor: Color { Color(hex: dna.palette.body) }

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────────────────────────
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                Spacer()

                // ── Companion stage ──────────────────────────────────────────
                companionStage
                    .padding(.horizontal, 24)

                // ── Pose label ───────────────────────────────────────────────
                poseLabel
                    .padding(.top, 12)

                Spacer()

                // ── Pose buttons (for prototype testing) ─────────────────────
                poseButtonsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
        }
    }

    // MARK: – Top bar
    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PacePal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Text("Day 1 / 66")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#616E7C"))
            }
            Spacer()
            Button {
                showCharacterSelect = true
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color(hex: "#616E7C"))
                    .padding(10)
                    .background(Color(hex: "#EDF0F4"))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: – Companion stage
    private var companionStage: some View {
        ZStack {
            // Stage card
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 20, y: 6)

            VStack(spacing: 0) {
                // Pose name chip
                Text(currentPose.rawValue.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Capsule())
                    .padding(.top, 20)

                // Character (big, ~260pt canvas → 260/24 ≈ 10.8 pt per pixel)
                PetAnimationView(dna: dna, pose: currentPose, pixelSize: 10.8)
                    .id(dna.id)
                    .padding(.vertical, 12)

                // Mood description
                Text(moodText)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "#616E7C"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – Pose label
    private var poseLabel: some View {
        HStack(spacing: 6) {
            Text(currentPose.emoji)
            Text("Animation: \(currentPose.label)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
        }
    }

    // MARK: – Pose buttons
    private var poseButtonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("PREVIEW ANIMATIONS")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(Color(hex: "#9AA5B4"))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(PetPose.allCases) { pose in
                    PoseButton(pose: pose, isActive: currentPose == pose, accentColor: accentColor) {
                        withAnimation(.spring(duration: 0.25)) {
                            currentPose = pose
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }

    // MARK: – Mood text
    private var moodText: String {
        switch currentPose {
        case .idle:    return "\(dna.name) is waiting for you..."
        case .happy:   return "\(dna.name) is full of energy!"
        case .sad:     return "\(dna.name) misses running..."
        case .running: return "\(dna.name) is on the move!"
        case .jump:    return "\(dna.name) is jumping for joy!"
        case .dead:    return "Oh no... \(dna.name) is resting."
        case .hurt:    return "\(dna.name) took a hit. Don't miss more days!"
        }
    }
}

// MARK: - Pose button component
private struct PoseButton: View {
    let pose: PetPose
    let isActive: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(pose.emoji)
                    .font(.system(size: 20))
                Text(pose.label)
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular, design: .rounded))
                    .foregroundStyle(isActive ? accentColor : Color(hex: "#9AA5B4"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isActive ? accentColor.opacity(0.1) : Color(hex: "#F5F7FA"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isActive ? accentColor.opacity(0.4) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environment({
            let s = AppState()
            s.selectedCharacter = PetDNA.presets()[0]
            return s
        }())
}
