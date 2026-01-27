import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case decodingError
    case uploadFailed
    case noConnection

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Request failed with status code \(code)"
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode response"
        case .uploadFailed:
            return "Failed to upload file"
        case .noConnection:
            return "No internet connection"
        }
    }
}
