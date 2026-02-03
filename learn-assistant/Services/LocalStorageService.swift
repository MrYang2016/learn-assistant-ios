import Foundation

/// 本地存储服务 - 所有数据存储在设备本地，保护用户隐私
class LocalStorageService {
  static let shared = LocalStorageService()

  private let knowledgePointsKey = "LearnAssistant.KnowledgePoints"
  private let reviewSchedulesKey = "LearnAssistant.ReviewSchedules"
  private let hasLaunchedKey = "LearnAssistant.HasLaunched"

  // 间隔重复算法的复习间隔（天数）
  private let reviewIntervals = [1, 7, 16, 35]

  private let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private init() {
    print("📱 LocalStorageService initialized - All data stored locally on device")
  }

  // MARK: - First Launch Check

  var hasLaunchedBefore: Bool {
    return UserDefaults.standard.bool(forKey: hasLaunchedKey)
  }

  func markAsLaunched() {
    UserDefaults.standard.set(true, forKey: hasLaunchedKey)
  }

  // MARK: - Knowledge Points CRUD

  func getAllKnowledgePoints() -> [LocalKnowledgePoint] {
    guard let data = UserDefaults.standard.data(forKey: knowledgePointsKey),
      let points = try? JSONDecoder().decode([LocalKnowledgePoint].self, from: data)
    else {
      return []
    }
    return points.sorted { $0.createdAt > $1.createdAt }
  }

  func getKnowledgePoints(limit: Int, offset: Int) -> [LocalKnowledgePoint] {
    let allPoints = getAllKnowledgePoints()
    let startIndex = min(offset, allPoints.count)
    let endIndex = min(startIndex + limit, allPoints.count)

    if startIndex >= endIndex {
      return []
    }

    return Array(allPoints[startIndex..<endIndex])
  }

  func createKnowledgePoint(question: String, answer: String, isInReviewPlan: Bool)
    -> LocalKnowledgePoint
  {
    var points = getAllKnowledgePoints()

    let now = Date()
    let newPoint = LocalKnowledgePoint(
      id: UUID().uuidString,
      question: question,
      answer: answer,
      createdAt: now,
      updatedAt: now,
      isInReviewPlan: isInReviewPlan
    )

    points.insert(newPoint, at: 0)
    saveKnowledgePoints(points)

    // 如果加入复习计划，创建复习日程
    if isInReviewPlan {
      createReviewSchedules(for: newPoint)
    }

    return newPoint
  }

  func updateKnowledgePoint(id: String, question: String, answer: String, isInReviewPlan: Bool?)
    -> LocalKnowledgePoint?
  {
    var points = getAllKnowledgePoints()

    guard let index = points.firstIndex(where: { $0.id == id }) else {
      return nil
    }

    let oldPoint = points[index]
    let newIsInReviewPlan = isInReviewPlan ?? oldPoint.isInReviewPlan

    let updatedPoint = LocalKnowledgePoint(
      id: oldPoint.id,
      question: question,
      answer: answer,
      createdAt: oldPoint.createdAt,
      updatedAt: Date(),
      isInReviewPlan: newIsInReviewPlan
    )

    points[index] = updatedPoint
    saveKnowledgePoints(points)

    // 如果复习计划状态改变，更新复习日程
    if oldPoint.isInReviewPlan != newIsInReviewPlan {
      if newIsInReviewPlan {
        createReviewSchedules(for: updatedPoint)
      } else {
        deleteReviewSchedules(forKnowledgePointId: id)
      }
    }

    return updatedPoint
  }

  func deleteKnowledgePoint(id: String) {
    var points = getAllKnowledgePoints()
    points.removeAll { $0.id == id }
    saveKnowledgePoints(points)

    // 删除相关的复习日程
    deleteReviewSchedules(forKnowledgePointId: id)
  }

  func getKnowledgePoint(byId id: String) -> LocalKnowledgePoint? {
    return getAllKnowledgePoints().first { $0.id == id }
  }

  private func saveKnowledgePoints(_ points: [LocalKnowledgePoint]) {
    if let data = try? JSONEncoder().encode(points) {
      UserDefaults.standard.set(data, forKey: knowledgePointsKey)
    }
  }

  // MARK: - Review Schedules

  func getAllReviewSchedules() -> [LocalReviewSchedule] {
    guard let data = UserDefaults.standard.data(forKey: reviewSchedulesKey),
      let schedules = try? JSONDecoder().decode([LocalReviewSchedule].self, from: data)
    else {
      return []
    }
    return schedules
  }

  func getTodayReviews(offset: Int = 0) -> (reviews: [LocalReviewSchedule], total: Int) {
    let allSchedules = getAllReviewSchedules()
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    // 筛选今天及之前未完成的复习
    let todayReviews = allSchedules.filter { schedule in
      !schedule.completed && schedule.reviewDate < tomorrow
    }.sorted { $0.reviewDate < $1.reviewDate }

    let total = todayReviews.count

    if offset >= todayReviews.count {
      return ([], total)
    }

    // 只返回一个复习项
    return ([todayReviews[offset]], total)
  }

  func completeReview(id: String, recallText: String?) {
    var schedules = getAllReviewSchedules()

    if let index = schedules.firstIndex(where: { $0.id == id }) {
      let oldSchedule = schedules[index]
      let completedSchedule = LocalReviewSchedule(
        id: oldSchedule.id,
        knowledgePointId: oldSchedule.knowledgePointId,
        reviewNumber: oldSchedule.reviewNumber,
        reviewDate: oldSchedule.reviewDate,
        completed: true,
        completedAt: Date(),
        recallText: recallText
      )
      schedules[index] = completedSchedule
      saveReviewSchedules(schedules)
    }
  }

  private func createReviewSchedules(for point: LocalKnowledgePoint) {
    var schedules = getAllReviewSchedules()
    let today = Calendar.current.startOfDay(for: Date())

    for (index, interval) in reviewIntervals.enumerated() {
      let reviewDate = Calendar.current.date(byAdding: .day, value: interval, to: today)!

      let schedule = LocalReviewSchedule(
        id: UUID().uuidString,
        knowledgePointId: point.id,
        reviewNumber: index + 1,
        reviewDate: reviewDate,
        completed: false,
        completedAt: nil,
        recallText: nil
      )
      schedules.append(schedule)
    }

    saveReviewSchedules(schedules)
  }

  private func deleteReviewSchedules(forKnowledgePointId id: String) {
    var schedules = getAllReviewSchedules()
    schedules.removeAll { $0.knowledgePointId == id }
    saveReviewSchedules(schedules)
  }

  private func saveReviewSchedules(_ schedules: [LocalReviewSchedule]) {
    if let data = try? JSONEncoder().encode(schedules) {
      UserDefaults.standard.set(data, forKey: reviewSchedulesKey)
    }
  }

  // MARK: - Data Export/Import (for backup)

  func exportData() -> Data? {
    let exportData = ExportData(
      knowledgePoints: getAllKnowledgePoints(),
      reviewSchedules: getAllReviewSchedules()
    )
    return try? JSONEncoder().encode(exportData)
  }

  func importData(_ data: Data) -> Bool {
    guard let importData = try? JSONDecoder().decode(ExportData.self, from: data) else {
      return false
    }

    saveKnowledgePoints(importData.knowledgePoints)
    saveReviewSchedules(importData.reviewSchedules)
    return true
  }

  // MARK: - Statistics

  func getStatistics() -> StorageStatistics {
    let points = getAllKnowledgePoints()
    let schedules = getAllReviewSchedules()
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    let todayReviews = schedules.filter { !$0.completed && $0.reviewDate < tomorrow }
    let completedToday = schedules.filter {
      $0.completed && $0.completedAt != nil && Calendar.current.isDateInToday($0.completedAt!)
    }

    return StorageStatistics(
      totalKnowledgePoints: points.count,
      pointsInReviewPlan: points.filter { $0.isInReviewPlan }.count,
      pendingReviewsToday: todayReviews.count,
      completedReviewsToday: completedToday.count
    )
  }
}

// MARK: - Local Models

struct LocalKnowledgePoint: Codable, Identifiable {
  let id: String
  let question: String
  let answer: String
  let createdAt: Date
  let updatedAt: Date
  let isInReviewPlan: Bool
}

struct LocalReviewSchedule: Codable, Identifiable {
  let id: String
  let knowledgePointId: String
  let reviewNumber: Int
  let reviewDate: Date
  let completed: Bool
  let completedAt: Date?
  let recallText: String?
}

struct ExportData: Codable {
  let knowledgePoints: [LocalKnowledgePoint]
  let reviewSchedules: [LocalReviewSchedule]
}

struct StorageStatistics {
  let totalKnowledgePoints: Int
  let pointsInReviewPlan: Int
  let pendingReviewsToday: Int
  let completedReviewsToday: Int
}
