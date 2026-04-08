import SwiftUI
import SwiftData

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @Query private var saved: [SavedCharacter]

    @State private var randomDNA: PetDNA = PetDNA.random()
    private var dna: PetDNA { saved.first?.dna ?? randomDNA }

    @State private var petAppeared = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                VStack(spacing: 0) {
                    // Flexible top spacer (replaces topBar + energySection + phraseSection)
                    Spacer()

                    // Logo centered above the pet
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)

                    Spacer().frame(height: 28)

                    // Pet — anchored at same position as HomeView
                    PetAnimationView(dna: dna, pose: appState.medalEarned ? .idle : .running, pixelSize: 9.07,
                                     accessories: appState.medalEarned ? [.medal66] : [])
                        .opacity(petAppeared ? 1 : 0)
                        .scaleEffect(petAppeared ? 1 : 0.85)
                        .animation(.spring(duration: 0.55, bounce: 0.25).delay(0.2), value: petAppeared)

                    // Fixed bottom anchor matching HomeView's km + pill + spacers
                    Color.clear.frame(height: geo.size.height * 0.25 - 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { AppBackground(imageName: appState.selectedBackground) }
        .onAppear {
            petAppeared = true
        }
    }
}

#Preview {
    SplashView()
}
