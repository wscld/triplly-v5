import SwiftUI

@main
struct TripllyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    handleCustomScheme(url)
                }
        }
    }

    private func handleCustomScheme(_ url: URL) {
        // triplly://profile/{username}
        guard url.scheme == "triplly",
              url.host == "profile",
              let username = url.pathComponents.dropFirst().first else {
            return
        }
        appState.navigateToPublicProfile(username: username)
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                SplashView()
            } else if appState.isAuthenticated {
                MainTabView()
            } else {
                AuthNavigationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: appState.isLoading)
        .globalErrorAlert()
        .sheet(isPresented: $appState.showOnboarding) {
            OnboardingView()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $appState.showPaywall) {
            PaywallView()
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)

                Text("Triplly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
}
