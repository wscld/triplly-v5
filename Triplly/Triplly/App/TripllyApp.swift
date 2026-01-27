import SwiftUI

@main
struct TripllyApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .preferredColorScheme(.light)
        }
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
