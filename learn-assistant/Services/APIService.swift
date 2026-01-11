import Foundation

class APIService {
  static let shared = APIService()

  // 生产环境URL
  private let baseURL = "https://learn-assistant.aries-happy.com/api/ios"

  private init() {
    print("🌐 API Base URL: \(baseURL)")
  }

  // MARK: - Auth Methods

  func signIn(email: String, password: String) async throws -> AuthResponse {
    let url = URL(string: "\(baseURL)/auth/signin")!
    print("🔑 Sign in request to: \(url)")

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["email": email, "password": password]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    print("📊 Response status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
    if let responseString = String(data: data, encoding: .utf8) {
      print("📦 Response: \(responseString.prefix(200))")
    }

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(AuthResponse.self, from: data)
  }

  func signUp(email: String, password: String) async throws -> AuthResponse {
    let url = URL(string: "\(baseURL)/auth/signup")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["email": email, "password": password]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(AuthResponse.self, from: data)
  }

  func refreshToken(refreshToken: String) async throws -> AuthResponse {
    let url = URL(string: "\(baseURL)/auth/refresh")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ["refreshToken": refreshToken]
    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    return try JSONDecoder().decode(AuthResponse.self, from: data)
  }

  // MARK: - Knowledge Points Methods

  func getKnowledgePoints(accessToken: String, limit: Int = 20, offset: Int = 0) async throws
    -> [KnowledgePoint]
  {
    let url = URL(string: "\(baseURL)/knowledge?limit=\(limit)&offset=\(offset)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    let decodedResponse = try JSONDecoder().decode(KnowledgePointsResponse.self, from: data)
    return decodedResponse.points
  }

  func createKnowledgePoint(
    accessToken: String, question: String, answer: String, isInReviewPlan: Bool = true
  ) async throws -> KnowledgePoint {
    let url = URL(string: "\(baseURL)/knowledge")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = CreateKnowledgePointRequest(
      question: question, answer: answer, isInReviewPlan: isInReviewPlan)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    let responseData = try JSONDecoder().decode(KnowledgePointResponse.self, from: data)
    return responseData.point
  }

  func updateKnowledgePoint(
    accessToken: String, id: String, question: String, answer: String, isInReviewPlan: Bool? = nil
  ) async throws -> KnowledgePoint {
    let url = URL(string: "\(baseURL)/knowledge/\(id)")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = UpdateKnowledgePointRequest(
      question: question, answer: answer, isInReviewPlan: isInReviewPlan)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    let responseData = try JSONDecoder().decode(KnowledgePointResponse.self, from: data)
    return responseData.point
  }

  func deleteKnowledgePoint(accessToken: String, id: String) async throws {
    let url = URL(string: "\(baseURL)/knowledge/\(id)")!
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }
  }

  // MARK: - Review Methods

  func getTodayReviews(accessToken: String) async throws -> [ReviewSchedule] {
    let url = URL(string: "\(baseURL)/reviews")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    let decodedResponse = try JSONDecoder().decode(ReviewsResponse.self, from: data)
    return decodedResponse.reviews
  }

  func completeReview(accessToken: String, id: String, recallText: String?) async throws {
    let url = URL(string: "\(baseURL)/reviews/\(id)/complete")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = CompleteReviewRequest(recallText: recallText)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      if let error = try? JSONDecoder().decode(APIError.self, from: data) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }
  }

  // MARK: - Chat Methods

  func sendChatMessage(
    accessToken: String,
    message: String,
    history: [ChatHistoryMessage]? = nil,
    onContent: @escaping (String) -> Void,
    onSources: @escaping ([Source]) -> Void
  ) async throws {
    let url = URL(string: "\(baseURL)/chat")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = ChatRequest(message: message, history: history)
    request.httpBody = try JSONEncoder().encode(body)

    let (bytes, response) = try await URLSession.shared.bytes(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIServiceError.invalidResponse
    }

    if httpResponse.statusCode != 200 {
      // Try to read error message
      var errorData = Data()
      for try await byte in bytes {
        errorData.append(byte)
      }
      if let error = try? JSONDecoder().decode(APIError.self, from: errorData) {
        throw APIServiceError.serverError(error.error)
      }
      throw APIServiceError.httpError(httpResponse.statusCode)
    }

    // Parse Server-Sent Events stream
    var buffer = Data()
    for try await byte in bytes {
      buffer.append(byte)

      // Look for complete SSE messages (ending with \n\n)
      if let bufferString = String(data: buffer, encoding: .utf8),
        bufferString.contains("\n\n")
      {
        let parts = bufferString.components(separatedBy: "\n\n")

        // Process all complete messages except the last incomplete one
        for messageString in parts.dropLast() {
          let lines = messageString.components(separatedBy: "\n")
          for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }

            // Parse SSE format: "data: {...}"
            if trimmed.hasPrefix("data: ") {
              let jsonString = String(trimmed.dropFirst(6))  // Remove "data: "

              // Check for done signal
              if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                return
              }

              // Parse JSON
              guard let jsonData = jsonString.data(using: .utf8) else { continue }

              do {
                let event = try JSONDecoder().decode(StreamEvent.self, from: jsonData)
                switch event.type {
                case "sources":
                  if let sources = event.sources {
                    onSources(sources)
                  }
                case "content":
                  if let content = event.content {
                    onContent(content)
                  }
                default:
                  break
                }
              } catch {
                // Skip invalid JSON
                print("Failed to decode SSE event: \(error)")
                continue
              }
            }
          }
        }

        // Keep the last incomplete part in buffer
        if let lastPart = parts.last,
          let lastData = lastPart.data(using: .utf8)
        {
          buffer = lastData
        } else {
          buffer = Data()
        }
      }
    }

    // Process any remaining data in buffer
    if !buffer.isEmpty,
      let bufferString = String(data: buffer, encoding: .utf8)
    {
      let lines = bufferString.components(separatedBy: "\n")
      for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { continue }

        if trimmed.hasPrefix("data: ") {
          let jsonString = String(trimmed.dropFirst(6))
          if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
            return
          }

          guard let jsonData = jsonString.data(using: .utf8) else { continue }
          if let event = try? JSONDecoder().decode(StreamEvent.self, from: jsonData) {
            switch event.type {
            case "sources":
              if let sources = event.sources {
                onSources(sources)
              }
            case "content":
              if let content = event.content {
                onContent(content)
              }
            default:
              break
            }
          }
        }
      }
    }
  }
}

// MARK: - Error Types

enum APIServiceError: LocalizedError {
  case invalidResponse
  case httpError(Int)
  case serverError(String)
  case decodingError

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid response from server"
    case .httpError(let code):
      return "HTTP error: \(code)"
    case .serverError(let message):
      return message
    case .decodingError:
      return "Failed to decode response"
    }
  }
}
