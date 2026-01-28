import Foundation
import Combine

@MainActor
class CompanionViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: text)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        do {
            let history = buildConversationHistory()
            let response = try await APIClient.shared.sendCompanionMessage(message: text, history: history)

            let assistantMessage = ChatMessage(role: .assistant, content: response.response)
            messages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(role: .assistant, content: "Sorry, I couldn't process your request. Please try again.")
            messages.append(errorMessage)
        }

        isLoading = false
    }

    private func buildConversationHistory() -> [[String: String]]? {
        guard messages.count > 1 else { return nil }

        // Exclude the last message (the one we just added) and limit history
        let historyMessages = Array(messages.dropLast().suffix(10))
        return historyMessages.map { message in
            ["role": message.role.rawValue, "content": message.content]
        }
    }

    func clearMessages() {
        messages = []
    }
}
