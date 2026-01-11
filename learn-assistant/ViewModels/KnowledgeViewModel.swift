import Foundation

@MainActor
class KnowledgeViewModel: ObservableObject {
    @Published var knowledgePoints: [KnowledgePoint] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let authService: AuthService
    private var offset = 0
    private let limit = 20
    private var hasMore = true
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    func loadKnowledgePoints(refresh: Bool = false) async {
        if refresh {
            offset = 0
            hasMore = true
            knowledgePoints = []
        }
        
        guard hasMore, !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let token = try await authService.getAccessToken()
            let points = try await APIService.shared.getKnowledgePoints(
                accessToken: token,
                limit: limit,
                offset: offset
            )
            
            if points.count < limit {
                hasMore = false
            }
            
            knowledgePoints.append(contentsOf: points)
            offset += points.count
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createKnowledgePoint(question: String, answer: String, isInReviewPlan: Bool = true) async throws {
        let token = try await authService.getAccessToken()
        let newPoint = try await APIService.shared.createKnowledgePoint(
            accessToken: token,
            question: question,
            answer: answer,
            isInReviewPlan: isInReviewPlan
        )
        
        knowledgePoints.insert(newPoint, at: 0)
    }
    
    func updateKnowledgePoint(id: String, question: String, answer: String, isInReviewPlan: Bool? = nil) async throws {
        let token = try await authService.getAccessToken()
        let updatedPoint = try await APIService.shared.updateKnowledgePoint(
            accessToken: token,
            id: id,
            question: question,
            answer: answer,
            isInReviewPlan: isInReviewPlan
        )
        
        if let index = knowledgePoints.firstIndex(where: { $0.id == id }) {
            knowledgePoints[index] = updatedPoint
        }
    }
    
    func deleteKnowledgePoint(id: String) async throws {
        let token = try await authService.getAccessToken()
        try await APIService.shared.deleteKnowledgePoint(accessToken: token, id: id)
        
        knowledgePoints.removeAll { $0.id == id }
    }
}
