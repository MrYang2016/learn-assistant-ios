//
//  learn_assistantApp.swift
//  learn-assistant
//
//  Created by 羊锡贵 on 2026/1/10.
//

import SwiftUI

@main
struct learn_assistantApp: App {
    @StateObject private var authService = AuthService()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    SplashView()
                } else if authService.isAuthenticated {
                    MainTabView(authService: authService)
                } else {
                    SignInView()
                }
            }
            .environmentObject(authService)
        }
    }
}

struct SplashView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            ProgressView()
                .scaleEffect(1.5)
        }
    }
}
