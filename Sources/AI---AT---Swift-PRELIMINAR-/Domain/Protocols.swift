import Foundation

public protocol AppleIntelligenceProviding: Sendable {
    func supportMaterial(for topic: String, type: ActivityType) async throws -> [String]
    func triviaQuestions(
        count: Int,
        categories: [TriviaCategory],
        difficulty: Int
    ) async throws -> [TriviaQuestion]
}

public protocol NotificationScheduling: Sendable {
    func schedule(_ message: NotificationMessage, id: String, on day: Date) async
}

public protocol DateProviding: Sendable {
    var now: Date { get }
}

public struct SystemDateProvider: DateProviding {
    public init() {}
    public var now: Date { Date() }
}
