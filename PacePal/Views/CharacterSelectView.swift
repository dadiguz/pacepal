import SwiftUI
import SwiftData

private let maxNicknameLength = 10

struct CharacterSelectView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @State private var characters: [PetDNA] = {
        let anchor = PetDNA.presets()[0]   // smooth/ghost — always first
        var list = [anchor]
        var prevType = anchor.animalType
        for _ in 1..<8 {
            var pet = PetDNA.random()
            var tries = 0
            while pet.animalType == prevType && tries < 15 { pet = PetDNA.random(); tries += 1 }
            list.append(pet)
            prevType = pet.animalType
        }
        return list
    }()
    @State private var selectedIndex: Int = 0

    // Naming state
    @State private var isNaming      = false
    @State private var nickname      = ""
    @State private var namingPose    = PetPose.jump
    @State private var showNameError = false
    @FocusState private var keyboardUp: Bool
    @State private var glowPulse = false
    @State private var glowAngle: Double = 0
    @State private var glowAngle2: Double = 0

    private var selected: PetDNA { characters[selectedIndex] }
    private var bodyColor: Color { Color(hex: selected.palette.body) }
    private var accentColor: Color { Color(hex: selected.palette.accent1) }

    private let heroPx: CGFloat = 9.07
    private var heroSize: CGFloat { heroPx * CGFloat(GRID_SIZE) }
    private var footOffsetFromBottom: CGFloat { heroPx * 3 }

    var body: some View {
        ZStack {
            AppBackground()

            // ── Normal selection screen ────────────────────────────────────
            if !isNaming {
                VStack(spacing: 0) {
                    header.padding(.top, 56)

                    Spacer()

                    heroSection

                    if !selected.name.isEmpty {
                        Text(selected.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: "#1F2933"))
                            .animation(.none, value: selectedIndex)
                            .padding(.top, 16)
                    }

                    // Animal type pill
                    Text(animalLabel.uppercased())
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(bodyColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(bodyColor.opacity(0.12))
                        .clipShape(Capsule())
                        .padding(.top, selected.name.isEmpty ? 16 : 6)
                        .animation(.none, value: selectedIndex)

                    // Tagline
                    Text("Te acompañará en cada kilómetro")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: "#B0A8A0"))
                        .padding(.top, 4)

                    Spacer()

                    characterStrip.padding(.bottom, 8)
                    pageDots.padding(.bottom, 28)

                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, 48)
                }
                .transition(.opacity)
            }

            // ── Naming screen ──────────────────────────────────────────────
            if isNaming {
                namingScreen
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isNaming)
    }

    // MARK: – Naming screen

    private var namingScreen: some View {
        ZStack(alignment: .topLeading) {
            // Back arrow
            Button {
                keyboardUp = false
                withAnimation { isNaming = false }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                    .padding(12)
                    .background(Color(hex: "#F0EBE6"))
                    .clipShape(Circle())
            }
            .padding(.top, 56)
            .padding(.leading, 24)

        VStack(spacing: 0) {
            Spacer()

            // Pet hero (same as normal, slightly smaller)
            ZStack {
                Circle()
                    .fill(bodyColor.opacity(0.07))
                    .frame(width: heroSize * 0.85, height: heroSize * 0.85)
                    .blur(radius: 20)

                ZStack(alignment: .bottom) {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [bodyColor.opacity(0.40), .clear],
                            center: .center, startRadius: 0, endRadius: 60
                        ))
                        .frame(width: 120, height: 22)
                        .blur(radius: 12)
                        .padding(.bottom, footOffsetFromBottom - 8)

                    PetAnimationView(dna: selected, pose: namingPose, pixelSize: heroPx)
                        .id(selected.id)
                }
            }

            Spacer().frame(height: 28)

            // Prompt
            Text("¿Cómo se llama tu compañero?")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
            Text(showNameError ? "¡Necesita un nombre!" : "Máximo \(maxNicknameLength) letras")
                .font(.system(size: 13, weight: showNameError ? .semibold : .regular, design: .rounded))
                .foregroundStyle(showNameError ? Color(hex: "#E12D39") : Color(hex: "#9AA5B4"))
                .padding(.top, 4)
                .animation(.easeInOut(duration: 0.2), value: showNameError)

            Spacer().frame(height: 32)

            // ── Slot display ────────────────────────────────────────────────
            nicknameSlots

            // Hidden text field that captures input
            TextField("", text: $nickname)
                .focused($keyboardUp)
                .frame(width: 1, height: 1)
                .opacity(0.001)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onChange(of: nickname) { _, new in
                    // Strip to letters/numbers/spaces, max length
                    let filtered = String(
                        new.filter { $0.isLetter || $0.isNumber || $0 == " " }
                            .prefix(maxNicknameLength)
                    )
                    if filtered != new { nickname = filtered }
                }

            Spacer().frame(height: 32)

            // ── Buttons ─────────────────────────────────────────────────────
            Button { confirmNickname() } label: {
                Text("Confirmar")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#F9703E"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        } // VStack
        } // ZStack
        .onAppear {
            nickname = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                keyboardUp = true
            }
        }
    }

    // MARK: – Nickname slots

    private var nicknameSlots: some View {
        let chars = Array(nickname)
        return HStack(spacing: 10) {
            ForEach(0..<maxNicknameLength, id: \.self) { i in
                let isFilled  = i < chars.count
                let isCursor  = i == chars.count && chars.count < maxNicknameLength
                VStack(spacing: 6) {
                    Text(isFilled ? String(chars[i]) : " ")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#1F2933"))
                        .frame(width: 22, height: 26)

                    Rectangle()
                        .fill(
                            isCursor ? Color(hex: "#F9703E") :
                            isFilled ? Color(hex: "#1F2933") :
                                       Color(hex: "#CBD2D9")
                        )
                        .frame(height: isCursor ? 2.5 : 1.5)
                        .animation(.easeInOut(duration: 0.12), value: nickname.count)
                }
                .frame(width: 22)
            }
        }
        .padding(.horizontal, 24)
        .onTapGesture { keyboardUp = true }
    }

    // MARK: – Confirm

    private func confirmNickname() {
        let trimmed = nickname.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            // Angry flash: switch to angry pose then back to jump
            showNameError = true
            namingPose = .angry
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                namingPose = .jump
                withAnimation { showNameError = false }
            }
            return
        }
        var namedDNA = selected
        namedDNA.name = trimmed
        characters[selectedIndex] = namedDNA
        keyboardUp = false
        saveAndSelect(namedDNA)
    }

    private func saveAndSelect(_ dna: PetDNA) {
        saveCharacter(dna)
        appState.onCharacterSelected()
        withAnimation(.spring(duration: 0.4)) {
            appState.selectedCharacter = dna
        }
    }

    // MARK: – Animal type label

    private var animalLabel: String { selected.animalType.archetypeLabel }

    // MARK: – Header

    private var header: some View {
        VStack(spacing: 6) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 50)
            Text("Elige tu compañero de 66 días")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
        }
    }

    // MARK: – Hero

    private var heroSection: some View {
        ZStack {
            // Outer ambient glow — ellipse rotates slowly like light orbiting
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [bodyColor.opacity(0.28), accentColor.opacity(0.10), .clear],
                        center: .center, startRadius: 0, endRadius: heroSize * 0.7
                    )
                )
                .frame(width: heroSize * 1.7, height: heroSize * 1.1)
                .blur(radius: 26)
                .rotationEffect(.degrees(glowAngle))
                .scaleEffect(glowPulse ? 1.12 : 0.90)
                .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true), value: glowPulse)
                .animation(nil, value: selectedIndex)

            // Accent glow — counter-rotates at different speed
            Ellipse()
                .fill(accentColor.opacity(glowPulse ? 0.26 : 0.08))
                .frame(width: heroSize * 0.85, height: heroSize * 0.55)
                .blur(radius: 20)
                .rotationEffect(.degrees(-glowAngle2))
                .offset(x: heroSize * 0.12, y: heroSize * 0.08)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: glowPulse)
                .animation(nil, value: selectedIndex)

            ZStack(alignment: .bottom) {
                // Ground shadow
                Ellipse()
                    .fill(RadialGradient(
                        colors: [bodyColor.opacity(0.50), .clear],
                        center: .center, startRadius: 0, endRadius: 70
                    ))
                    .frame(width: 150, height: 28)
                    .blur(radius: 14)
                    .padding(.bottom, footOffsetFromBottom - 8)

                PetAnimationView(dna: selected, pose: .idle, pixelSize: heroPx)
                    .id(selected.id)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: selectedIndex)
        .onAppear {
            glowPulse = true
            withAnimation(.linear(duration: 5.5).repeatForever(autoreverses: false)) {
                glowAngle = 360
            }
            withAnimation(.linear(duration: 8.5).repeatForever(autoreverses: false)) {
                glowAngle2 = 360
            }
        }
    }

    // MARK: – Carousel

    private var characterStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(characters.enumerated()), id: \.element.id) { i, dna in
                        PetPreviewCard(dna: dna, isSelected: i == selectedIndex, size: 72)
                            .id(i)
                            .onTapGesture {
                                withAnimation(.spring(duration: 0.3)) { selectedIndex = i }
                            }
                    }
                }
                .padding(.horizontal, 24)
            }
            .onChange(of: selectedIndex) { _, new in
                withAnimation { proxy.scrollTo(new, anchor: .center) }
            }
        }
        .frame(height: 128)
    }

    // MARK: – Page dots

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<characters.count, id: \.self) { i in
                Circle()
                    .fill(i == selectedIndex ? bodyColor : Color(hex: "#CBD2D9"))
                    .frame(width: i == selectedIndex ? 8 : 5,
                           height: i == selectedIndex ? 8 : 5)
                    .animation(.spring(duration: 0.25), value: selectedIndex)
            }
        }
    }

    // MARK: – Action buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    let leftType  = selectedIndex > 0                    ? characters[selectedIndex - 1].animalType : nil
                    let rightType = selectedIndex < characters.count - 1 ? characters[selectedIndex + 1].animalType : nil
                    var pet = PetDNA.random()
                    var tries = 0
                    while (pet.animalType == leftType || pet.animalType == rightType) && tries < 20 {
                        pet = PetDNA.random(); tries += 1
                    }
                    characters[selectedIndex] = pet
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "shuffle")
                    Text("Generar")
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white)
                .foregroundStyle(Color(hex: "#F9703E"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(hex: "#F9703E"), lineWidth: 1.5))
            }

            Button {
                withAnimation { isNaming = true }
            } label: {
                Text("Seleccionar")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#F9703E"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    // MARK: – Persistence

    private func saveCharacter(_ dna: PetDNA) {
        saved.forEach { modelContext.delete($0) }
        if let data = try? JSONEncoder().encode(dna) {
            modelContext.insert(SavedCharacter(dnaData: data))
        }
    }
}

#Preview {
    CharacterSelectView()
        .environment(AppState())
}
