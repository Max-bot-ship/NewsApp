//
//  Untitled.swift
//  World
//
//  Created by Skyler on 3/17/26.
//
import Foundation


class ru {
    let newsApiKey = "fef3f022f2bf43fea36d30b094a86918"
    
    func fetchArticles() async throws -> [Article] {
        do {
            let topHeadlines = try await fetchTopHeadlines()
            if !topHeadlines.isEmpty {
                return Array(topHeadlines.prefix(20))
            }
        } catch {
            // Fall through to the broader search if headlines fail.
        }

        let fallbackArticles = try await fetchEverything()
        return Array(fallbackArticles.prefix(20))
    }
    
    private func fetchTopHeadlines() async throws -> [Article] {
        let url = URL(string: "https://newsapi.org/v2/top-headlines?country=ru&apiKey=\(newsApiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decodeArticles(from: data)
    }

    private func fetchEverything() async throws -> [Article] {
        let url = URL(string: "https://newsapi.org/v2/everything?q=Russia&language=ru&sortBy=publishedAt&apiKey=\(newsApiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decodeArticles(from: data)
    }

    private func decodeArticles(from data: Data) throws -> [Article] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw RUAPIError.invalidPayload
        }

        if let status = json["status"] as? String, status != "ok" {
            let message = json["message"] as? String ?? "Unknown NewsAPI error"
            throw RUAPIError.apiError(message)
        }

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
}

private enum RUAPIError: Error {
    case invalidPayload
    case apiError(String)
}
