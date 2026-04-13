import SwiftUI
import TelemetryDeck

struct PaywallView: View {
    @Environment(AppState.self) private var appState
    @Environment(PurchaseManager.self) private var store

    @State private var appeared = false
    @State private var glowPulse = false
    @State private var floatTick = false
    @State private var purchased = false
    @State private var activePill: Int? = nil

    private struct PillData {
        let icon: String; let color: String
        let titleES: String; let titleEN: String
        let descES: String;  let descEN: String
        let x: CGFloat; let y: CGFloat
        let floatAmp: CGFloat; let delay: Double
    }

    private let pills: [PillData] = [
        PillData(icon: "figure.run",           color: "#F9703E",
                 titleES: "66 días",      titleEN: "66 days",
                 descES:  "Completa el reto de 66 días para convertir correr en un hábito real.",
                 descEN:  "Complete the 66-day challenge and turn running into a real habit.",
                 x: -112, y: -80, floatAmp: 4, delay: 0.0),
        PillData(icon: "heart.fill",           color: "#E12D39",
                 titleES: "Apple Health", titleEN: "Apple Health",
                 descES:  "Tus kilómetros se sincronizan automáticamente. Sin hacer nada.",
                 descEN:  "Your kilometers sync automatically from Apple Health.",
                 x:  108, y: -65, floatAmp: 5, delay: 0.4),
        PillData(icon: "rectangle.stack.fill", color: "#0967D2",
                 titleES: "Widget",       titleEN: "Widget",
                 descES:  "Agrega el widget y ve el estado de tu compañero sin abrir la app.",
                 descEN:  "Add the widget and see your pet's status without opening the app.",
                 x: -118, y:  10, floatAmp: 3, delay: 0.7),
        PillData(icon: "bell.fill",            color: "#DE911D",
                 titleES: "Avisos",       titleEN: "Alerts",
                 descES:  "Recibe una notificación cuando tu compañero empieza a perder energía.",
                 descEN:  "Get notified when your companion starts losing energy.",
                 x:  110, y:  15, floatAmp: 6, delay: 0.2),
        PillData(icon: "flame.fill",           color: "#CF1124",
                 titleES: "Rachas",       titleEN: "Streaks",
                 descES:  "Consulta tu historial y mantén tu racha activa día a día.",
                 descEN:  "Track your history and keep your streak going every day.",
                 x:  -88, y:  82, floatAmp: 4, delay: 0.9),
        PillData(icon: "photo.fill",           color: "#27AB83",
                 titleES: "Fondos",       titleEN: "Backgrounds",
                 descES:  "Desbloquea nuevos fondos al alcanzar logros de racha en el reto.",
                 descEN:  "Unlock new backgrounds as you reach streak milestones.",
                 x:   84, y:  80, floatAmp: 5, delay: 0.5),
    ]

    private var isES: Bool { AppLang.current != .en }

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

                    // Pet + floating pills
                    petStage
                        .padding(.top, 24)

                    // Pill description card
                    if let i = activePill {
                        let p = pills[i]
                        HStack(spacing: 10) {
                            Image(systemName: p.icon)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(hex: p.color))
                                .clipShape(Circle())
                            Text(isES ? p.descES : p.descEN)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(hex: "#3E4C59"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: p.color).opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color(hex: p.color).opacity(0.2), lineWidth: 1))
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.scale(scale: 0.95, anchor: .top).combined(with: .opacity))
                    }

                    // Headline
                    headlineText
                        .padding(.top, 32)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)

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

                    // Error message
                    if let error = store.purchaseError {
                        Text(error)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(Color(hex: "#E12D39"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 12)
                    }

                    // Restore
                    Button {
                        Task { await store.restore() }
                    } label: {
                        Text(store.isRestoring ? L("paywall.restoring") : L("paywall.restore"))
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(Color(hex: "#9AA5B4"))
                    }
                    .disabled(store.isRestoring || store.isPurchasing)
                    .onChange(of: store.isPremium) { _, premium in
                        if premium {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                appState.dismissPaywall()
                            }
                        }
                    }
                    .padding(.top, 16)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.5), value: appeared)

                    // Subscription description (required by Apple)
                    Text(isES
                         ? "Pacepal Premium desbloquea el acceso completo a la app para completar el reto de 66 días: sincronización con Apple Health, widget, notificaciones y fondos. Suscripción anual · 7 días gratis, después \(store.displayPrice)/año · Cancela en Ajustes de Apple."
                         : "Pacepal Premium unlocks full access to complete the 66-day challenge: Apple Health sync, widget, notifications, and backgrounds. Annual subscription · 7-day free trial, then \(store.displayPrice)/year · Cancel anytime in Apple Settings.")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 12)
                        .opacity(appeared ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.52), value: appeared)

                    // Legal links (required by Apple)
                    HStack(spacing: 16) {
                        Link(isES ? "Privacidad" : "Privacy", destination: URL(string: "https://www.pacepal.mx/privacy")!)
                        Text("·").foregroundStyle(Color(hex: "#CBD2D9"))
                        Link(isES ? "Términos de uso" : "Terms of Use", destination: URL(string: "https://www.pacepal.mx/terms")!)
                    }
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                    .padding(.top, 10)
                    .padding(.bottom, 48)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.54), value: appeared)
                }
            }
        }
        .onChange(of: store.isPremium) { _, premium in
            if premium {
                withAnimation(.easeInOut(duration: 0.35)) {
                    appState.dismissPaywall()
                }
            }
        }
        .onAppear {
            TelemetryDeck.signal("paywall_viewed")
            appeared = true
            floatTick = true
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

            PetAnimationView(dna: displayDNA, pose: purchased ? .hype : .jump, pixelSize: 9)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)

            // Floating feature pills (encima del mono)
            ForEach(Array(pills.enumerated()), id: \.offset) { i, p in
                featurePill(p, isActive: activePill == i)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.3)) {
                            activePill = activePill == i ? nil : i
                        }
                    }
                    .offset(x: p.x, y: p.y + (floatTick ? p.floatAmp : -p.floatAmp))
                    .animation(
                        .easeInOut(duration: 2.2 + Double(i) * 0.25)
                        .repeatForever(autoreverses: true)
                        .delay(p.delay),
                        value: floatTick
                    )
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35).delay(0.15 + Double(i) * 0.08), value: appeared)
            }
        }
        .frame(height: 260)
    }

    private func featurePill(_ p: PillData, isActive: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: p.icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color(hex: p.color))
                .clipShape(Circle())
            Text(isES ? p.titleES : p.titleEN)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
                .lineLimit(1)
                .fixedSize()
        }
        .fixedSize()
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(isActive ? Color(hex: p.color).opacity(0.15) : .white.opacity(0.72))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
        .overlay(Capsule().strokeBorder(isActive ? Color(hex: p.color).opacity(0.5) : .clear, lineWidth: 1.5))
    }

    // MARK: - Headline

    private var headlineText: some View {
        VStack(spacing: 6) {
            if let name = petName {
                (
                    Text(L("paywall.headline_keep_part1"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    + Text(name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#F9703E"))
                    + Text(L("paywall.headline_keep_part2"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                )
                .multilineTextAlignment(.center)
            } else {
                (
                    Text(L("paywall.headline_start_part1"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    + Text(L("paywall.headline_start_highlight"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#F9703E"))
                    + Text(L("paywall.headline_start_part3"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                )
                .multilineTextAlignment(.center)
            }

            HStack(spacing: 6) {
                Label(L("paywall.free_trial_badge"), systemImage: "checkmark.seal.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
                Text("·")
                    .foregroundStyle(Color(hex: "#CBD2D9"))
                Text(L("paywall.cancel_anytime"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
        }
    }

    // MARK: - Price card

    private var priceCard: some View {
        HStack(spacing: 0) {
            pricePill(top: L("paywall.price_today"), main: L("paywall.price_free"), sub: L("paywall.price_trial_days"), highlighted: true)

            Rectangle()
                .fill(Color(hex: "#E4E7EB"))
                .frame(width: 1, height: 56)

            pricePill(top: L("paywall.price_after"), main: store.displayPrice, sub: L("paywall.price_per_year"), highlighted: false)
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
            Task {
                await store.purchase()
                if store.isPremium {
                    TelemetryDeck.signal("purchase_completed")
                    purchased = true
                    SoundManager.shared.play(.hype, enabled: appState.soundsEnabled)
                    try? await Task.sleep(for: .seconds(1.4))
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState.dismissPaywall()
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                if store.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.85)
                }
                Text(store.isPurchasing ? L("paywall.processing") : L("paywall.start_trial"))
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(Color(hex: "#F9703E").opacity(store.isPurchasing ? 0.6 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(hex: "#F9703E").opacity(glowPulse ? 0.70 : 0.20),
                    radius: glowPulse ? 20 : 8, y: 4)
            .shadow(color: Color(hex: "#F9703E").opacity(glowPulse ? 0.35 : 0.05),
                    radius: glowPulse ? 38 : 14, y: 8)
        }
        .disabled(store.isPurchasing || store.isRestoring)
        .scaleEffect(glowPulse ? 1.012 : 0.996)
        .animation(.easeInOut(duration: 0.2), value: store.isPurchasing)
    }
}

#Preview {
    PaywallView()
        .environment({
            let s = AppState()
            s.selectedCharacter = PetDNA.presets()[0]
            return s
        }())
        .environment(PurchaseManager())
}
