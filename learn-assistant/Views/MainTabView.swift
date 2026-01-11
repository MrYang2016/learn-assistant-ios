import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var knowledgeViewModel: KnowledgeViewModel
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var reviewViewModel: ReviewViewModel
    
    init(authService: AuthService) {
        _knowledgeViewModel = StateObject(wrappedValue: KnowledgeViewModel(authService: authService))
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(authService: authService))
        _reviewViewModel = StateObject(wrappedValue: ReviewViewModel(authService: authService))
    }
    
    var body: some View {
        TabView {
            KnowledgeListView()
                .environmentObject(knowledgeViewModel)
                .tabItem {
                    Label("Knowledge", systemImage: "book.fill")
                }
            
            ChatView()
                .environmentObject(chatViewModel)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            ReviewView()
                .environmentObject(reviewViewModel)
                .tabItem {
                    Label("Review", systemImage: "calendar")
                }
            
            SettingsView()
                .environmentObject(authService)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}
