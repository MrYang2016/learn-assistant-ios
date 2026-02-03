import SwiftUI

struct MainTabView: View {
  @StateObject private var knowledgeViewModel = KnowledgeViewModel()
  @StateObject private var reviewViewModel = ReviewViewModel()

  var body: some View {
    TabView {
      KnowledgeListView()
        .environmentObject(knowledgeViewModel)
        .tabItem {
          Label("Knowledge", systemImage: "book.fill")
        }

      ReviewView()
        .environmentObject(reviewViewModel)
        .tabItem {
          Label("Review", systemImage: "calendar")
        }

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gear")
        }
    }
  }
}
