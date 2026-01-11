import Foundation

@MainActor
class ReviewViewModel: ObservableObject {
    @Published var reviews: [ReviewSchedule] = []
    @Published var currentIndex = 0
    @Published var isLoading = false
    @Published var error: String?
    @Published var showAnswer = false
    @Published var recallText = ""
    
    private let authService: AuthService
    
    init(authService: AuthService) {
        self.authService = authService
    }
    
    var currentReview: ReviewSchedule? {
        guard currentIndex < reviews.count else { return nil }
        return reviews[currentIndex]
    }
    
    var hasMoreReviews: Bool {
        currentIndex < reviews.count - 1
    }
    
    var completedCount: Int {
        currentIndex
    }
    
    var totalCount: Int {
        reviews.count
    }
    
    func loadReviews() async {
        isLoading = true
        error = nil
        
        do {
            let token = try await authService.getAccessToken()
            reviews = try await APIService.shared.getTodayReviews(accessToken: token)
            currentIndex = 0
            showAnswer = false
            recallText = ""
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func completeCurrentReview() async {
        guard let review = currentReview else { return }
        
        isLoading = true
        error = nil
        
        do {
            let token = try await authService.getAccessToken()
            try await APIService.shared.completeReview(
                accessToken: token,
                id: review.id,
                recallText: recallText.isEmpty ? nil : recallText
            )
            
            // Move to next review
            if hasMoreReviews {
                currentIndex += 1
                showAnswer = false
                recallText = ""
            } else {
                // All reviews completed
                currentIndex = reviews.count
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleAnswer() {
        showAnswer.toggle()
    }
    
    func resetReviews() {
        currentIndex = 0
        showAnswer = false
        recallText = ""
    }
}
