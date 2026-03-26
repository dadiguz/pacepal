import SwiftUI
import SwiftData

@main
struct PacepalApp: App {
    @State private var appState = AppState()
    @State private var health = HealthManager()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environment(appState)
            .environment(health)
            .animation(.easeInOut(duration: 0.45), value: showSplash)
            .task {
                // Only auto-request for returning users who already completed
                // the health permission screen — new users see it explicitly.
                if appState.healthPermissionDone {
                    health.requestAuthorizationAndFetch()
                }
                try? await Task.sleep(for: .seconds(2.4))
                showSplash = false
            }
        }
        .modelContainer(for: SavedCharacter.self)
    }
}

struct RootView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var saved: [SavedCharacter]

    var body: some View {
        Group {
            if !appState.onboardingCompleted {
                OnboardingView()
                    .transition(.opacity)
            } else if appState.selectedCharacter == nil {
                CharacterSelectView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if !appState.paywallDismissed {
                PaywallView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else if !appState.healthPermissionDone {
                HealthPermissionView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                HomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.4), value: appState.onboardingCompleted)
        .animation(.easeInOut(duration: 0.4), value: appState.selectedCharacter?.id)
        .animation(.easeInOut(duration: 0.4), value: appState.paywallDismissed)
        .animation(.easeInOut(duration: 0.4), value: appState.healthPermissionDone)
        .onAppear {
            if appState.selectedCharacter == nil, let first = saved.first, let dna = first.dna {
                appState.selectedCharacter = dna
            }
        }
    }
}
