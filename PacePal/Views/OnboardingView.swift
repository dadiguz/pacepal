import SwiftUI

// MARK: - Step enum

private enum OnboardingStep: Int, CaseIterable {
    case welcome, goal, pain, socialProof, tinder, solution, processing
}

// MARK: - Data models

private struct GoalOption: Identifiable {
    let id = UUID()
    let symbol: String
    let key: String
    var text: String { L(key) }
}

private let goalOptions: [GoalOption] = [
    .init(symbol: "figure.run",          key: "ob.goal_1"),
    .init(symbol: "bolt.fill",           key: "ob.goal_2"),
    .init(symbol: "trophy.fill",         key: "ob.goal_3"),
    .init(symbol: "brain.head.profile",  key: "ob.goal_4"),
    .init(symbol: "heart.fill",          key: "ob.goal_5"),
]

private struct PainOption: Identifiable {
    let id = UUID()
    let symbol: String
    let key: String
    var text: String { L(key) }
}

private let painOptions: [PainOption] = [
    .init(symbol: "moon.zzz.fill",            key: "ob.pain_1"),
    .init(symbol: "arrow.counterclockwise",   key: "ob.pain_2"),
    .init(symbol: "questionmark.circle.fill", key: "ob.pain_3"),
    .init(symbol: "person.2.slash.fill",      key: "ob.pain_4"),
    .init(symbol: "clock.fill",               key: "ob.pain_5"),
]

private struct Testimonial: Identifiable {
    let id = UUID()
    let nameKey: String
    let badgeSymbol: String
    let badgeKey: String
    let textKey: String
    var name: String  { L(nameKey) }
    var badge: String { L(badgeKey) }
    var text: String  { L(textKey) }
}

private let testimonials: [Testimonial] = [
    .init(nameKey: "ob.proof_1_name", badgeSymbol: "figure.run",
          badgeKey: "ob.proof_1_badge", textKey: "ob.proof_1_text"),
    .init(nameKey: "ob.proof_2_name", badgeSymbol: "bolt.fill",
          badgeKey: "ob.proof_2_badge", textKey: "ob.proof_2_text"),
    .init(nameKey: "ob.proof_3_name", badgeSymbol: "heart.fill",
          badgeKey: "ob.proof_3_badge", textKey: "ob.proof_3_text"),
]

private let tinderCardKeys: [String] = [
    "ob.tinder_1", "ob.tinder_2", "ob.tinder_3", "ob.tinder_4",
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var step: OnboardingStep = .welcome
    @State private var appeared = false

    // Goal
    @State private var selectedGoal: Int? = nil

    // Pain
    @State private var selectedPains: Set<Int> = []

    // Tinder
    @State private var tinderIndex = 0
    @State private var dragOffset: CGSize = .zero
    private var tinderCards: [String] { tinderCardKeys.map { L($0) } }

    private let accent = Color(hex: "#F9703E")
    private let dark   = Color(hex: "#1F2933")
    private let muted  = Color(hex: "#9AA5B4")

    private var progress: Double {
        let barSteps: [OnboardingStep] = [.goal, .pain, .socialProof, .tinder, .solution]
        guard let barIdx = barSteps.firstIndex(of: step) else { return step == .processing ? 1 : 0 }
        return Double(barIdx + 1) / Double(barSteps.count)
    }

    var body: some View {
        ZStack {
            AppBackground()

            // Sound toggle — welcome only
            if step == .welcome {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            appState.soundsEnabled.toggle()
                            if appState.soundsEnabled {
                                SoundManager.shared.playMusic(name: "pacepal", enabled: true)
                            } else {
                                SoundManager.shared.stopMusic(fadeDuration: 0.4)
                            }
                        } label: {
                            Image(systemName: appState.soundsEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(muted)
                                .padding(10)
                                .background(Color(hex: "#F5ECE4"))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 24)
                        .padding(.top, 56)
                    }
                    Spacer()
                }
                .zIndex(1)
                .transition(.opacity)
            }

            VStack(spacing: 0) {
                if step != .welcome && step != .processing {
                    progressBar
                        .padding(.top, 60)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }

                ZStack {
                    switch step {
                    case .welcome:     welcomeView.id("welcome")
                    case .goal:        goalView.id("goal")
                    case .pain:        painView.id("pain")
                    case .socialProof: socialProofView.id("social")
                    case .tinder:      tinderView.id("tinder")
                    case .solution:    solutionView.id("solution")
                    case .processing:  processingView.id("processing")
                    }
                }
                .animation(.spring(duration: 0.45), value: step)
            }
        }
        .onAppear {
            appeared = true
            SoundManager.shared.playMusic(name: "pacepal", enabled: appState.soundsEnabled)
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.07)).frame(height: 4)
                Capsule().fill(accent)
                    .frame(width: geo.size.width * progress, height: 4)
                    .animation(.spring(duration: 0.5), value: progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Welcome

    private var welcomeView: some View {
        VStack(spacing: 0) {
            Image("Logo")
                .resizable().scaledToFit().frame(height: 44)
                .padding(.top, 56)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.35), value: appeared)

            Spacer()

            ZStack {
                Text("66")
                    .font(.system(size: 160, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [accent, Color(hex: "#FFAD80")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .opacity(0.09)

                Ellipse()
                    .fill(RadialGradient(
                        colors: [accent.opacity(0.28), .clear],
                        center: .center, startRadius: 0, endRadius: 60
                    ))
                    .frame(width: 140, height: 22).blur(radius: 12).offset(y: 46)

                PetAnimationView(dna: PetDNA.presets()[0], pose: .running, pixelSize: 10)
                    .scaleEffect(appeared ? 1 : 0.85)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.55, bounce: 0.25).delay(0.15), value: appeared)
            }
            .frame(height: 200)

            Spacer().frame(height: 36)

            VStack(spacing: 10) {
                Text(L("ob.welcome_title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(dark).multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 10)
                    .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                Text(L("ob.welcome_sub"))
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundStyle(muted)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.3), value: appeared)
            }
            .padding(.horizontal, 32)

            Spacer()

            ctaButton(L("ob.start"), enabled: true) { advance() }
                .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 10)
                .animation(.spring(duration: 0.45).delay(0.38), value: appeared)
                .padding(.bottom, 48)
        }
    }

    // MARK: - Goal

    private var goalView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)

            Text(L("ob.goal_title"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(dark).padding(.horizontal, 24)
            Text(L("ob.goal_sub"))
                .font(.system(size: 15, design: .rounded)).foregroundStyle(muted)
                .padding(.horizontal, 24).padding(.top, 6)

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                ForEach(Array(goalOptions.enumerated()), id: \.offset) { i, option in
                    selectRow(symbol: option.symbol, text: option.text,
                              selected: selectedGoal == i, multiSelect: false) {
                        selectedGoal = i
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            ctaButton(L("ob.continue"), enabled: selectedGoal != nil) { advance() }
                .padding(.bottom, 48)
        }
    }

    // MARK: - Pain

    private var painView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 24)

            Text(L("ob.pain_title"))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(dark).padding(.horizontal, 24)
            Text(L("ob.pain_sub"))
                .font(.system(size: 15, design: .rounded)).foregroundStyle(muted)
                .padding(.horizontal, 24).padding(.top, 6)

            Spacer().frame(height: 24)

            VStack(spacing: 12) {
                ForEach(Array(painOptions.enumerated()), id: \.offset) { i, option in
                    selectRow(symbol: option.symbol, text: option.text,
                              selected: selectedPains.contains(i), multiSelect: true) {
                        if selectedPains.contains(i) { selectedPains.remove(i) }
                        else { selectedPains.insert(i) }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            ctaButton(L("ob.continue"), enabled: true) { advance() }
                .padding(.bottom, 48)
        }
    }

    // MARK: - Social Proof

    private var socialProofView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 6) {
                Text(L("ob.proof_title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(dark)
                Text(L("ob.proof_sub"))
                    .font(.system(size: 15, design: .rounded)).foregroundStyle(muted)
            }
            .multilineTextAlignment(.center).padding(.horizontal, 24)

            Spacer().frame(height: 24)

            VStack(spacing: 14) {
                ForEach(testimonials) { t in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(t.name)
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundStyle(dark)
                                HStack(spacing: 5) {
                                    Image(systemName: t.badgeSymbol)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(accent)
                                    Text(t.badge)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(accent)
                                }
                            }
                            Spacer()
                            HStack(spacing: 2) {
                                ForEach(0..<5, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10)).foregroundStyle(accent)
                                }
                            }
                        }
                        Text(t.text)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color(hex: "#486581"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            ctaButton(L("ob.continue"), enabled: true) { advance() }
                .padding(.bottom, 48)
        }
    }

    // MARK: - Tinder cards

    private var tinderView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 6) {
                Text(L("ob.tinder_title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(dark)
                Text(L("ob.tinder_sub"))
                    .font(.system(size: 15, design: .rounded)).foregroundStyle(muted)
            }
            .multilineTextAlignment(.center).padding(.horizontal, 24)

            Spacer()

            if tinderIndex < tinderCards.count {
                ZStack {
                    if tinderIndex + 1 < tinderCards.count {
                        tinderCardView(tinderCards[tinderIndex + 1], offset: .zero, rotation: 0)
                            .scaleEffect(0.93).offset(y: 12)
                    }

                    tinderCardView(tinderCards[tinderIndex], offset: dragOffset,
                                   rotation: dragOffset.width / 18)
                    .gesture(
                        DragGesture()
                            .onChanged { dragOffset = $0.translation }
                            .onEnded { value in
                                if abs(value.translation.width) > 80 {
                                    flyOffAndAdvance(direction: value.translation.width > 0 ? 1 : -1)
                                } else {
                                    withAnimation(.spring()) { dragOffset = .zero }
                                }
                            }
                    )

                    HStack {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 44))
                            .foregroundStyle(.red)
                            .opacity(dragOffset.width < -40 ? Double(min(1, abs(dragOffset.width) / 80)) : 0)
                        Spacer()
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 44))
                            .foregroundStyle(.green)
                            .opacity(dragOffset.width > 40 ? Double(min(1, dragOffset.width / 80)) : 0)
                    }
                    .padding(.horizontal, 36)
                }
                .frame(height: 200)
                .padding(.horizontal, 24)

                Spacer().frame(height: 28)

                HStack(spacing: 16) {
                    Button { flyOffAndAdvance(direction: -1) } label: {
                        Label(L("ob.tinder_nope"), systemImage: "xmark")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(muted)
                            .padding(.horizontal, 22).padding(.vertical, 13)
                            .background(Color.white.opacity(0.7)).clipShape(Capsule())
                    }
                    Button { flyOffAndAdvance(direction: 1) } label: {
                        Label(L("ob.tinder_agree"), systemImage: "checkmark")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22).padding(.vertical, 13)
                            .background(accent).clipShape(Capsule())
                    }
                }

            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 40)).foregroundStyle(accent)
                    Text(L("ob.tinder_done"))
                        .font(.system(size: 24, weight: .bold, design: .rounded)).foregroundStyle(dark)
                    withPacepalOrange(L("ob.tinder_done_sub"))
                        .font(.system(size: 16, design: .rounded)).foregroundStyle(muted)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }

            Spacer()

            if tinderIndex >= tinderCards.count {
                ctaButton(L("ob.tinder_cta"), enabled: true) { advance() }
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: tinderIndex)
    }

    private func tinderCardView(_ text: String, offset: CGSize, rotation: Double) -> some View {
        Text("\"\(text)\"")
            .font(.system(size: 19, weight: .semibold, design: .rounded))
            .foregroundStyle(dark).multilineTextAlignment(.center)
            .padding(24).frame(maxWidth: .infinity).frame(height: 170)
            .background(Color.white.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.07), radius: 14, y: 5)
            .offset(offset).rotationEffect(.degrees(rotation))
    }

    private func flyOffAndAdvance(direction: Double) {
        withAnimation(.spring(duration: 0.28)) {
            dragOffset = CGSize(width: direction * 420, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            dragOffset = .zero
            withAnimation(.spring()) { tinderIndex += 1 }
        }
    }

    // MARK: - Solution

    private var solutionView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 6) {
                withPacepalOrange(L("ob.solution_title"))
                    .font(.system(size: 26, weight: .bold, design: .rounded)).foregroundStyle(dark)
                Text(L("ob.solution_sub"))
                    .font(.system(size: 15, design: .rounded)).foregroundStyle(muted)
            }
            .multilineTextAlignment(.center).padding(.horizontal, 24)

            Spacer().frame(height: 24)

            VStack(spacing: 13) {
                solutionRow(symbol: "pawprint.fill",     problem: L("ob.sol_1_prob"), solution: L("ob.sol_1_fix"))
                solutionRow(symbol: "calendar",          problem: L("ob.sol_2_prob"), solution: L("ob.sol_2_fix"))
                solutionRow(symbol: "gamecontroller.fill", problem: L("ob.sol_3_prob"), solution: L("ob.sol_3_fix"))
                solutionRow(symbol: "flag.checkered",    problem: L("ob.sol_4_prob"), solution: L("ob.sol_4_fix"))
            }
            .padding(.horizontal, 24)

            Spacer()

            ctaButton(L("ob.create_plan"), enabled: true) { advance() }
                .padding(.bottom, 48)
        }
    }

    private func solutionRow(symbol: String, problem: String, solution: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 36, height: 36)
                .background(accent.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(problem)
                    .font(.system(size: 12, design: .rounded)).foregroundStyle(muted)
                Text(solution)
                    .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(dark)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 28) {
                ZStack {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [accent.opacity(0.22), .clear],
                            center: .center, startRadius: 0, endRadius: 60
                        ))
                        .frame(width: 140, height: 22).blur(radius: 14).offset(y: 56)

                    PetAnimationView(dna: PetDNA.presets()[0], pose: .running, pixelSize: 12)
                }
                .frame(height: 200)

                VStack(spacing: 8) {
                    Text(L("ob.processing_title"))
                        .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(dark)
                    Text(L("ob.processing_sub"))
                        .font(.system(size: 15, design: .rounded)).foregroundStyle(muted)
                }
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            }

            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.completeOnboarding()
                }
            }
        }
    }

    // MARK: - Shared UI

    /// Renders a string with every occurrence of "Pacepal" in orange.
    private func withPacepalOrange(_ string: String) -> Text {
        let parts = string.components(separatedBy: "Pacepal")
        return parts.enumerated().reduce(Text("")) { result, item in
            let (i, part) = item
            let appended = result + Text(part)
            return i < parts.count - 1
                ? appended + Text("Pacepal").foregroundStyle(accent)
                : appended
        }
    }

    private func ctaButton(_ title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity).padding(.vertical, 18)
                .background(enabled ? accent : accent.opacity(0.35))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: enabled ? accent.opacity(0.35) : .clear, radius: 16, y: 6)
        }
        .disabled(!enabled)
        .padding(.horizontal, 24)
    }

    private func selectRow(symbol: String, text: String,
                           selected: Bool, multiSelect: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(selected ? accent : muted)
                    .frame(width: 32)
                Text(text)
                    .font(.system(size: 16,
                                  weight: selected ? .semibold : .regular,
                                  design: .rounded))
                    .foregroundStyle(selected ? accent : dark)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: multiSelect
                      ? (selected ? "checkmark.square.fill" : "square")
                      : (selected ? "checkmark.circle.fill" : "circle"))
                    .foregroundStyle(selected ? accent : muted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(selected ? accent.opacity(0.08) : Color.white.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(selected ? accent : Color.clear, lineWidth: 1.5))
        }
    }

    // MARK: - Navigation

    private func advance() {
        let all = OnboardingStep.allCases
        guard let idx = all.firstIndex(of: step), idx + 1 < all.count else { return }
        withAnimation(.spring(duration: 0.42)) { step = all[idx + 1] }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
