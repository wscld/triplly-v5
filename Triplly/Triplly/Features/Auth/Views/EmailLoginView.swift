import SwiftUI

struct EmailLoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "envelope.circle.fill")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.top, 60)

                    VStack(spacing: 8) {
                        Text("Sign In")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Enter your email and password")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 16)

                // Form
                VStack(spacing: 20) {
                    AppTextField(
                        title: "Email",
                        placeholder: "Enter your email",
                        text: $viewModel.email,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        autocapitalization: .never,
                        errorMessage: viewModel.emailError
                    )
                    .onChange(of: viewModel.email) { _, _ in
                        viewModel.validateEmail()
                    }

                    AppTextField(
                        title: "Password",
                        placeholder: "Enter your password",
                        text: $viewModel.password,
                        icon: "lock",
                        isSecure: true,
                        errorMessage: viewModel.passwordError
                    )
                    .onChange(of: viewModel.password) { _, _ in
                        viewModel.validatePassword()
                    }
                }

                // Error Message
                if let error = viewModel.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Sign In Button
                AppButton(
                    title: "Sign In",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isLoginValid
                ) {
                    Task {
                        await viewModel.login(using: appState)
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EmailLoginView()
    }
    .environmentObject(AppState())
}
