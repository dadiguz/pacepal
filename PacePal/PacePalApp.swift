import SwiftUI
import SwiftData
import UserNotifications

@main
struct PacepalApp: App {
    @State private var appState = AppState()
    @State private var health = HealthManager()
    @State private var store = PurchaseManager()
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
            .environment(store)
            .animation(.easeInOut(duration: 0.45), value: showSplash)
            .task {
                // Set delegate so foreground banners work for returning users.
                // New users go through NotificationPermissionView which calls requestPermission().
                if appState.notificationPermissionDone {
                    NotificationManager.requestPermission()
                } else {
                    UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
                }
                // Only auto-request for returning users who already completed
                // the health permission screen — new users see it explicitly.
                if appState.healthPermissionDone {
                    health.requestAuthorizationAndFetch()
                }
                appState.syncToWidget(km: health.todayKm)
                // Verify subscription is still active; if not, reset paywall so it shows again.
                await store.refreshStatus()
                if !store.isPremium && appState.paywallDismissed {
                    appState.resetPaywall()
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
            } else if !appState.notificationPermissionDone {
                NotificationPermissionView()
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
        .animation(.easeInOut(duration: 0.4), value: appState.notificationPermissionDone)
        .onAppear {
            if appState.selectedCharacter == nil, let first = saved.first, let dna = first.dna {
                appState.selectedCharacter = dna
            }
        }
    }
}
