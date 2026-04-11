import SwiftUI

struct ForceUpdateView: View {
    @Environment(AppState.self) private var appState

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[1] }
    private var petName: String { appState.selectedCharacter?.name ?? "Tu compañero" }

    @State private var appeared = false
    @State private var shake = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Spacer()

                // Pet angry animation
                ZStack {
                    Circle()
                        .fill(Color(hex: "#F9703E").opacity(0.08))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    PetAnimationView(dna: dna, pose: .hurt, pixelSize: 9)
                        .frame(width: 140, height: 140)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .opacity(appeared ? 1 : 0)
                        .rotationEffect(.degrees(shake ? -3 : 3))
                        .animation(
                            .easeInOut(duration: 0.12).repeatForever(autoreverses: true),
                            value: shake
                        )
                        .animation(.spring(duration: 0.5, bounce: 0.4).delay(0.1), value: appeared)
                }

                Spacer().frame(height: 32)

                // Title
                Text(L("force_update.title", petName))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)
                    .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                Spacer().frame(height: 12)

                // Subtitle
                Text(L("force_update.subtitle"))
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color(hex: "#52606D"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.45).delay(0.28), value: appeared)

                Spacer()

                // CTA
                Button {
                    openAppStore()
                } label: {
                    Text(L("force_update.button"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 52)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.45).delay(0.38), value: appeared)
            }
        }
        .onAppear {
            appeared = true
            shake = true
        }
    }

    private func openAppStore() {
        // Replace with real App Store ID when published
        let appStoreID = "YOUR_APP_STORE_ID"
        if let url = URL(string: "https://apps.apple.com/app/id\(appStoreID)") {
            UIApplication.shared.open(url)
        }
    }
}
