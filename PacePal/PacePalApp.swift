import SwiftUI
import SwiftData

@main
struct PacePalApp: App {
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
                health.requestAuthorizationAndFetch()
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
            if appState.selectedCharacter != nil {
                HomeView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .leading)
                    ))
            } else {
                CharacterSelectView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .onAppear {
            if appState.selectedCharacter == nil, let first = saved.first, let dna = first.dna {
                appState.selectedCharacter = dna
            }
        }
    }
}
