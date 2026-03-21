import Foundation

// A minimal placeholder AI service that produces a simple summary.
// Replace the implementation with a real AI backend when ready.
enum AIService {
    /// Produces a brief summary string for the given articles and feed name.
    /// Matches the call site in ContentView: `try await AIService.summaryOfToday(articles:feedName:)`
    static func summaryOfToday(articles: [Article], feedName: String) async throws -> String {
        // Very lightweight synthesized summary to unblock builds.
        // We limit to a few titles to keep it short.
        let titles = articles.prefix(5).map { $0.title }
        if titles.isEmpty {
            return "No stories yet."
        }
        let joined = titles.joined(separator: "; ")
        return "Top stories for \(feedName): \(joined)"
    }
}
