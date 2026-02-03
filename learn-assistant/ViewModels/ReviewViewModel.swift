import Foundation

@MainActor
class ReviewViewModel: ObservableObject {
  @Published var currentReview: ReviewSchedule?
  @Published var currentIndex = 0
  @Published var totalCount = 0
  @Published var isLoading = false
  @Published var error: String?
  @Published var showAnswer = false
  @Published var recallText = ""

  private let storageService = LocalStorageService.shared

  init() {
    // 不再需要 AuthService
  }

  var hasMoreReviews: Bool {
    currentIndex < totalCount - 1
  }

  var completedCount: Int {
    currentIndex
  }

  func loadReviews() async {
    isLoading = true
    error = nil

    // 从本地存储加载今天的复习
    let (reviews, total) = loadTodayReviewsFromStorage(offset: 0)

    totalCount = total
    currentReview = reviews.first
    currentIndex = 0
    showAnswer = false
    recallText = ""

    isLoading = false
  }

  func loadNextReview() async {
    guard hasMoreReviews else { return }

    isLoading = true
    error = nil

    let nextIndex = currentIndex + 1
    let (reviews, _) = loadTodayReviewsFromStorage(offset: nextIndex)

    currentReview = reviews.first
    currentIndex = nextIndex
    showAnswer = false
    recallText = ""

    isLoading = false
  }

  func completeCurrentReview() async {
    guard let review = currentReview else {
      return
    }

    isLoading = true
    error = nil

    // 完成复习并保存到本地
    storageService.completeReview(
      id: review.id,
      recallText: recallText.isEmpty ? nil : recallText
    )

    // Move to next review
    if hasMoreReviews {
      await loadNextReview()
    } else {
      // All reviews completed
      currentIndex = totalCount
      currentReview = nil
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

  // MARK: - Private Methods

  private func loadTodayReviewsFromStorage(offset: Int) -> ([ReviewSchedule], Int) {
    let (localReviews, total) = storageService.getTodayReviews(offset: offset)

    let reviews = localReviews.compactMap { localSchedule -> ReviewSchedule? in
      let knowledgePoint = storageService.getKnowledgePoint(byId: localSchedule.knowledgePointId)
      return ReviewSchedule(from: localSchedule, knowledgePoint: knowledgePoint)
    }

    return (reviews, total)
  }
}
