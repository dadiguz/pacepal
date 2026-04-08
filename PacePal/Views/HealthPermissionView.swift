import SwiftUI
import HealthKit

struct HealthPermissionView: View {
    @Environment(AppState.self) private var appState
    @Environment(HealthManager.self) private var health

    private var displayDNA: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[1] }
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
                    .padding(.top, 32)
                    .padding(.bottom, 24)

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
        VStack(spacing: 20) {
            // Title
            (
                Text(L("health.title_part1"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text(L("health.title_highlight"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            // Explanation
            (
                Text(L("health.subtitle_part1"))
                    .font(.system(size: 17, design: .rounded))
                    .foregroundStyle(Color(hex: "#52606D"))
                + Text(L("health.subtitle_highlight"))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 32)

            // What we read
            dataReadPills
                .padding(.top, 4)

            // Third-party app hint card
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "#F9703E").opacity(0.7))
                    .padding(.top, 1)
                (Text(L("health.third_party_hint_1")).foregroundStyle(Color(hex: "#52606D"))
                 + Text("Strava").bold().foregroundStyle(Color(hex: "#F9703E"))
                 + Text(L("health.third_party_hint_2")).foregroundStyle(Color(hex: "#52606D"))
                 + Text("Garmin").bold().foregroundStyle(Color(hex: "#F9703E"))
                 + Text(L("health.third_party_hint_3")).foregroundStyle(Color(hex: "#52606D")))
                    .font(.system(size: 13, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(hex: "#FFF1EC"))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color(hex: "#F9703E").opacity(0.20), lineWidth: 1))
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)
    }

    private var dataReadPills: some View {
        HStack(spacing: 10) {
            dataPill(icon: "figure.run", label: L("health.pill_distance"))
            dataPill(icon: "lock.fill",  label: L("health.pill_readonly"))
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
                Text(health.authState == .unavailable ? L("health.unavailable_title") : L("health.denied_title_part1"))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + (health.authState == .unavailable ? Text("") :
                    Text(L("health.denied_title_part2"))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: "#E12D39"))
                )
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Text(health.authState == .unavailable
                 ? L("health.unavailable_body")
                 : L("health.denied_body"))
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
                    Text(health.authState == .requesting ? L("health.requesting") : L("health.activate_button"))
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
                    Text(L("health.open_settings"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Color(hex: "#F9703E"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
                }

                // Retry (re-triggers the dialog if .notDetermined, or silently completes)
                Button(L("health.retry")) {
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
