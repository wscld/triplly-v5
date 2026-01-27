import SwiftUI
import Combine

@MainActor
final class ErrorManager: ObservableObject {
    static let shared = ErrorManager()

    @Published var currentError: AlertError?

    private init() {}

    func show(_ error: Error) {
        let message: String
        let title: String

        if let networkError = error as? NetworkError {
            title = "Network Error"
            message = networkError.userMessage
        } else if let decodingError = error as? DecodingError {
            title = "Data Error"
            message = "Failed to process server response"
            print("DEBUG: DecodingError details: \(decodingError)")
        } else {
            title = "Error"
            message = error.localizedDescription
        }

        currentError = AlertError(title: title, message: message)
    }

    func show(title: String, message: String) {
        currentError = AlertError(title: title, message: message)
    }

    func dismiss() {
        currentError = nil
    }
}

struct AlertError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - NetworkError User Message
extension NetworkError {
    var userMessage: String {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            switch code {
            case 400: return "Bad request - please try again"
            case 401: return "Please log in again"
            case 403: return "You don't have permission for this action"
            case 404: return "Resource not found"
            case 500...599: return "Server error - please try again later"
            default: return "Request failed (error \(code))"
            }
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to process server response"
        case .uploadFailed:
            return "Failed to upload file"
        case .noConnection:
            return "No internet connection"
        }
    }
}

// MARK: - Global Error Alert Modifier
struct GlobalErrorAlert: ViewModifier {
    @ObservedObject var errorManager = ErrorManager.shared

    func body(content: Content) -> some View {
        content
            .alert(
                errorManager.currentError?.title ?? "Error",
                isPresented: Binding(
                    get: { errorManager.currentError != nil },
                    set: { if !$0 { errorManager.dismiss() } }
                )
            ) {
                Button("OK") {
                    errorManager.dismiss()
                }
            } message: {
                if let error = errorManager.currentError {
                    Text(error.message)
                }
            }
    }
}

extension View {
    func globalErrorAlert() -> some View {
        modifier(GlobalErrorAlert())
    }
}
