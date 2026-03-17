//
//  NewsAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation


struct Article: Identifiable {
    let id = UUID()
    var title: String
    var url: String
    var description: String?
    var imageUrl: String?
    var publishedAt: String?
}

private enum NewsAPIError: Error {
    case invalidURL
    case invalidPayload
}

private func decodeNewsAPIArticles(from data: Data) throws -> [Article] {
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let articles = json["articles"] as? [[String: Any]] else {
        throw NewsAPIError.invalidPayload
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


