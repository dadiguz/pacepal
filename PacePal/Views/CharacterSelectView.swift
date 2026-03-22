import SwiftUI

struct CharacterSelectView: View {
    @Environment(AppState.self) private var appState

    // 6 preset characters always shown; user can also roll random
    @State private var characters: [PetDNA] = PetDNA.presets()
    @State private var selectedIndex: Int = 0
    @State private var dragOffset: CGFloat = 0

    private var selected: PetDNA { characters[selectedIndex] }

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 56)

                Spacer()

                // Large hero character
                ZStack {
                    // Background glow matching palette
                    Circle()
                        .fill(Color(hex: selected.palette.body).opacity(0.08))
                        .frame(width: 240, height: 240)

                    PetAnimationView(dna: selected, pose: .happy, pixelSize: 10)
                        .id(selected.id)       // forces redraw on selection change
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                .animation(.spring(duration: 0.35), value: selectedIndex)

                // Name + type badge
                VStack(spacing: 6) {
                    Text(selected.name)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                        .animation(.none, value: selectedIndex)

                    Text(selected.animalType.rawValue.uppercased())
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: selected.palette.body))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(hex: selected.palette.body).opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding(.top, 16)
                .animation(.easeInOut(duration: 0.2), value: selectedIndex)

                Spacer()

                // Character carousel strip
                characterStrip
                    .padding(.bottom, 8)

                // Page dots
                pageDots
                    .padding(.bottom, 32)

                // Roll random
                Button {
                    characters[selectedIndex] = PetDNA.random()
                } label: {
                    Label("Shuffle", systemImage: "shuffle")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#616E7C"))
                }
                .padding(.bottom, 24)

                // Choose CTA
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        appState.selectedCharacter = selected
                    }
                } label: {
                    Text("Choose \(selected.name)")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: – Header
    private var header: some View {
        VStack(spacing: 6) {
            Text("PacePal")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))

            Text("Choose your running buddy")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color(hex: "#616E7C"))
        }
    }

    // MARK: – Carousel strip
    private var characterStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
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
        .frame(height: 130)
    }

    // MARK: – Page dots
    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<characters.count, id: \.self) { i in
                Circle()
                    .fill(i == selectedIndex ? Color(hex: "#F9703E") : Color(hex: "#CBD2D9"))
                    .frame(width: i == selectedIndex ? 8 : 5, height: i == selectedIndex ? 8 : 5)
                    .animation(.spring(duration: 0.25), value: selectedIndex)
            }
        }
    }
}

#Preview {
    CharacterSelectView()
        .environment(AppState())
}
