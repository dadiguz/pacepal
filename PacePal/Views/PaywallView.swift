import SwiftUI

struct PaywallView: View {
    @Environment(AppState.self) private var appState

    private let displayDNA = PetDNA.presets()[1]
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // Logo — centered
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
                    .padding(.top, 28)
                    .padding(.horizontal, 32)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

                // Benefit pills
                benefitPills
                    .padding(.top, 18)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.spring(duration: 0.45).delay(0.28), value: appeared)

                Spacer()

                // Price card
                priceCard
                    .padding(.horizontal, 24)
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
        .onAppear { appeared = true }
    }

    // MARK: - Pet

    private var petStage: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.07))
                .frame(width: 180, height: 180)
                .blur(radius: 28)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#F9703E").opacity(0.22), .clear],
                        center: .center, startRadius: 0, endRadius: 55
                    )
                )
                .frame(width: 110, height: 18)
                .blur(radius: 8)
                .offset(y: 40)

            PetAnimationView(dna: displayDNA, pose: .jump, pixelSize: 9)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)
        }
        .frame(height: 180)
    }

    // MARK: - Headline

    private var headlineText: some View {
        VStack(spacing: 6) {
            (
                Text("Empieza tu ")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text("prueba gratis")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                + Text("\nhoy mismo.")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
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

    // MARK: - Benefit pills (horizontal, compact)

    private var benefitPills: some View {
        HStack(spacing: 8) {
            benefitPill(icon: "figure.run",  label: "66 días")
            benefitPill(icon: "heart.fill",  label: "Apple Health")
            benefitPill(icon: "flame.fill",  label: "Rachas")
        }
        .padding(.horizontal, 24)
    }

    private func benefitPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(Color(hex: "#F9703E"))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "#FFF1EC"))
        .clipShape(Capsule())
    }

    // MARK: - Price card

    private var priceCard: some View {
        HStack(spacing: 0) {
            pricePill(top: "HOY", main: "GRATIS", sub: "7 días de prueba", highlighted: true)

            Rectangle()
                .fill(Color(hex: "#E4E7EB"))
                .frame(width: 1, height: 56)

            pricePill(top: "DESPUÉS", main: "$49", sub: "al mes", highlighted: false)
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
                .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
        }
    }
}

#Preview {
    PaywallView()
        .environment(AppState())
}
