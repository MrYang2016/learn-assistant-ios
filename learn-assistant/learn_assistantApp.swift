//
//  learn_assistantApp.swift
//  learn-assistant
//
//  Created by 羊锡贵 on 2026/1/10.
//

import SwiftUI

@main
struct learn_assistantApp: App {
  @State private var showWelcome = !LocalStorageService.shared.hasLaunchedBefore
  @State private var isLoading = true

  var body: some Scene {
    WindowGroup {
      Group {
        if isLoading {
          SplashView()
            .onAppear {
              // 短暂显示启动画面
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
              }
            }
        } else if showWelcome {
          WelcomeView(showWelcome: $showWelcome)
        } else {
          MainTabView()
        }
      }
    }
  }
}

// MARK: - Splash View

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

// MARK: - Welcome View (首次启动提示)

struct WelcomeView: View {
  @Binding var showWelcome: Bool

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      // Icon
      ZStack {
        Circle()
          .fill(Color.blue.opacity(0.1))
          .frame(width: 120, height: 120)

        Image(systemName: "brain.head.profile")
          .font(.system(size: 60))
          .foregroundColor(.blue)
      }
      .padding(.bottom, 30)

      // Title
      Text("欢迎使用学习助手")
        .font(.title)
        .fontWeight(.bold)
        .padding(.bottom, 8)

      Text("Welcome to Learn Assistant")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding(.bottom, 40)

      // Privacy Info Card
      VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
          Image(systemName: "lock.shield.fill")
            .font(.title2)
            .foregroundColor(.green)

          VStack(alignment: .leading, spacing: 4) {
            Text("数据本地存储")
              .font(.headline)
            Text("Local Data Storage")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Text("您的所有学习数据都安全地存储在您的设备上，不会上传到任何服务器。")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        Text(
          "All your learning data is stored securely on your device and will not be uploaded to any server."
        )
        .font(.caption)
        .foregroundColor(.secondary)
        .fixedSize(horizontal: false, vertical: true)

        Divider()
          .padding(.vertical, 8)

        HStack(spacing: 12) {
          Image(systemName: "iphone")
            .font(.title2)
            .foregroundColor(.blue)

          VStack(alignment: .leading, spacing: 4) {
            Text("无需登录")
              .font(.headline)
            Text("No Login Required")
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }

        Text("无需创建账号，直接开始使用，保护您的隐私。")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)

        Text("No account needed. Start using immediately while protecting your privacy.")
          .font(.caption)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(20)
      .background(Color(.systemGray6))
      .cornerRadius(16)
      .padding(.horizontal, 24)

      Spacer()

      // Start Button
      Button(action: {
        LocalStorageService.shared.markAsLaunched()
        withAnimation {
          showWelcome = false
        }
      }) {
        Text("开始使用  Get Started")
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
          .background(Color.blue)
          .cornerRadius(12)
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 40)
    }
    .background(Color(.systemBackground))
  }
}

#Preview {
  WelcomeView(showWelcome: .constant(true))
}
