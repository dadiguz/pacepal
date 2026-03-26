import SwiftUI
import HealthKit

struct HealthPermissionView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health

    private let displayDNA = PetDNA.presets()[1]
    @State private var appeared = false

    // Advance automatically once authorized
    private var shouldAdvance: Bool {
        health.authState == .authorized
    }

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

                // Pet
                petStage
                    .padding(.top, 4)

                // Content swaps between normal pitch and denied state
                if health.authState == .denied || health.authState == .unavailable {
                    deniedContent
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    pitchContent
                        .transition(.opacity)
                }

                Spacer()

                // CTA
                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
            .animation(.spring(duration: 0.4), value: health.authState == .denied)
        }
        .onAppear { appeared = true }
        .onChange(of: shouldAdvance) { _, advance in
            if advance {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.completeHealthPermission()
                }
            }
        }
    }

    // MARK: - Pet stage

    private var petStage: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.07))
                .frame(width: 200, height: 200)
                .blur(radius: 28)

            // Health icon decoration
            Image(systemName: health.authState == .denied ? "heart.slash.fill" : "heart.fill")
                .font(.system(size: 90, weight: .black))
                .foregroundStyle(Color(hex: "#F9703E").opacity(0.08))
                .offset(y: -6)

            PetAnimationView(dna: displayDNA, pose: health.authState == .denied ? .sad : .running, pixelSize: 9)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)
                .animation(.spring(duration: 0.4), value: health.authState)
        }
        .frame(height: 180)
    }

    // MARK: - Pitch content (normal state)

    private var pitchContent: some View {
        VStack(spacing: 14) {
            // Title
            (
                Text("Pacepal necesita\nacceso a ")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text("Apple Health")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                + Text(".")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            // Explanation
            (
                Text("Sin tus datos de ")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color(hex: "#52606D"))
                + Text("distancia recorrida")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text(", tu compañero no puede saber cuándo corres.\n\nNunca compartimos tu información — solo la usamos para que ")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundStyle(Color(hex: "#52606D"))
                + Text("tu mascota cobre vida.")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .padding(.horizontal, 32)

            // What we read
            dataReadPills
                .padding(.top, 4)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)
    }

    private var dataReadPills: some View {
        HStack(spacing: 10) {
            dataPill(icon: "figure.run", label: "Distancia")
            dataPill(icon: "lock.fill",  label: "Solo lectura")
        }
        .padding(.horizontal, 24)
    }

    private func dataPill(icon: String, label: String) -> some View {
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

    // MARK: - Denied content

    private var deniedContent: some View {
        VStack(spacing: 14) {
            (
                Text(health.authState == .unavailable ? "Apple Health no\nestá disponible" : "Acceso a Health\n")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + (health.authState == .unavailable ? Text("") :
                    Text("no activado.")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#E12D39"))
                )
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Text(health.authState == .unavailable
                 ? "Apple Health no está disponible en este dispositivo. Pacepal requiere un iPhone con Apple Health para funcionar."
                 : "Sin acceso, Pacepal no puede detectar tus carreras y tu compañero no podrá crecer contigo.\n\nVe a Ajustes → Privacidad → Salud → Pacepal y activa Distancia en caminata y carrera.")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, 32)
        }
        .padding(.top, 24)
    }

    // MARK: - CTA button

    @ViewBuilder
    private var ctaButton: some View {
        switch health.authState {

        case .idle, .requesting:
            Button {
                health.requestFromPermissionScreen()
            } label: {
                HStack(spacing: 8) {
                    if health.authState == .requesting {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.85)
                    }
                    Image(systemName: "heart.fill")
                        .font(.system(size: 15))
                    Text(health.authState == .requesting ? "Esperando permiso..." : "Activar Apple Health")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(health.authState == .requesting
                    ? Color(hex: "#F9703E").opacity(0.6)
                    : Color(hex: "#F9703E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
            }
            .disabled(health.authState == .requesting)
            .animation(.easeInOut(duration: 0.2), value: health.authState == .requesting)

        case .denied:
            VStack(spacing: 12) {
                // Open settings
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Abrir Ajustes")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
                }

                // Retry (re-triggers the dialog if .notDetermined, or silently completes)
                Button("Intentar de nuevo") {
                    health.requestFromPermissionScreen()
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
            }

        case .unavailable:
            EmptyView()

        case .authorized:
            EmptyView()
        }
    }
}

#Preview {
    HealthPermissionView()
        .environment(AppState())
        .environment(HealthManager())
}
