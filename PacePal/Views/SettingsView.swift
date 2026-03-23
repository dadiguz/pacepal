import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    var onShowTutorial: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Color(hex: "#FFF8F2").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Ajustes")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color(hex: "#9AA5B4"))
                            .padding(10)
                            .background(Color(hex: "#F0E8E0"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)

                // Options list
                VStack(spacing: 10) {
                    settingsRow(
                        icon: "questionmark.circle",
                        iconColor: "#F9703E",
                        title: "Ver tutorial",
                        subtitle: "Repasa cómo funciona la energía"
                    ) {
                        onShowTutorial?()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    settingsRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: "#E12D39",
                        title: "Restablecer compañero",
                        subtitle: "Elige un nuevo mono desde cero"
                    ) {
                        showResetConfirm = true
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .confirmationDialog("Restablecer compañero", isPresented: $showResetConfirm) {
            Button("Restablecer", role: .destructive) {
                saved.forEach { modelContext.delete($0) }
                health.resetKm()
                dismiss()
                withAnimation(.spring(duration: 0.4)) {
                    appState.selectedCharacter = nil
                }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se borrará tu progreso y podrás elegir un nuevo compañero.")
        }
    }

    private func settingsRow(
        icon: String,
        iconColor: String,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: iconColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "#1F2933"))
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundStyle(Color(hex: "#9AA5B4"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "#CBD2D9"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(hex: "#FFF0E8"))
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(HealthManager())
}
