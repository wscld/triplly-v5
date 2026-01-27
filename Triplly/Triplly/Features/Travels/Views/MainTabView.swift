import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TravelsListView()
            }
            .tabItem {
                Label("Trips", systemImage: "airplane")
            }
            .tag(0)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(1)
        }
        .tint(Color.appPrimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
