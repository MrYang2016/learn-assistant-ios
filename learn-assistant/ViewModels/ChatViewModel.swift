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
        
        do {
            let token = try await authService.getAccessToken()
            
            // Convert messages to history format
            let history = messages.dropLast().suffix(10).map { message in
                ChatHistoryMessage(
                    role: message.role.rawValue,
                    content: message.content
                )
            }
            
            let response = try await APIService.shared.sendChatMessage(
                accessToken: token,
                message: text,
                history: Array(history)
            )
            
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response.response,
                timestamp: Date()
            )
            
            messages.append(assistantMessage)
            
            if let responseSources = response.sources, !responseSources.isEmpty {
                sources = responseSources
            }
        } catch {
            self.error = error.localizedDescription
            // Remove the user message if the request failed
            messages.removeLast()
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages = []
        sources = []
        error = nil
    }
}
