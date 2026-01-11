import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var sources: [Source] = []
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            role: .user,
            content: text,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        isLoading = true
        error = nil
        sources = []
        
        // Create assistant message placeholder for streaming
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: "",
            timestamp: Date()
        )
        messages.append(assistantMessage)
        let assistantMessageIndex = messages.count - 1
        
        do {
            let token = try await authService.getAccessToken()
            
            // Convert messages to history format (excluding the placeholder)
            let history = messages.dropLast().suffix(10).map { message in
                ChatHistoryMessage(
                    role: message.role.rawValue,
                    content: message.content
                )
            }
            
            var accumulatedContent = ""
            
            try await APIService.shared.sendChatMessage(
                accessToken: token,
                message: text,
                history: Array(history),
                onContent: { [weak self] content in
                    Task { @MainActor in
                        guard let self = self else { return }
                        // Append content to accumulated response
                        accumulatedContent += content
                        // Update the assistant message
                        if assistantMessageIndex < self.messages.count {
                            let currentMessage = self.messages[assistantMessageIndex]
                            self.messages[assistantMessageIndex] = ChatMessage(
                                role: currentMessage.role,
                                content: accumulatedContent,
                                timestamp: currentMessage.timestamp
                            )
                        }
                    }
                },
                onSources: { [weak self] responseSources in
                    Task { @MainActor in
                        guard let self = self else { return }
                        if !responseSources.isEmpty {
                            self.sources = responseSources
                        }
                    }
                }
            )
        } catch {
            self.error = error.localizedDescription
            // Remove both user and assistant messages if the request failed
            if messages.count >= 2 {
                messages.removeLast(2)
            } else if !messages.isEmpty {
                messages.removeLast()
            }
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages = []
        sources = []
        error = nil
    }
}
