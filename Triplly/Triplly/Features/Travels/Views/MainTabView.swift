import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var invitesViewModel = InvitesViewModel()

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
                InvitesView()
            }
            .tabItem {
                Label("Invites", systemImage: "envelope")
            }
            .tag(1)
            .badge(invitesViewModel.invites.count > 0 ? invitesViewModel.invites.count : 0)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(2)
        }
        .tint(Color.appPrimary)
        .task {
            await invitesViewModel.loadInvites()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
