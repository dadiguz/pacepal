import SwiftUI
import SwiftData

struct CharacterSelectView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @State private var characters: [PetDNA] = PetDNA.presets()
    @State private var selectedIndex: Int = 0

    private var selected: PetDNA { characters[selectedIndex] }
    private var bodyColor: Color { Color(hex: selected.palette.body) }

    // Hero pixel size: fills ~260pt width
    private let heroPx: CGFloat = 10
    private var heroSize: CGFloat { heroPx * CGFloat(GRID_SIZE) }
    // Feet are at ~row 21/24 → distance from canvas bottom = 3 rows
    private var footOffsetFromBottom: CGFloat { heroPx * 3 }

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            VStack(spacing: 0) {
                header.padding(.top, 56)

                Spacer()

                // ── Hero ────────────────────────────────────────────────────
                ZStack {
                    // Background atmosphere glow
                    Circle()
                        .fill(bodyColor.opacity(0.07))
                        .frame(width: heroSize, height: heroSize)
                        .blur(radius: 20)

                    // Character + foot shadow stacked
                    ZStack(alignment: .bottom) {
                        // Foot glow/shadow
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [bodyColor.opacity(0.50), .clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 150, height: 28)
                            .blur(radius: 14)
                            .padding(.bottom, footOffsetFromBottom - 8)

                        PetAnimationView(dna: selected, pose: .happy, pixelSize: heroPx)
                            .id(selected.id)
                            .transition(.scale(scale: 0.85).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.35), value: selectedIndex)

                // Name only — no type label
                Text(selected.name)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                    .animation(.none, value: selectedIndex)
                    .padding(.top, 16)

                Spacer()

                // ── Carousel ─────────────────────────────────────────────────
                characterStrip.padding(.bottom, 8)

                pageDots.padding(.bottom, 28)

                // ── Actions ──────────────────────────────────────────────────
                HStack(spacing: 12) {
                    // Generate
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            characters[selectedIndex] = PetDNA.random()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "shuffle")
                            Text("Generate")
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#EDF0F4"))
                        .foregroundStyle(Color(hex: "#3E4C59"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Select
                    Button {
                        saveCharacter(selected)
                        withAnimation(.spring(duration: 0.4)) {
                            appState.selectedCharacter = selected
                        }
                    } label: {
                        Text("Select")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(bodyColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: – Header
    private var header: some View {
        VStack(spacing: 4) {
            Text("PacePal")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
            Text("Choose your running buddy")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
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
                                withAnimation(.spring(duration: 0.3)) {
                                    selectedIndex = i
                                }
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

    // MARK: – Persistence
    private func saveCharacter(_ dna: PetDNA) {
        saved.forEach { modelContext.delete($0) }
        if let data = try? JSONEncoder().encode(dna) {
            modelContext.insert(SavedCharacter(dnaData: data))
        }
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
}

#Preview {
    CharacterSelectView()
        .environment(AppState())
}
