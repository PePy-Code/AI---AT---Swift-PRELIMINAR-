import Foundation

#if canImport(FoundationModels)
import FoundationModels

@available(iOS 18.0, macOS 15.0, *)
public struct FoundationModelsLocalAgent: LocalAcademicAgentProviding {
    public init() {}

    public func supportMaterial(for topic: String, type: ActivityType) async throws -> [String] {
        guard type == .study || type == .task else { return [] }
        let session = LanguageModelSession()
        let prompt = """
        Genera 3 puntos de apoyo breves en español para estudiar el tema: \(topic).
        Devuelve cada punto en una línea separada y sin numeración.
        """
        let response = try await session.respond(to: prompt)
        return response
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .map(String.init)
    }

    public func triviaQuestions(
        count: Int,
        categories: [TriviaCategory],
        difficulty: Int
    ) async throws -> [TriviaQuestion] {
        let session = LanguageModelSession()
        let categoryPrompt = categories.map(\.rawValue).joined(separator: ", ")
        let prompt = """
        Genera \(count) preguntas de trivia en español de dificultad \(difficulty) para categorías: \(categoryPrompt).
        """
        _ = try await session.respond(to: prompt)
        return []
    }
}
#endif
