import SwiftUI
import CoreLocation

struct LocationPermissionView: View {
    @Environment(AppState.self) private var appState

    /// Called when the user grants location — used when presented from run context.
    var onGranted: (() -> Void)? = nil
    /// Called when the user cancels — used when presented from run context.
    var onCancel: (() -> Void)? = nil

    private var isRunContext: Bool { onCancel != nil }

    private var displayDNA: PetDNA { appState.selectedCharacter ?? PetDNA.presets()[1] }
    @State private var appeared = false
    @State private var locationManager = LocationPermissionManager()
    @State private var pinBob = false
    @State private var pinGlow = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                // X button (run context) or Logo (onboarding)
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(.top, 52)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeIn(duration: 0.35), value: appeared)

                // Pet with navigate pose
                petStage
                    .padding(.top, 32)
                    .padding(.bottom, 24)

                // Content
                pitchContent
                    .transition(.opacity)

                Spacer()

                // CTA
                ctaButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear { appeared = true }
        .onChange(of: locationManager.authStatus) { _, status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                if let onGranted {
                    onGranted()
                } else {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState.completeLocationPermission()
                    }
                }
            }
        }
    }

    // MARK: - Pet stage

    private var petStage: some View {
        ZStack(alignment: .center) {
            // Background glow
            Circle()
                .fill(Color(hex: "#F9703E").opacity(0.08))
                .frame(width: 180, height: 180)
                .blur(radius: 30)

            VStack(spacing: -14) {
                // Location pin the pet holds up
                ZStack {
                    // Glow behind pin
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(Color(hex: "#F9703E").opacity(pinGlow ? 0.35 : 0.12))
                        .blur(radius: 10)
                        .scaleEffect(pinGlow ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pinGlow)

                    // Pin itself
                    Image(systemName: "mappin.fill")
                        .font(.system(size: 52, weight: .black))
                        .foregroundStyle(Color(hex: "#F9703E"))
                        .shadow(color: Color(hex: "#F9703E").opacity(0.5), radius: 8, y: 4)
                }
                .offset(y: pinBob ? -7 : 0)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pinBob)

                // Pet in sign pose (holding something up)
                PetAnimationView(dna: displayDNA, pose: .sign, pixelSize: 9)
                    .frame(width: 130, height: 130)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(duration: 0.55, bounce: 0.3).delay(0.1), value: appeared)
            }
        }
        .frame(height: 180)
        .onAppear {
            pinBob  = true
            pinGlow = true
        }
    }

    // MARK: - Pitch content

    private var pitchContent: some View {
        VStack(spacing: 20) {
            (
                Text(L("location_perm.title_part1"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#1F2933"))
                + Text(L("location_perm.title_highlight"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#F9703E"))
            )
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

            Text(L("location_perm.subtitle"))
                .font(.system(size: 17, design: .rounded))
                .foregroundStyle(Color(hex: "#52606D"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Pills
            HStack(spacing: 10) {
                locPill(icon: "location.fill",   label: L("location_perm.pill_gps"))
                locPill(icon: "lock.fill",        label: L("location_perm.pill_readonly"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)
        }
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.spring(duration: 0.45).delay(0.2), value: appeared)
    }

    private func locPill(icon: String, label: String) -> some View {
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

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: 12) {
            Button {
                locationManager.request()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 15))
                    Text(L("location_perm.activate_button"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color(hex: "#F9703E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color(hex: "#F9703E").opacity(0.3), radius: 10, y: 5)
            }

            Button(L("location_perm.skip")) {
                if let onCancel {
                    onCancel()
                } else {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        appState.completeLocationPermission()
                    }
                }
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(Color(hex: "#9AA5B4"))
        }
    }
}

// MARK: - Location permission helper

@Observable
final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var authStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        authStatus = manager.authorizationStatus
    }

    func request() {
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authStatus = manager.authorizationStatus
    }
}

#Preview {
    LocationPermissionView()
        .environment(AppState())
}
