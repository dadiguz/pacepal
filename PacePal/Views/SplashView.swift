import SwiftUI
import SwiftData

struct SplashView: View {
    @Query private var saved: [SavedCharacter]

    // Fallback if nothing is saved yet
    @State private var randomDNA: PetDNA = PetDNA.random()

    private var dna: PetDNA { saved.first?.dna ?? randomDNA }

    @State private var appeared = false
    @State private var textScale: CGFloat = 0.85

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Running character — pixel size 13 → 312pt canvas
                PetAnimationView(dna: dna, pose: .running, pixelSize: 13)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.8)

                Spacer().frame(height: 32)

                // PACEPAL logotype
                Text("PACEPAL")
                    .font(.system(size: 40, weight: .black, design: .monospaced))
                    .tracking(6)
                    .foregroundStyle(Color(hex: "#1F2933"))
                    .scaleEffect(textScale)
                    .opacity(appeared ? 1 : 0)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.3)) {
                appeared = true
                textScale = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
