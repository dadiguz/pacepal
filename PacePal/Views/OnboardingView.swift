import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false
    @State private var leaving = false

    private let displayDNA = PetDNA.presets()[0]

    var body: some View {
        ZStack {
            AppBackground()

            // Sound toggle — top right
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
                            .foregroundStyle(Color(hex: "#9AA5B4"))
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

            VStack(spacing: 0) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 56)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                Spacer()

                // Pet + big "66" backdrop
                ZStack {
                    Text("66")
                        .font(.system(size: 160, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#F9703E"), Color(hex: "#FFAD80")],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .opacity(0.09)

                    Ellipse()
                        .fill(RadialGradient(
                            colors: [Color(hex: "#F9703E").opacity(0.28), .clear],
                            center: .center, startRadius: 0, endRadius: 60
                        ))
                        .frame(width: 140, height: 22)
                        .blur(radius: 12)
                        .offset(y: 46)

                    PetAnimationView(dna: displayDNA, pose: .running, pixelSize: 10)
                        .scaleEffect(appeared ? 1 : 0.85)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring(duration: 0.55, bounce: 0.25).delay(0.15), value: appeared)
                }
                .frame(height: 200)

                Spacer().frame(height: 36)

                // Hook copy
                VStack(spacing: 10) {
                    (
                        Text("Tu compañero\nde ")
                            .foregroundStyle(Color(hex: "#1F2933"))
                        + Text("66 días")
                            .foregroundStyle(Color(hex: "#F9703E"))
                        + Text(" te espera.")
                            .foregroundStyle(Color(hex: "#1F2933"))
                    )
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                    Text("Corre. Mantenlo vivo.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.4).delay(0.3), value: appeared)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState.completeOnboarding()
                    }
                } label: {
                    Text("Elegir mi compañero")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.35), radius: 16, y: 6)
                }
                .padding(.horizontal, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(duration: 0.45).delay(0.38), value: appeared)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            appeared = true
            SoundManager.shared.playMusic(name: "pacepal", enabled: appState.soundsEnabled)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
