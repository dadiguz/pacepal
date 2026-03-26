import SwiftUI

// MARK: - Main view

struct OnboardingView: View {
    @Environment(AppState.self) private var appState

    @State private var currentPage = 0

    // Same character displayed throughout — only the pose changes
    private let displayDNA = PetDNA.presets()[1]

    private let poses: [PetPose] = [.idle, .running, .happy]
    private let totalSlides = 3

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // Top bar — logo centered, skip trailing
                ZStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)

                    HStack {
                        Spacer()
                        Button("Saltar") {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                appState.completeOnboarding()
                            }
                        }
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                        .padding(.trailing, 24)
                    }
                }
                .padding(.top, 56)

                // ── Pet stays fixed here — only pose changes ─────────────────
                petStage
                    .padding(.top, 8)

                // ── Slide content scrolls via TabView ────────────────────────
                TabView(selection: $currentPage) {
                    ForEach(0..<totalSlides, id: \.self) { i in
                        SlideContentView(slideIndex: i)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page dots
                pageDots
                    .padding(.bottom, 20)

                // CTA
                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Fixed pet stage

    private var petStage: some View {
        ZStack {
            // Background glow — shifts subtly per slide
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.07))
                .frame(width: 200, height: 200)
                .blur(radius: 28)

            // Large decorative number behind the pet
            Text(slideAccentText)
                .font(.system(size: 110, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#F9703E"), Color(hex: "#FFAD80")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(0.11)
                .animation(.easeInOut(duration: 0.3), value: currentPage)

            // Pet — same size across all slides, pose changes
            PetAnimationView(dna: displayDNA, pose: poses[currentPage], pixelSize: 9)
                .id(currentPage)          // forces redraw so animation restarts
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .animation(.spring(duration: 0.4, bounce: 0.2), value: currentPage)
        }
        .frame(height: 180)
    }

    private var slideAccentText: String {
        switch currentPage {
        case 0: return "66"
        case 1: return "♥"
        case 2: return "→"
        default: return ""
        }
    }

    // MARK: - Page dots

    private var pageDots: some View {
        HStack(spacing: 7) {
            ForEach(0..<totalSlides, id: \.self) { i in
                Capsule()
                    .fill(i == currentPage ? Color(hex: "#F9703E") : Color(hex: "#CBD2D9"))
                    .frame(width: i == currentPage ? 20 : 6, height: 6)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
    }

    // MARK: - CTA button

    private var ctaButton: some View {
        Button {
            if currentPage < totalSlides - 1 {
                withAnimation(.spring(duration: 0.35)) {
                    currentPage += 1
                }
            } else {
                withAnimation(.easeInOut(duration: 0.35)) {
                    appState.completeOnboarding()
                }
            }
        } label: {
            Text(currentPage < totalSlides - 1 ? "Siguiente" : "Comenzar mi reto")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color(hex: "#F9703E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .animation(.none, value: currentPage)
    }
}

// MARK: - Slide text content (scrollable, per slide)

private struct SlideContentView: View {
    let slideIndex: Int
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            titleText
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.spring(duration: 0.45).delay(0.05), value: appeared)
                .padding(.horizontal, 28)

            Spacer().frame(height: 16)

            bodyText
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(.spring(duration: 0.45).delay(0.13), value: appeared)
                .padding(.horizontal, 32)

            if slideIndex == 2 {
                dots66Grid
                    .padding(.top, 22)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.4).delay(0.22), value: appeared)
            }

            Spacer()
        }
        .onAppear { appeared = true }
        .onDisappear { appeared = false }
    }

    // MARK: - Titles

    @ViewBuilder
    private var titleText: some View {
        switch slideIndex {
        case 0:
            Text("No son 21 días.\nSon ")
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text("66.")
                .foregroundStyle(Color(hex: "#F9703E"))
        case 1:
            Text("Un compañero que\n")
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text("depende de ti.")
                .foregroundStyle(Color(hex: "#F9703E"))
        default:
            Text("Tu reto de ")
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text("66 días")
                .foregroundStyle(Color(hex: "#F9703E"))
            + Text("\nempieza hoy.")
                .foregroundStyle(Color(hex: "#1F2933"))
        }
    }

    // MARK: - Body text with highlights

    @ViewBuilder
    private var bodyText: some View {
        switch slideIndex {
        case 0:
            slide0Body
        case 1:
            slide1Body
        default:
            slide2Body
        }
    }

    private var slide0Body: some View {
        (
            Text("Un estudio de ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("University College London")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text(" demostró que el promedio real para formar un hábito es de ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("66 días")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#F9703E"))
            + Text(" — no 21, no 30.\nAlgunos lo logran en ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("18")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text(", otros tardan hasta ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("254.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
        )
    }

    private var slide1Body: some View {
        (
            Text("Cada vez que corres, tu mascota ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("gana energía.")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#F9703E"))
            + Text(" Si la abandonas,\n")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("se debilita.")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text("\n\nEsa ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("conexión emocional")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
            + Text(" es lo que te mantiene\ncorriendo cuando la motivación flaquea.")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
        )
    }

    private var slide2Body: some View {
        (
            Text("Construye tu racha día a día.\nAl ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("día 66")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#F9703E"))
            + Text(", correr ya no será un esfuerzo —\nserá parte de ")
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
            + Text("quien eres.")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "#1F2933"))
        )
    }

    // MARK: - 66 dots grid

    private var dots66Grid: some View {
        let columns = Array(repeating: GridItem(.fixed(10), spacing: 6), count: 11)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<66, id: \.self) { i in
                Circle()
                    .fill(i == 0 ? Color(hex: "#F9703E") : Color(hex: "#E4E7EB"))
                    .frame(width: 10, height: 10)
                    .overlay(
                        i == 0 ?
                        Circle()
                            .strokeBorder(Color(hex: "#F9703E").opacity(0.35), lineWidth: 2)
                            .frame(width: 14, height: 14)
                        : nil
                    )
            }
        }
        .frame(width: 11 * 10 + 10 * 6)
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
