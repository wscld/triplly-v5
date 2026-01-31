import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Color.appPrimary)
                        .padding(.top, 60)

                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Start planning your next adventure")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.bottom, 16)

                // Form
                VStack(spacing: 20) {
                    AppTextField(
                        title: "Full Name",
                        placeholder: "Enter your name",
                        text: $viewModel.name,
                        icon: "person",
                        autocapitalization: .words,
                        errorMessage: viewModel.nameError
                    )
                    .onChange(of: viewModel.name) { _, _ in
                        viewModel.validateName()
                    }

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
                        placeholder: "Create a password",
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

                // Register Button
                AppButton(
                    title: "Create Account",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.isRegisterValid
                ) {
                    Task {
                        await viewModel.register(using: appState)
                    }
                }
                .padding(.top, 8)

                // Login Link
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .foregroundStyle(.secondary)

                    Button("Sign In") {
                        dismiss()
                    }
                    .foregroundStyle(Color.appPrimary)
                    .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
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
        RegisterView()
    }
    .environmentObject(AppState())
}
