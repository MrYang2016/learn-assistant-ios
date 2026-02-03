import Foundation

@MainActor
class KnowledgeViewModel: ObservableObject {
  @Published var knowledgePoints: [KnowledgePoint] = []
  @Published var isLoading = false
  @Published var error: String?

  private var offset = 0
  private let limit = 20
  private var hasMore = true

  private let storageService = LocalStorageService.shared

  init() {
    // 不再需要 AuthService
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

    // 从本地存储加载
    let localPoints = storageService.getKnowledgePoints(limit: limit, offset: offset)

    if localPoints.count < limit {
      hasMore = false
    }

    // 转换为视图模型
    let points = localPoints.map { KnowledgePoint(from: $0) }
    knowledgePoints.append(contentsOf: points)
    offset += points.count

    isLoading = false
  }

  func createKnowledgePoint(question: String, answer: String, isInReviewPlan: Bool = true)
    async throws
  {
    let localPoint = storageService.createKnowledgePoint(
      question: question,
      answer: answer,
      isInReviewPlan: isInReviewPlan
    )

    let newPoint = KnowledgePoint(from: localPoint)
    knowledgePoints.insert(newPoint, at: 0)
  }

  func updateKnowledgePoint(
    id: String, question: String, answer: String, isInReviewPlan: Bool? = nil
  ) async throws {
    guard
      let updatedLocalPoint = storageService.updateKnowledgePoint(
        id: id,
        question: question,
        answer: answer,
        isInReviewPlan: isInReviewPlan
      )
    else {
      throw LocalStorageError.notFound
    }

    let updatedPoint = KnowledgePoint(from: updatedLocalPoint)

    if let index = knowledgePoints.firstIndex(where: { $0.id == id }) {
      knowledgePoints[index] = updatedPoint
    }
  }

  func deleteKnowledgePoint(id: String) async throws {
    storageService.deleteKnowledgePoint(id: id)
    knowledgePoints.removeAll { $0.id == id }
  }
}
