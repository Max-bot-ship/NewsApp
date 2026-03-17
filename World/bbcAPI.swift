//
//  bbcAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

//
//  bbcAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation

class bbc {
    let apiKey = "fef3f022f2bf43fea36d30b094a86918"

    func fetchArticles() async throws -> [Article] {
        guard let url = URL(string: "https://newsapi.org/v2/top-headlines?sources=bbc-news&apiKey=\(apiKey)") else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let articles = json["articles"] as? [[String: Any]] else {
            throw URLError(.cannotParseResponse)
        }

        return articles.map { article in
            Article(
                title: article["title"] as? String ?? "",
                url: article["url"] as? String ?? "",
                description: article["description"] as? String,
                imageUrl: article["urlToImage"] as? String,
                publishedAt: article["publishedAt"] as? String
            )
        }
    }

    func fetchArticle(matchingURL selectedURL: String) async throws -> Article? {
        let articles = try await fetchArticles()
        let normalizedSelected = normalizedURLString(selectedURL)

        return articles.first { article in
            normalizedURLString(article.url) == normalizedSelected
        }
    }

    private func normalizedURLString(_ rawURL: String) -> String {
        guard let components = URLComponents(string: rawURL) else {
            return rawURL.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }

        var normalized = components
        normalized.query = nil
        normalized.fragment = nil

        let cleaned = (normalized.string ?? rawURL)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return cleaned.hasSuffix("/") ? String(cleaned.dropLast()) : cleaned
    }
}
