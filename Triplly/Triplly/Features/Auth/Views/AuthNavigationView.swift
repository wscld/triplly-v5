import SwiftUI

struct AuthNavigationView: View {
    var body: some View {
        NavigationStack {
            LoginView()
        }
    }
}

#Preview {
    AuthNavigationView()
        .environmentObject(AppState())
}
