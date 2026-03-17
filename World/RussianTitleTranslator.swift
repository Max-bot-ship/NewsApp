//
//  RussianTitleTranslator.swift
//  World
//
//  Created by Codex on 3/17/26.
//

import Foundation
import Translation
internal import UIKit

actor RussianTitleTranslator {
    static let shared = RussianTitleTranslator()

    private let sourceLanguage = Locale.Language(languageCode: .russian)
    private let targetLanguage = Locale.Language(languageCode: .english)
    private let availability = LanguageAvailability()
    private let session: TranslationSession
    private var didPrepare = false
    private var cache: [String: String] = [:]

    init() {
        if #available(iOS 26.0, *) {
            session = TranslationSession(installedSource: sourceLanguage, target: targetLanguage)
        } else {
            // Fallback: create a session with the same languages if the API is available at compile time; otherwise this path is never used on older OSes because we guard at call sites.
            session = TranslationSession(installedSource: sourceLanguage, target: targetLanguage)
        }
    }

    func translateTitlesIfNeeded(_ articles: [Article]) async -> [Article] {
        if #unavailable(iOS 26.0) {
            return articles
        }
        
        guard !articles.isEmpty else { return articles }

        do {
            if !didPrepare {
                if #available(iOS 26.0, *) {
                    let status = await availability.status(from: sourceLanguage, to: targetLanguage)
                    if status == .unsupported {
                        return articles
                    }
                }

                try await session.prepareTranslation()
                didPrepare = true
            }
        } catch {
            // If on-device translation isn't available, fall back to a simple web translation.
        }

        var updated = articles
        var requests: [TranslationSession.Request] = []
        for index in updated.indices {
            let title = updated[index].title
            if let cached = cache[title] {
                updated[index].title = cached
            } else {
                requests.append(.init(sourceText: title, clientIdentifier: "\(index)"))
            }
        }

        guard !requests.isEmpty else { return updated }

        var translatedIndices: Set<Int> = []

        do {
            let responses = try await session.translations(from: requests)
            for response in responses {
                guard let id = response.clientIdentifier, let index = Int(id) else { continue }
                cache[response.sourceText] = response.targetText
                if updated.indices.contains(index) {
                    updated[index].title = response.targetText
                    translatedIndices.insert(index)
                }
            }
        } catch {
            // Fall back below.
        }

        if translatedIndices.count < requests.count {
            for request in requests {
                guard let id = request.clientIdentifier, let index = Int(id) else { continue }
                guard !translatedIndices.contains(index) else { continue }
                if let translated = await translateViaFallback(request.sourceText) {
                    cache[request.sourceText] = translated
                    if updated.indices.contains(index) {
                        updated[index].title = translated
                    }
                }
            }
        }

        return updated
    }

    private func translateViaFallback(_ text: String) async -> String? {
        guard let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }

        let urlString = "https://api.mymemory.translated.net/get?q=\(encoded)&langpair=ru|en"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
            if let status = json["responseStatus"] as? Int, status != 200 {
                return nil
            }
            let responseData = json["responseData"] as? [String: Any]
            guard let raw = responseData?["translatedText"] as? String else { return nil }
            return normalizeTranslatedText(raw)
        } catch {
            return nil
        }
    }

    private func normalizeTranslatedText(_ text: String) -> String {
        var cleaned = text
        if let decoded = cleaned.removingPercentEncoding {
            cleaned = decoded
        }

        let data = Data(cleaned.utf8)
        if let attributed = try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        ) {
            cleaned = attributed.string
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
