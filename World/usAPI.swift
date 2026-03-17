//
//  usAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation

class us {
    let newsApiKey = "fef3f022f2bf43fea36d30b094a86918"
    let nytApiKey = "TL3VGKKuG6jKAPcuLr9cAdeElaH30EFIdnUoTX0PV7vkY1ZQ"
    let guardianApiKey = "13e528ce-e5ed-497a-9cb5-5b993d720e1c"

    func fetchArticles() async throws -> [Article] {
        async let newsAPI = fetchNewsAPI()
        async let nyt = fetchNYT()
        async let guardian = fetchGuardian()

        let newsAPIArticles = try await Array(newsAPI.prefix(10))
        let nytArticles = try await Array(nyt.prefix(5))
        let guardianArticles = try await Array(guardian.prefix(5))

        return newsAPIArticles + nytArticles + guardianArticles
    }

    private func fetchNewsAPI() async throws -> [Article] {
        let url = URL(string: "https://newsapi.org/v2/top-headlines?sources=cnn,fox-news,msnbc,abc-news,cbs-news&apiKey=\(newsApiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let articles = json["articles"] as? [[String: Any]] ?? []

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

    private func fetchNYT() async throws -> [Article] {
        let url = URL(string: "https://api.nytimes.com/svc/topstories/v2/us.json?api-key=\(nytApiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let results = json["results"] as? [[String: Any]] ?? []

        return results.map { article in
            let multimedia = article["multimedia"] as? [[String: Any]]
            let imageUrl = multimedia?.first?["url"] as? String

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
        let url = URL(string: "https://content.guardianapis.com/us-news?order-by=newest&show-fields=thumbnail,trailText,webPublicationDate&api-key=\(guardianApiKey)")!
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
