import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Text("Email")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authService.user?.email ?? "Not available")
                    }
                    
                    HStack {
                        Text("User ID")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(authService.user?.id.prefix(8) ?? "")
                            .font(.system(.body, design: .monospaced))
                    }
                } header: {
                    Text("Account")
                }
                
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
                        Text("1.0.0")
                    }
                } header: {
                    Text("About")
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
}
