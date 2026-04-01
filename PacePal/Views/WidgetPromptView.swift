import SwiftUI

struct WidgetPromptView: View {
    @Environment(AppState.self) private var appState
    @State private var appeared = false

    private var dna: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[0] }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                widgetPreview
                    .padding(.top, 36)
                    .scaleEffect(appeared ? 1 : 0.9)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.55, bounce: 0.25).delay(0.1), value: appeared)

                pitchContent
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.spring(duration: 0.45).delay(0.25), value: appeared)

                Spacer()

                buttons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.3).delay(0.35), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Widget preview

    private var widgetPreview: some View {
        HStack(spacing: 0) {
            // Left: pet placeholder
            VStack(spacing: 6) {
                Spacer(minLength: 0)
                PetAnimationView(dna: dna, pose: .happy, pixelSize: 4)
                    .frame(width: 80, height: 80)
                HStack(spacing: 3) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 9)
                    Text(dna.name)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#616E7C"))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(width: 100)

            Rectangle()
                .fill(Color(hex: "#E2E8F0"))
                .frame(width: 1)
                .padding(.vertical, 12)

            // Right: stats
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text("Energía")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                    Spacer()
                    Text("72%")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#4ADE80"))
                }
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(hex: "#E2E8F0")).frame(height: 4)
                    Capsule().fill(Color(hex: "#4ADE80")).frame(width: 86, height: 4)
                }
                Label("3.2 km hoy", systemImage: "figure.run")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#616E7C"))
                Label("Día 14 de 66", systemImage: "calendar")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#616E7C"))
                Text("Contento")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color(hex: "#4A3F35"))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color(hex: "#4ADE80").opacity(0.18)))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 300, height: 140)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.10), radius: 20, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1)
        )
    }

    // MARK: - Pitch

    private var pitchContent: some View {
        VStack(spacing: 20) {
            (
                Text("Tenlo siempre\n")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text("a la vista.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 28)

            Text("Agrega el widget a tu pantalla principal\ny mira su estado sin abrir la app.")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)

            // Steps
            VStack(spacing: 10) {
                step(number: "1", text: "Mantén presionado el home screen")
                step(number: "2", text: "Toca el botón  +  de la esquina")
                step(number: "3", text: "Busca Pacepal y elige el widget")
            }
            .padding(.top, 4)
            .padding(.horizontal, 32)
        }
    }

    private func step(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Color(hex: "#F9703E"))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color(hex: "#3E4C59"))

            Spacer()
        }
    }

    // MARK: - Buttons

    private var buttons: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.completeWidgetPrompt()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 15))
                    Text("Entendido")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color(hex: "#F9703E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.completeWidgetPrompt()
                }
            } label: {
                Text("Ahora no")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
        }
    }
}

#Preview {
    WidgetPromptView()
        .environment(AppState())
}
