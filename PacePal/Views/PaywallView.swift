import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    @State private var appeared = false
    @State private var glowPulse = false
    @State private var featurePage = 0

    private let features: [(icon: String, color: String, title: String, desc: String)] = [
        ("figure.run",  "#F9703E", "Reto de 66 días",   "El tiempo justo para convertirlo en hábito"),
        ("heart.fill",  "#E12D39", "Apple Health",       "Tus km se sincronizan solos"),
        ("flame.fill",  "#DE911D", "Rachas y progreso",  "Cada día del reto en tu historial"),
    ]

    // Always use the real chosen pet if available
    private var displayDNA: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[1] }
    private var petName: String? {
        guard let name = appState.selectedCharacter?.name, !name.isEmpty else { return nil }
        return name
    }

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
                        .padding(.top, 52)

                    // Headline
                    headlineText
                        .padding(.top, 32)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                    // Feature carousel
                    featureList
                        .padding(.top, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                        .animation(.spring(duration: 0.45).delay(0.28), value: appeared)

                    // Price card
                    priceCard
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.45).delay(0.35), value: appeared)

                    // CTA
                    ctaButton
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
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
                    .padding(.top, 16)
                    .padding(.bottom, 48)
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
            if let name = petName {
                (
                    Text("Mantén a ")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    + Text(name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#F9703E"))
                    + Text(" con vida.")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                )
                .multilineTextAlignment(.center)
            } else {
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
            }

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

    // MARK: - Feature carousel

    private var featureList: some View {
        VStack(spacing: 10) {
            TabView(selection: $featurePage) {
                ForEach(features.indices, id: \.self) { i in
                    featureCard(features[i])
                        .tag(i)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 88)

            // Dots
            HStack(spacing: 6) {
                ForEach(features.indices, id: \.self) { i in
                    Capsule()
                        .fill(i == featurePage ? Color(hex: "#F9703E") : Color(hex: "#CBD2D9"))
                        .frame(width: i == featurePage ? 16 : 5, height: 5)
                        .animation(.spring(duration: 0.3), value: featurePage)
                }
            }
        }
        .onAppear {
            // Auto-advance every 2.5s
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                withAnimation(.spring(duration: 0.4)) {
                    featurePage = (featurePage + 1) % features.count
                }
            }
        }
    }

    private func featureCard(_ f: (icon: String, color: String, title: String, desc: String)) -> some View {
        HStack(spacing: 16) {
            Image(systemName: f.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color(hex: f.color))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(f.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Text(f.desc)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
        .shadow(color: .black.opacity(0.03), radius: 8, y: 3)
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
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
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
                .shadow(color: Color(hex: "#F9703E").opacity(glowPulse ? 0.70 : 0.20),
                        radius: glowPulse ? 20 : 8, y: 4)
                .shadow(color: Color(hex: "#F9703E").opacity(glowPulse ? 0.35 : 0.05),
                        radius: glowPulse ? 38 : 14, y: 8)
        }
        .scaleEffect(glowPulse ? 1.012 : 0.996)
    }
}

#Preview {
    PaywallView()
        .environment({
            let s = AppState()
            s.selectedCharacter = PetDNA.presets()[0]
            return s
        }())
}
