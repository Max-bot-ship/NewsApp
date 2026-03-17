//
//  guardianAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//


//
//  guardian.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

//
//  GuardianAPI.swift
//  World
//
//  Created by Skyler on 2/28/26.
//

import Foundation

class guardian {
    let apiKey = "13e528ce-e5ed-497a-9cb5-5b993d720e1c"

    func fetchArticles(section: String = "world") async throws -> [Article] {
        let url = URL(string: "https://content.guardianapis.com/\(section)?order-by=newest&show-fields=thumbnail,trailText,webPublicationDate&api-key=\(apiKey)")!
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
}
