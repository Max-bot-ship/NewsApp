//
//  nyctimesAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation

class nyctimes {
    let apiKey = "TL3VGKKuG6jKAPcuLr9cAdeElaH30EFIdnUoTX0PV7vkY1ZQ"
    
    func fetchArticles() async throws -> [Article] {
        let url = URL(string: "https://api.nytimes.com/svc/topstories/v2/home.json?api-key=\(apiKey)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let results = json["results"] as! [[String: Any]]
        
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
}
