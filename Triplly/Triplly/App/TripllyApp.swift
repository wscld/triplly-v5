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
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    handleUniversalLink(activity)
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

    private func handleUniversalLink(_ activity: NSUserActivity) {
        guard let url = activity.webpageURL,
              url.host == "triplly.com",
              url.pathComponents.count >= 3,
              url.pathComponents[1] == "u" else {
            return
        }
        let username = url.pathComponents[2]
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
                Image(systemName: "airplane.departure")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.appPrimary)
                    .symbolEffect(.pulse)

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
