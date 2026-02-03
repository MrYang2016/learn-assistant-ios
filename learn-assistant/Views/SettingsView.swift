import SwiftUI

struct SettingsView: View {
  @State private var statistics: StorageStatistics?
  @State private var showingResetAlert = false

  private let storageService = LocalStorageService.shared

  var body: some View {
    NavigationView {
      List {
        // 数据隐私提示
        Section {
          HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill")
              .font(.title2)
              .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
              Text("Data Privacy")
                .font(.headline)
              Text("All data stored locally on your device")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
          .padding(.vertical, 4)
        } header: {
          Text("Privacy")
        }

        // 统计信息
        Section {
          if let stats = statistics {
            HStack {
              Text("Knowledge Points")
                .foregroundColor(.secondary)
              Spacer()
              Text("\(stats.totalKnowledgePoints)")
                .fontWeight(.medium)
            }

            HStack {
              Text("In Review Plan")
                .foregroundColor(.secondary)
              Spacer()
              Text("\(stats.pointsInReviewPlan)")
                .fontWeight(.medium)
            }

            HStack {
              Text("Today's Pending Reviews")
                .foregroundColor(.secondary)
              Spacer()
              Text("\(stats.pendingReviewsToday)")
                .fontWeight(.medium)
                .foregroundColor(stats.pendingReviewsToday > 0 ? .orange : .green)
            }

            HStack {
              Text("Completed Today")
                .foregroundColor(.secondary)
              Spacer()
              Text("\(stats.completedReviewsToday)")
                .fontWeight(.medium)
                .foregroundColor(.green)
            }
          } else {
            ProgressView()
          }
        } header: {
          Text("Statistics")
        }

        // 关于信息
        Section {
          Link(destination: URL(string: "https://github.com/yourusername/learn-assistant")!) {
            HStack {
              Text("GitHub Repository")
              Spacer()
              Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }

          HStack {
            Text("Version")
              .foregroundColor(.secondary)
            Spacer()
            Text("2.0.0 (Local)")
          }

          HStack {
            Text("Storage")
              .foregroundColor(.secondary)
            Spacer()
            Text("Local Only")
              .foregroundColor(.green)
          }
        } header: {
          Text("About")
        }

        // 重置数据（危险操作）
        Section {
          Button(
            role: .destructive,
            action: {
              showingResetAlert = true
            }
          ) {
            HStack {
              Spacer()
              Image(systemName: "trash")
              Text("Reset All Data")
              Spacer()
            }
          }
        } footer: {
          Text(
            "This will permanently delete all your knowledge points and review schedules. This action cannot be undone."
          )
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Settings")
      .alert("Reset All Data", isPresented: $showingResetAlert) {
        Button("Cancel", role: .cancel) {}
        Button("Reset", role: .destructive) {
          resetAllData()
        }
      } message: {
        Text("Are you sure you want to delete all your data? This action cannot be undone.")
      }
      .onAppear {
        loadStatistics()
      }
    }
  }

  private func loadStatistics() {
    statistics = storageService.getStatistics()
  }

  private func resetAllData() {
    // 删除所有数据
    UserDefaults.standard.removeObject(forKey: "LearnAssistant.KnowledgePoints")
    UserDefaults.standard.removeObject(forKey: "LearnAssistant.ReviewSchedules")

    // 重新加载统计
    loadStatistics()
  }
}

#Preview {
  SettingsView()
}
