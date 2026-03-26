import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false

    #if DEBUG
    @State private var debugNow: Date = Date()
    #endif

    var onShowTutorial: (() -> Void)? = nil

    var body: some View {
        ZStack {
            AppBackground()

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
                            .background(Color(hex: "#F5ECE4"))
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

                    // ── Difficulty row ───────────────────────────────────
                    let bindable = Bindable(appState)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 14) {
                            Image(systemName: "dial.medium")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Color(hex: "#9B59B6"))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dificultad")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color(hex: "#1F2933"))
                                Text(appState.difficulty.subtitle)
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(Color(hex: "#9AA5B4"))
                                    .animation(.easeInOut(duration: 0.2), value: appState.difficulty)
                            }
                        }

                        Picker("", selection: bindable.difficulty) {
                            ForEach(Difficulty.allCases, id: \.self) { d in
                                Text(d.label).tag(d)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))

                    settingsRow(
                        icon: "arrow.triangle.2.circlepath",
                        iconColor: "#E12D39",
                        title: "Restablecer compañero",
                        subtitle: "Elige un nuevo mono desde cero"
                    ) {
                        showResetConfirm = true
                    }
                }
                .padding(.horizontal, 24)

                #if DEBUG
                testingSection
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                #endif

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

    #if DEBUG
    private var testingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TESTING")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.4)
                .foregroundStyle(Color(hex: "#9AA5B4"))

            HStack(spacing: 6) {
                ForEach([
                    ("100%", 1.00),
                    ("96%",  0.96),
                    ("92%",  0.92),
                    ("70%",  0.70),
                    ("25%",  0.25),
                    ("0%",   0.00),
                ], id: \.0) { label, value in
                    Button {
                        appState.setEnergy(value)
                        debugNow = Date()
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white)
                            .foregroundStyle(Color(hex: "#4A3F35"))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                    }
                }
            }

            HStack(spacing: 6) {
                Button {
                    health.addTestKm()
                } label: {
                    Text("➕ 1 km")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }

                Button {
                    appState.addEnergy(km: 1.0)
                    debugNow = Date()
                } label: {
                    Text("⚡ +10% energía")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "#4A3F35"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
                }
            }
        }
    }
    #endif

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
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: "#E2E8F0"), lineWidth: 1))
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppState())
        .environment(HealthManager())
}
