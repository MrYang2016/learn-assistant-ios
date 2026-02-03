import Foundation

// MARK: - Knowledge Point Models (for compatibility with views)

/// 知识点模型 - 用于视图显示（从本地存储转换）
struct KnowledgePoint: Codable, Identifiable {
  let id: String
  let question: String
  let answer: String
  let createdAt: String
  let updatedAt: String
  let isInReviewPlan: Bool

  /// 从本地存储模型创建
  init(from local: LocalKnowledgePoint) {
    self.id = local.id
    self.question = local.question
    self.answer = local.answer
    self.createdAt = ISO8601DateFormatter().string(from: local.createdAt)
    self.updatedAt = ISO8601DateFormatter().string(from: local.updatedAt)
    self.isInReviewPlan = local.isInReviewPlan
  }

  init(
    id: String, question: String, answer: String, createdAt: String, updatedAt: String,
    isInReviewPlan: Bool
  ) {
    self.id = id
    self.question = question
    self.answer = answer
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.isInReviewPlan = isInReviewPlan
  }
}

// MARK: - Review Models

/// 复习日程模型 - 用于视图显示（从本地存储转换）
struct ReviewSchedule: Codable, Identifiable {
  let id: String
  let knowledgePointId: String
  let reviewNumber: Int
  let reviewDate: String
  let completed: Bool
  let completedAt: String?
  let recallText: String?
  let knowledgePoints: KnowledgePointInfo

  /// 从本地存储模型创建
  init(from local: LocalReviewSchedule, knowledgePoint: LocalKnowledgePoint?) {
    self.id = local.id
    self.knowledgePointId = local.knowledgePointId
    self.reviewNumber = local.reviewNumber
    self.reviewDate = ISO8601DateFormatter().string(from: local.reviewDate)
    self.completed = local.completed
    self.completedAt = local.completedAt.map { ISO8601DateFormatter().string(from: $0) }
    self.recallText = local.recallText
    self.knowledgePoints = KnowledgePointInfo(
      question: knowledgePoint?.question ?? "",
      answer: knowledgePoint?.answer ?? ""
    )
  }
}

/// 知识点信息 - 嵌套在复习日程中
struct KnowledgePointInfo: Codable {
  let question: String
  let answer: String
}

/// 复习响应
struct ReviewsResponse: Codable {
  let reviews: [ReviewSchedule]
  let total: Int
}

// MARK: - Request Models (保留用于兼容性)

struct CreateKnowledgePointRequest: Codable {
  let question: String
  let answer: String
  let isInReviewPlan: Bool
}

struct UpdateKnowledgePointRequest: Codable {
  let question: String
  let answer: String
  let isInReviewPlan: Bool?
}

struct CompleteReviewRequest: Codable {
  let recallText: String?
}

// MARK: - Error Models

enum LocalStorageError: LocalizedError {
  case notFound
  case saveFailed
  case loadFailed

  var errorDescription: String? {
    switch self {
    case .notFound:
      return "Item not found"
    case .saveFailed:
      return "Failed to save data"
    case .loadFailed:
      return "Failed to load data"
    }
  }
}
