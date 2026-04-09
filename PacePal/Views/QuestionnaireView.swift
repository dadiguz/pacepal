import SwiftUI

// MARK: - Data

private struct Question {
    let key: String
    let answers: [String]
}

private let questions: [Question] = [
    Question(key: "q1.question", answers: ["q1.a", "q1.b", "q1.c"]),
    Question(key: "q2.question", answers: ["q2.a", "q2.b", "q2.c"]),
    Question(key: "q3.question", answers: ["q3.a", "q3.b", "q3.c"]),
    Question(key: "q4.question", answers: ["q4.a", "q4.b", "q4.c"]),
]

// Score: option A=0, B=1, C=2. Total 0-2→habito, 3-5→resistencia, 6-8→rendimiento
private func computeLevel(_ answers: [Int]) -> ChallengeLevel {
    let total = answers.reduce(0, +)
    switch total {
    case 0...2: return .habito
    case 3...5: return .resistencia
    default:    return .rendimiento
    }
}

// MARK: - QuestionnaireView

struct QuestionnaireView: View {
    @Environment(AppState.self) private var appState

    // -1 = intro, 0-3 = questions, 4 = result
    @State private var step = -1
    @State private var answers: [Int] = []
    @State private var selectedOption: Int? = nil
    @State private var pickedLevel: ChallengeLevel? = nil
    @State private var appeared = false

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }
    private var recommendedLevel: ChallengeLevel { computeLevel(answers) }
    private var finalLevel: ChallengeLevel { pickedLevel ?? recommendedLevel }

    var body: some View {
        Group {
            if step == -1 {
                introPage
                    .transition(.opacity)
            } else if step < questions.count {
                questionPage(index: step)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id("q\(step)")
            } else {
                resultPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal:   .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: step)
        .onAppear { appeared = true }
    }

    // MARK: - Intro page (matches NotificationPermissionView style)

    private var introPage: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                // Pet stage
                ZStack {
                    Circle()
                        .fill(Color(hex: "#F9703E").opacity(0.07))
                        .frame(width: 200, height: 200)
                        .blur(radius: 28)

                    ExcitedTeachingPet(dna: dna, appeared: appeared)
                }
                .frame(height: 180)
                .padding(.top, 32)
                .padding(.bottom, 24)

                // Text content
                VStack(spacing: 16) {
                    (
                        Text(L("q.intro_title_part1"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1F2933"))
                        + Text(L("q.intro_title_highlight"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#F9703E"))
                        + Text(L("q.intro_title_part2"))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1F2933"))
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                    Text(L("q.intro_subtitle"))
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(Color(hex: "#52606D"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        withAnimation { step = 0 }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                                .font(.system(size: 15))
                            Text(L("q.intro_cta"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
                    }

                    Button {
                        appState.completeQuestionnaire(level: .habito)
                    } label: {
                        Text(L("q.skip"))
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#9AA5B4"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.3), value: appeared)
            }
        }
    }

    // MARK: - Question page (pattern background)

    private func questionPage(index: Int) -> some View {
        let q = questions[index]
        return GeometryReader { geo in
            ZStack {
                Color(hex: "#F9F496")

                Image("pattern")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.3)

                VStack(spacing: 0) {
                    // Progress dots — pinned to top
                    HStack(spacing: 7) {
                        ForEach(0..<questions.count, id: \.self) { i in
                            Circle()
                                .fill(i <= index ? Color(hex: "#F9703E") : Color(hex: "#1F2933").opacity(0.20))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 60)

                    Spacer()

                    // ── Centered content container ──────────────────────
                    VStack(spacing: 24) {
                        // Question title
                        Text(L(q.key))
                            .font(.system(size: 26, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.55), radius: 0, x: 1, y: 1)
                            .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)

                        // Answer options
                        VStack(spacing: 12) {
                            ForEach(Array(q.answers.enumerated()), id: \.offset) { idx, key in
                                let isSelected = selectedOption == idx
                                Button {
                                    withAnimation(.spring(duration: 0.2)) { selectedOption = idx }
                                } label: {
                                    ZStack(alignment: .trailing) {
                                        Text(L(key))
                                            .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .rounded))
                                            .foregroundStyle(.white)
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .padding(.horizontal, 36)
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundStyle(Color(hex: "#F9703E"))
                                                .padding(.trailing, 18)
                                        }
                                    }
                                    .padding(.vertical, 20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color(hex: "#2B2420"))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .strokeBorder(
                                                        isSelected ? Color(hex: "#F9703E") : Color.white.opacity(0.18),
                                                        lineWidth: isSelected ? 1.5 : 1
                                                    )
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    // Navigation buttons — pinned to bottom
                    VStack(spacing: 10) {
                        Button {
                            guard let opt = selectedOption else { return }
                            if answers.count > index { answers[index] = opt } else { answers.append(opt) }
                            withAnimation { selectedOption = nil; step += 1 }
                        } label: {
                            Text(index == questions.count - 1 ? L("q.done") : L("q.next"))
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(selectedOption != nil ? Color(hex: "#F9703E") : Color(hex: "#F9703E").opacity(0.35))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color(hex: "#F9703E").opacity(selectedOption != nil ? 0.4 : 0), radius: 12, y: 5)
                        }
                        .disabled(selectedOption == nil)

                        Button {
                            withAnimation {
                                if index > 0 {
                                    step -= 1
                                    selectedOption = answers.count > step ? answers[step] : nil
                                } else {
                                    step = -1
                                }
                            }
                        } label: {
                            Text(L("q.back"))
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(hex: "#1F2933").opacity(0.55))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 52)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    // MARK: - Result page (pattern background)

    @State private var showLevelPicker = false

    private var resultPage: some View {
        GeometryReader { geo in
            ZStack {
                Color(hex: "#F9F496")

                Image("pattern")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.3)

                VStack(spacing: 0) {
                    Spacer()

                    // Badge
                    Text(L("q.result_badge"))
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color(hex: "#F9703E"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Color(hex: "#F9703E").opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color(hex: "#F9703E").opacity(0.3), lineWidth: 1))
                        .padding(.bottom, 20)

                    // Level card (dark, like DailyTipModal)
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: finalLevel.icon)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(finalLevel.color)
                            Text(finalLevel.label)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text(finalLevel.subtitle)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(finalLevel.color)
                        Text(L("q.result_body_\(finalLevel.rawValue)"))
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#2B2420"))
                            .overlay(RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.white.opacity(0.78), lineWidth: 1.5))
                            .shadow(color: Color.black.opacity(0.25), radius: 12, y: 4)
                    )
                    .padding(.horizontal, 24)

                    // Change level
                    Button { showLevelPicker = true } label: {
                        Label(L("q.result_change"), systemImage: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1F2933").opacity(0.55))
                            .padding(.vertical, 14)
                    }
                    .sheet(isPresented: $showLevelPicker) {
                        QuestionnairePickerSheet(selected: $pickedLevel)
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    }

                    Spacer()

                    // Confirm
                    Button { appState.completeQuestionnaire(level: finalLevel) } label: {
                        Text(L("q.result_confirm"))
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#F9703E"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color(hex: "#F9703E").opacity(0.4), radius: 12, y: 5)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 56)
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Level picker sheet (used on result page)

private struct QuestionnairePickerSheet: View {
    @Binding var selected: ChallengeLevel?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text(L("q.result_change"))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
                .padding(.top, 28)
                .padding(.bottom, 20)

            VStack(spacing: 8) {
                ForEach(ChallengeLevel.allCases, id: \.rawValue) { level in
                    let isSelected = (selected ?? computeLevel([])) == level
                    Button {
                        selected = level
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: level.icon)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(level.color)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.label)
                                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(Color(hex: "#1F2933"))
                                Text(level.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(hex: "#9AA5B4"))
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(Color(hex: "#F9703E"))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(isSelected ? Color(hex: "#F9703E").opacity(0.5) : Color(hex: "#E2E8F0"),
                                              lineWidth: isSelected ? 1.5 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(Color(hex: "#F5F8FC").ignoresSafeArea())
    }
}

// MARK: - Excited teaching pet with yellow pencil highlight

private struct ExcitedTeachingPet: View {
    let dna: PetDNA
    let appeared: Bool
    @State private var bob = false

    var body: some View {
        ZStack {
            PetAnimationView(dna: dna, pose: .teaching, pixelSize: 9, fps: 4)
                // Yellow pencil accent overlay (small dot over the pencil area)
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color(hex: "#FADB5F"))
                        .frame(width: 9, height: 9)
                        .offset(x: -12, y: -18)
                        .opacity(0.9)
                }
                .offset(y: bob ? -6 : 0)
                .animation(
                    appeared
                        ? .easeInOut(duration: 0.55).repeatForever(autoreverses: true)
                        : .default,
                    value: bob
                )
        }
        .scaleEffect(appeared ? 1 : 0.8)
        .opacity(appeared ? 1 : 0)
        .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)
        .onAppear { bob = true }
    }
}
