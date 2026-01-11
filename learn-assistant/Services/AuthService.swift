import Foundation

class AuthService: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = true
    
    private var accessToken: String?
    private var refreshToken: String?
    private var expiresAt: Int?
    
    private let userDefaultsKey = "LearnAssistant.Auth"
    
    init() {
        loadAuthState()
    }
    
    // MARK: - Auth State Management
    
    private func loadAuthState() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let authData = try? JSONDecoder().decode(StoredAuthData.self, from: data) else {
            isLoading = false
            return
        }
        
        self.user = authData.user
        self.accessToken = authData.accessToken
        self.refreshToken = authData.refreshToken
        self.expiresAt = authData.expiresAt
        self.isAuthenticated = true
        
        // Check if token needs refresh
        if shouldRefreshToken() {
            Task {
                await refreshTokenIfNeeded()
            }
        } else {
            isLoading = false
        }
    }
    
    private func saveAuthState(response: AuthResponse) {
        let authData = StoredAuthData(
            user: response.user,
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiresAt
        )
        
        if let data = try? JSONEncoder().encode(authData) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        
        self.user = response.user
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        self.expiresAt = response.expiresAt
        self.isAuthenticated = true
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        self.user = nil
        self.accessToken = nil
        self.refreshToken = nil
        self.expiresAt = nil
        self.isAuthenticated = false
    }
    
    // MARK: - Email/Password Authentication
    
    func signIn(email: String, password: String) async throws {
        let response = try await APIService.shared.signIn(email: email, password: password)
        
        await MainActor.run {
            saveAuthState(response: response)
            isLoading = false
        }
    }
    
    func signUp(email: String, password: String) async throws {
        let response = try await APIService.shared.signUp(email: email, password: password)
        
        await MainActor.run {
            saveAuthState(response: response)
            isLoading = false
        }
    }
    
    // MARK: - Token Management
    
    func getAccessToken() async throws -> String {
        if shouldRefreshToken() {
            try await refreshTokenIfNeeded()
        }
        
        guard let token = accessToken else {
            throw AuthError.notAuthenticated
        }
        
        return token
    }
    
    private func shouldRefreshToken() -> Bool {
        guard let expiresAt = expiresAt else { return false }
        let currentTime = Int(Date().timeIntervalSince1970)
        // Refresh if token expires in less than 5 minutes
        return currentTime > (expiresAt - 300)
    }
    
    @MainActor
    private func refreshTokenIfNeeded() async {
        guard let refreshToken = refreshToken else {
            clearAuthState()
            return
        }
        
        do {
            let response = try await APIService.shared.refreshToken(refreshToken: refreshToken)
            saveAuthState(response: response)
        } catch {
            print("Token refresh failed: \(error)")
            clearAuthState()
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        clearAuthState()
    }
}

// MARK: - Helper Types

private struct StoredAuthData: Codable {
    let user: User
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidCredentials:
            return "Invalid email or password"
        }
    }
}
