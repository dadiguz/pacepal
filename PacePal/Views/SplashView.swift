import SwiftUI
import SwiftData

struct SplashView: View {
    @Environment(AppState.self) private var appState
    @Query private var saved: [SavedCharacter]

    @State private var randomDNA: PetDNA = PetDNA.random()
    private var dna: PetDNA { saved.first?.dna ?? randomDNA }

    @State private var petAppeared = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()

                // Pet fades in after logo is already visible
                PetAnimationView(dna: dna, pose: .running, pixelSize: 9.07)
                    .opacity(petAppeared ? 1 : 0)
                    .scaleEffect(petAppeared ? 1 : 0.85)
                    .animation(.spring(duration: 0.55, bounce: 0.25).delay(0.2), value: petAppeared)

                Spacer().frame(height: 28)

                // Logo always visible immediately — no animation delay
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)

                Spacer()
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
