import Foundation

// MARK: - User & Auth Models

struct User: Codable, Identifiable {
  let id: String
  let email: String?
  let createdAt: String?

  enum CodingKeys: String, CodingKey {
    case id
    case email
    case createdAt = "created_at"
  }
}

struct AuthResponse: Codable {
  let user: User
  let accessToken: String
  let refreshToken: String
  let expiresAt: Int

  enum CodingKeys: String, CodingKey {
    case user
    case accessToken
    case refreshToken
    case expiresAt
  }
}

// MARK: - Knowledge Point Models

struct KnowledgePoint: Codable, Identifiable {
  let id: String
  let userId: String
  let question: String
  let answer: String
  let createdAt: String
  let updatedAt: String
  let isInReviewPlan: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case question
    case answer
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case isInReviewPlan = "is_in_review_plan"
  }
}

struct KnowledgePointsResponse: Codable {
  let points: [KnowledgePoint]
}

struct KnowledgePointResponse: Codable {
  let point: KnowledgePoint
}

// MARK: - Review Models

struct ReviewSchedule: Codable, Identifiable {
  let id: String
  let knowledgePointId: String
  let reviewNumber: Int
  let reviewDate: String
  let completed: Bool
  let completedAt: String?
  let recallText: String?
  let knowledgePoints: KnowledgePointInfo

  enum CodingKeys: String, CodingKey {
    case id
    case knowledgePointId = "knowledge_point_id"
    case reviewNumber = "review_number"
    case reviewDate = "review_date"
    case completed
    case completedAt = "completed_at"
    case recallText = "recall_text"
    case knowledgePoints = "knowledge_points"
  }
}

struct KnowledgePointInfo: Codable {
  let question: String
  let answer: String
}

struct ReviewsResponse: Codable {
  let reviews: [ReviewSchedule]
}

// MARK: - Chat Models

struct ChatMessage: Identifiable {
  let id = UUID()
  let role: MessageRole
  let content: String
  let timestamp: Date
}

enum MessageRole: String, Codable {
  case user
  case assistant
}

struct ChatRequest: Codable {
  let message: String
  let history: [ChatHistoryMessage]?
}

struct ChatHistoryMessage: Codable {
  let role: String
  let content: String
}

struct ChatResponse: Codable {
  let response: String
  let sources: [Source]?
}

struct StreamEvent: Codable {
  let type: String
  let content: String?
  let sources: [Source]?
}

struct Source: Codable, Identifiable {
  let id: String
  let question: String
  let answer: String
  let similarity: Double
}

// MARK: - Error Models

struct APIError: Codable {
  let error: String
}

// MARK: - Request Models

struct CreateKnowledgePointRequest: Codable {
  let question: String
  let answer: String
  let isInReviewPlan: Bool

  enum CodingKeys: String, CodingKey {
    case question
    case answer
    case isInReviewPlan
  }
}

struct UpdateKnowledgePointRequest: Codable {
  let question: String
  let answer: String
  let isInReviewPlan: Bool?

  enum CodingKeys: String, CodingKey {
    case question
    case answer
    case isInReviewPlan
  }
}

struct CompleteReviewRequest: Codable {
  let recallText: String?

  enum CodingKeys: String, CodingKey {
    case recallText
  }
}
