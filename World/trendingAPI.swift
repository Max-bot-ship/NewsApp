//
//  WorldAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation

class trending {
    let nytApiKey = "TL3VGKKuG6jKAPcuLr9cAdeElaH30EFIdnUoTX0PV7vkY1ZQ"
    let guardianApiKey = "13e528ce-e5ed-497a-9cb5-5b993d720e1c"

    func fetchArticles() async throws -> [Article] {
        async let nyt = fetchNYT()
        async let guardian = fetchGuardian()

        let nytArticles = try await Array(nyt.prefix(1))
        let guardianArticles = try await Array(guardian.prefix(1))

        return nytArticles + guardianArticles
    }

    private func fetchNYT() async throws -> [Article] {
        let url = URL(string: "https://api.nytimes.com/svc/mostpopular/v2/viewed/1.json?api-key=\(nytApiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let results = json["results"] as? [[String: Any]] ?? []

        return results.map { article in
            let multimedia = article["media"] as? [[String: Any]]
            let metadataList = multimedia?.first?["media-metadata"] as? [[String: Any]]
            let imageUrl = metadataList?.last?["url"] as? String

            return Article(
                title: article["title"] as? String ?? "",
                url: article["url"] as? String ?? "",
                description: article["abstract"] as? String,
                imageUrl: imageUrl,
                publishedAt: article["published_date"] as? String
            )
        }
    }

    private func fetchGuardian() async throws -> [Article] {
        let url = URL(string: "https://content.guardianapis.com/world?order-by=relevance&show-most-viewed=true&show-fields=thumbnail,trailText,webPublicationDate&api-key=\(guardianApiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let response = json["response"] as? [String: Any] ?? [:]
        let results = response["results"] as? [[String: Any]] ?? []

        return results.map { article in
            let fields = article["fields"] as? [String: Any]

            return Article(
                title: article["webTitle"] as? String ?? "",
                url: article["webUrl"] as? String ?? "",
                description: fields?["trailText"] as? String,
                imageUrl: fields?["thumbnail"] as? String,
                publishedAt: fields?["webPublicationDate"] as? String
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
