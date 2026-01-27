import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showEmailLogin = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Header
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(Color.appPrimary)

                    VStack(spacing: 8) {
                        Text("Welcome to Triplly")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Plan your trips together with friends and family")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                Spacer()

                // Sign In Options
                VStack(spacing: 16) {
                    // TODO: Enable Apple Sign In when membership is ready
                    // SignInWithAppleButton(.signIn) { request in
                    //     request.requestedScopes = [.fullName, .email]
                    // } onCompletion: { result in
                    //     Task {
                    //         await viewModel.handleAppleSignIn(result: result, using: appState)
                    //     }
                    // }
                    // .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    // .frame(height: 50)
                    // .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Email/Password Sign In Button
                    Button {
                        showEmailLogin = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                            Text("Continue with Email")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.appPrimary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Register Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(.secondary)

                        NavigationLink("Sign Up") {
                            RegisterView()
                        }
                        .foregroundStyle(Color.appPrimary)
                        .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
            .background(Color(.systemGroupedBackground))
            .navigationDestination(isPresented: $showEmailLogin) {
                EmailLoginView()
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}
