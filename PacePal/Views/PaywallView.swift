import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    private let displayDNA = PetDNA.presets()[1]
    @State private var appeared = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
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

                    // Headline
                    headlineText
                        .padding(.top, 20)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                    // Feature rows
                    featureList
                        .padding(.top, 16)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(duration: 0.45).delay(0.28), value: appeared)

                    // Price card
                    priceCard
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.45).delay(0.35), value: appeared)

                    // CTA
                    ctaButton
                        .padding(.horizontal, 24)
                        .padding(.top, 14)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.45).delay(0.42), value: appeared)

                    // Skip
                    Button("Continuar sin suscripción") {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            appState.dismissPaywall()
                        }
                    }
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.5), value: appeared)
                }
            }
        }
        .onAppear {
            appeared = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
        }
    }

    // MARK: - Pet

    private var petStage: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.07))
                .frame(width: 160, height: 160)
                .blur(radius: 24)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#F9703E").opacity(0.22), .clear],
                        center: .center, startRadius: 0, endRadius: 50
                    )
                )
                .frame(width: 100, height: 16)
                .blur(radius: 8)
                .offset(y: 36)

            PetAnimationView(dna: displayDNA, pose: .jump, pixelSize: 9)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)
        }
        .frame(height: 160)
    }

    // MARK: - Headline

    private var headlineText: some View {
        VStack(spacing: 6) {
            (
                Text("Empieza tu ")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text("prueba gratis")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                + Text(" hoy mismo.")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
            )
            .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Label("7 días gratis", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                Text("·")
                    .foregroundStyle(Color(hex: "#CBD2D9"))
                Text("Cancela cuando quieras")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
        }
    }

    // MARK: - Feature list

    private var featureList: some View {
        VStack(spacing: 8) {
            featureRow(icon: "figure.run",  iconColor: "#F9703E",
                       title: "Reto de 66 días",
                       desc:  "El tiempo justo para convertirlo en hábito")
            featureRow(icon: "heart.fill",  iconColor: "#E12D39",
                       title: "Apple Health",
                       desc:  "Tus km se sincronizan solos")
            featureRow(icon: "flame.fill",  iconColor: "#DE911D",
                       title: "Rachas y progreso",
                       desc:  "Cada día del reto en tu historial")
        }
        .padding(.horizontal, 24)
    }

    private func featureRow(icon: String, iconColor: String, title: String, desc: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Color(hex: iconColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Text(desc)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(hex: "#FFF0E8"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Price card

    private var priceCard: some View {
        HStack(spacing: 0) {
            pricePill(top: "HOY", main: "GRATIS", sub: "7 días de prueba", highlighted: true)

            Rectangle()
                .fill(Color(hex: "#E4E7EB"))
                .frame(width: 1, height: 56)

            pricePill(top: "DESPUÉS", main: "$49", sub: "al mes · MXN", highlighted: false)
        }
        .frame(height: 82)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }

    private func pricePill(top: String, main: String, sub: String, highlighted: Bool) -> some View {
        VStack(spacing: 2) {
            Text(top)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(highlighted ? Color(hex: "#F9703E") : Color(hex: "#9AA5B4"))
                .tracking(1)
            Text(main)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(highlighted ? Color(hex: "#F9703E") : Color(hex: "#1F2933"))
            Text(sub)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#9AA5B4"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.35)) {
                appState.dismissPaywall()
            }
        } label: {
            Text("Comenzar prueba gratuita")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color(hex: "#F9703E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                // Glow interior
                .shadow(color: Color(hex: "#F9703E").opacity(glowPulse ? 0.70 : 0.20),
                        radius: glowPulse ? 20 : 8, y: 4)
                // Glow exterior difuso
                .shadow(color: Color(hex: "#F9703E").opacity(glowPulse ? 0.35 : 0.05),
                        radius: glowPulse ? 38 : 14, y: 8)
        }
        .scaleEffect(glowPulse ? 1.012 : 0.996)
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
}
