//
//  techAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation

class tech {
    let newsApiKey = "fef3f022f2bf43fea36d30b094a86918"
    let nytApiKey = "TL3VGKKuG6jKAPcuLr9cAdeElaH30EFIdnUoTX0PV7vkY1ZQ"

    func fetchArticles() async throws -> [Article] {
        async let verge = fetchNewsAPI(source: "the-verge")
        async let techcrunch = fetchNewsAPI(source: "techcrunch")
        async let nyt = fetchNYT()
        async let hackerNews = fetchHackerNews()

        let vergeArticles = try await Array(verge.prefix(5))
        let techcrunchArticles = try await Array(techcrunch.prefix(5))
        let nytArticles = try await Array(nyt.prefix(5))
        let hackerNewsArticles = try await Array(hackerNews.prefix(5))
        let newsAPIArticles = vergeArticles + techcrunchArticles
        
        return Array(newsAPIArticles.prefix(10)) + nytArticles + hackerNewsArticles
    }

    private func fetchNewsAPI(source: String) async throws -> [Article] {
        let url = URL(string: "https://newsapi.org/v2/top-headlines?sources=\(source)&apiKey=\(newsApiKey)")!
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
        let url = URL(string: "https://api.nytimes.com/svc/topstories/v2/technology.json?api-key=\(nytApiKey)")!
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

    private func fetchHackerNews() async throws -> [Article] {
        let topStoriesURL = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!
        let (data, _) = try await URLSession.shared.data(from: topStoriesURL)
        let ids = try JSONDecoder().decode([Int].self, from: data)

        var articles: [Article] = []

        try await withThrowingTaskGroup(of: Article?.self) { group in
            for id in ids.prefix(5) {
                group.addTask {
                    let itemURL = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
                    let (itemData, _) = try await URLSession.shared.data(from: itemURL)
                    let item = try JSONSerialization.jsonObject(with: itemData) as! [String: Any]

                    guard let title = item["title"] as? String,
                          let url = item["url"] as? String else { return nil }

                    return Article(
                        title: title,
                        url: url,
                        description: nil,
                        imageUrl: nil,
                        publishedAt: nil
                    )
                }
            }

            for try await article in group {
                if let article { articles.append(article) }
            }
        }

        return articles
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

private func fetchHackerNews() async throws -> [Article] {
    let topStoriesURL = URL(string: "https://hacker-news.firebaseio.com/v0/topstories.json")!
    let (data, _) = try await URLSession.shared.data(from: topStoriesURL)
    let ids = try JSONDecoder().decode([Int].self, from: data)

    var articles: [Article] = []

    try await withThrowingTaskGroup(of: Article?.self) { group in
        for id in ids.prefix(20) {
            group.addTask {
                let itemURL = URL(string: "https://hacker-news.firebaseio.com/v0/item/\(id).json")!
                let (itemData, _) = try await URLSession.shared.data(from: itemURL)
                let item = try JSONSerialization.jsonObject(with: itemData) as! [String: Any]

                guard let title = item["title"] as? String,
                      let url = item["url"] as? String else { return nil }

                return Article(
                    title: title,
                    url: url,
                    description: nil,
                    imageUrl: nil,
                    publishedAt: nil
                )
            }
        }

        for try await article in group {
            if let article, articles.count < 5 {
                articles.append(article)
            }
        }
    }

    return articles
}
