import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]
    @State private var showResetConfirm = false

    // Tick every minute to keep energy level current
    @State private var now: Date = Date()

    private var dna: PetDNA { appState.selectedCharacter! }

    // MARK: – Energy (100% at 6 AM → 1% at 11:59 PM)
    private var energy: Double {
        let cal = Calendar.current
        let h   = cal.component(.hour,   from: now)
        let m   = cal.component(.minute, from: now)
        let total = h * 60 + m
        let start = 6 * 60   // 360  (6:00 AM)
        let end   = 24 * 60  // 1440 (midnight)
        guard total >= start else { return 0.01 }
        let ratio = Double(total - start) / Double(end - start)  // 0 → 1
        return max(0.01, 1.0 - ratio * 0.99)  // 100% → 1%
    }

    private var energyColor: Color {
        switch energy {
        case 0.60...: return Color(hex: "#4ADE80")  // green
        case 0.30...: return Color(hex: "#A3E635")  // lime
        default:      return Color(hex: "#FCD34D")  // warm yellow
        }
    }

    private var moodText: String {
        switch energy {
        case 0.70...: return "\(dna.name) está listo para correr"
        case 0.40...: return "\(dna.name) sigue aquí, ¿corremos?"
        default:      return "La energía se acaba... ¡sal a correr!"
        }
    }

    // Pose reacts lightly to energy
    private var pose: PetPose {
        energy < 0.25 ? .sad : .idle
    }

    var body: some View {
        ZStack {
            Color(hex: "#F5F7FA").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                Spacer(minLength: 12)

                companionCard
                    .padding(.horizontal, 24)

                Spacer(minLength: 16)

                // Stats row
                HStack(spacing: 12) {
                    kmCard
                    energyCard
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .onReceive(
            Timer.publish(every: 60, on: .main, in: .common).autoconnect()
        ) { date in
            now = date
        }
    }

    // MARK: – Top bar
    private var topBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PacePal")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                Text("Día 1 / 66")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
            }
            Spacer()
            Button {
                showResetConfirm = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color(hex: "#616E7C"))
                    .padding(10)
                    .background(Color(hex: "#EDF0F4"))
                    .clipShape(Circle())
            }
            .confirmationDialog("Perfil", isPresented: $showResetConfirm) {
                Button("Reiniciar compañero", role: .destructive) {
                    saved.forEach { modelContext.delete($0) }
                    withAnimation(.spring(duration: 0.4)) {
                        appState.selectedCharacter = nil
                    }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("¿Quieres elegir un nuevo compañero?")
            }
        }
    }

    // MARK: – Companion card
    private var companionCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 18, y: 5)

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    // Foot glow
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: dna.palette.body).opacity(0.35), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 130, height: 22)
                        .blur(radius: 10)
                        .padding(.bottom, 30)

                    PetAnimationView(dna: dna, pose: pose, pixelSize: 10.5)
                        .id(dna.id)
                }
                .padding(.top, 20)

                Text(moodText)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "#9AA5B4"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .padding(.top, 4)
                    .animation(.easeInOut(duration: 0.4), value: energy)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: – KM counter card
    private var kmCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "#F9703E"))
                .shadow(color: Color(hex: "#F9703E").opacity(0.30), radius: 12, y: 5)

            VStack(alignment: .leading, spacing: 4) {
                Text("HOY")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.65))

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text("0.0")
                        .font(.system(size: 44, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("km")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                        .padding(.bottom, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
    }

    // MARK: – Energy bar card
    private var energyCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 10, y: 4)

            VStack(alignment: .leading, spacing: 10) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    Text("ENERGÍA")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                    Spacer()
                    Text("\(Int(energy * 100))%")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(energyColor)
                        .animation(.easeInOut(duration: 0.4), value: energy)
                }

                // Bar track
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(hex: "#EDF0F4"))
                        RoundedRectangle(cornerRadius: 5)
                            .fill(energyColor)
                            .frame(width: geo.size.width * energy)
                            .animation(.spring(duration: 0.9), value: energy)
                    }
                }
                .frame(height: 8)

                // Time range labels
                HStack {
                    Text("6 AM")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Color(hex: "#CBD2D9"))
                    Spacer()
                    Text("12 AM")
                        .font(.system(size: 9, design: .rounded))
                        .foregroundStyle(Color(hex: "#CBD2D9"))
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    HomeView()
        .environment({
            let s = AppState()
            s.selectedCharacter = PetDNA.presets()[0]
            return s
        }())
}
