import SwiftUI
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var name = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Validation State
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var nameError: String?

    // MARK: - Validation
    var isLoginValid: Bool {
        !email.isEmpty && !password.isEmpty && emailError == nil && passwordError == nil
    }

    var isRegisterValid: Bool {
        !name.isEmpty && !email.isEmpty && !password.isEmpty &&
        nameError == nil && emailError == nil && passwordError == nil
    }

    func validateEmail() {
        if email.isEmpty {
            emailError = nil
            return
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if !emailPredicate.evaluate(with: email) {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }

    func validatePassword() {
        if password.isEmpty {
            passwordError = nil
            return
        }

        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = nil
        }
    }

    func validateName() {
        if name.isEmpty {
            nameError = nil
            return
        }

        if name.count < 2 {
            nameError = "Name must be at least 2 characters"
        } else {
            nameError = nil
        }
    }

    // MARK: - Actions
    func login(using appState: AppState) async {
        validateEmail()
        validatePassword()

        guard isLoginValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await appState.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func register(using appState: AppState) async {
        validateName()
        validateEmail()
        validatePassword()

        guard isRegisterValid else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await appState.register(name: name, email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearForm() {
        email = ""
        password = ""
        name = ""
        emailError = nil
        passwordError = nil
        nameError = nil
        errorMessage = nil
    }
}
