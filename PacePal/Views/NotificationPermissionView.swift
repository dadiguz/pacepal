import SwiftUI

struct NotificationPermissionView: View {
    @Environment(AppState.self) private var appState

    private var displayDNA: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[1] }
    @State private var appeared = false
    @State private var requesting = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Logo
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                // Pet stage
                petStage
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                // Pitch
                pitchContent

                Spacer()

                // Buttons
                buttons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Pet stage

    private var petStage: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.07))
                .frame(width: 200, height: 200)
                .blur(radius: 28)

            Image(systemName: "bell.fill")
                .font(.system(size: 90, weight: .black))
                .foregroundStyle(Color(hex: "#F9703E").opacity(0.08))
                .offset(y: -6)

            PetAnimationView(dna: displayDNA, pose: .sign, pixelSize: 9)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)
        }
        .frame(height: 180)
    }

    // MARK: - Pitch content

    private var pitchContent: some View {
        VStack(spacing: 20) {
            (
                Text("Que nada te haga\n")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text("perderle el ritmo.")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            (
                Text("Te avisamos cuando tu compañero\npierda energía para que ")
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(Color(hex: "#52606D"))
                + Text("nunca se quede solo.")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 32)

            // Benefit pills
            HStack(spacing: 10) {
                benefitPill(icon: "bolt.fill",    label: "Alertas de energía")
                benefitPill(icon: "figure.run",   label: "Motivación diaria")
            }
            .padding(.top, 4)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)
    }

    private func benefitPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color(hex: "#F9703E"))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color(hex: "#FFF1EC"))
        .clipShape(Capsule())
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                requesting = true
                NotificationManager.requestPermission {
                    DispatchQueue.main.async {
                        requesting = false
                        withAnimation(.easeInOut(duration: 0.4)) {
                            appState.completeNotificationPermission()
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if requesting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    }
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15))
                    Text(requesting ? "Esperando permiso..." : "Activar notificaciones")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(requesting ? Color(hex: "#F9703E").opacity(0.6) : Color(hex: "#F9703E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
            }
            .disabled(requesting)
            .animation(.easeInOut(duration: 0.2), value: requesting)

            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.completeNotificationPermission()
                }
            } label: {
                Text("Omitir por ahora")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
        }
    }
}

#Preview {
    NotificationPermissionView()
        .environment(AppState())
}
