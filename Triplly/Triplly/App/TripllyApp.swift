import SwiftUI
import Himetrica

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Himetrica.configure(apiKey: "hm_58e9ef6e9f3102833740e6d5993ac2ca8634623594a6e49c")
        return true
    }
}

@main
struct TripllyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
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
        .himetricaLifecycle()
        .himetricaDeepLink()
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
