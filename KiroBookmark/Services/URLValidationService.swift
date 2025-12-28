//
//  URLValidationService.swift
//  KiroBookmark
//
//  Service for URL validation and metadata extraction
//

import Foundation

// MARK: - URLValidationServiceProtocol

protocol URLValidationServiceProtocol {
    func validate(_ urlString: String) -> URLValidationResult
    func extractDomain(from urlString: String) -> String?
    func normalizeURL(_ urlString: String) -> String?
    func fetchMetadata(from url: URL) async throws -> URLMetadata
}

// MARK: - URLValidationResult

struct URLValidationResult {
    let isValid: Bool
    let normalizedURL: String?
    let domain: String?
    let errorMessage: String?

    static func valid(url: String, domain: String) -> URLValidationResult {
        URLValidationResult(isValid: true, normalizedURL: url, domain: domain, errorMessage: nil)
    }

    static func invalid(_ message: String) -> URLValidationResult {
        URLValidationResult(isValid: false, normalizedURL: nil, domain: nil, errorMessage: message)
    }
}

// MARK: - URLMetadata

struct URLMetadata {
    let title: String
    let description: String?
    let imageURL: String?
    let publishedDate: Date?
}

// MARK: - URLValidationService

final class URLValidationService: URLValidationServiceProtocol {

    // MARK: - Validation

    func validate(_ urlString: String) -> URLValidationResult {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .invalid("URLを入力してください")
        }

        guard let normalized = normalizeURL(trimmed) else {
            return .invalid("無効なURL形式です")
        }

        // Task6 User Test Fix: HTTPSスキームのみ許可（セキュリティ強化）
        guard let url = URL(string: normalized),
              let scheme = url.scheme,
              scheme.lowercased() == "https" else {
            return .invalid("https://で始まる正しいURLを入力してください")
        }

        guard let domain = extractDomain(from: normalized) else {
            return .invalid("ドメインを取得できません")
        }

        return .valid(url: normalized, domain: domain)
    }

    // MARK: - Domain Extraction

    func extractDomain(from urlString: String) -> String? {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return nil
        }
        return host.replacingOccurrences(of: "www.", with: "")
    }

    // MARK: - URL Normalization

    func normalizeURL(_ urlString: String) -> String? {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        if !normalized.lowercased().hasPrefix("http://") &&
           !normalized.lowercased().hasPrefix("https://") {
            normalized = "https://" + normalized
        }

        guard URL(string: normalized) != nil else {
            return nil
        }

        // Remove trailing slash if path has content
        if normalized.hasSuffix("/") {
            let withoutSlash = String(normalized.dropLast())
            if let url = URL(string: withoutSlash), url.path != "" {
                normalized = withoutSlash
            }
        }

        return normalized
    }

    // MARK: - Metadata Fetching

    func fetchMetadata(from url: URL) async throws -> URLMetadata {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLValidationError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw URLValidationError.invalidContent
        }

        let title = extractTitle(from: html) ?? url.host ?? "Untitled"
        let description = extractMetaContent(from: html, property: "og:description")
                       ?? extractMetaContent(from: html, name: "description")
        let imageURL = extractMetaContent(from: html, property: "og:image")

        return URLMetadata(
            title: title,
            description: description,
            imageURL: imageURL,
            publishedDate: nil
        )
    }

    // MARK: - HTML Parsing Helpers

    private func extractTitle(from html: String) -> String? {
        if let ogTitle = extractMetaContent(from: html, property: "og:title") {
            return ogTitle
        }

        let pattern = "<title[^>]*>([^<]+)</title>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html) else {
            return nil
        }

        return String(html[range])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
    }

    private func extractMetaContent(from html: String, property: String) -> String? {
        let pattern = "<meta[^>]+property=[\"']\(property)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        let altPattern = "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']\(property)[\"']"

        for p in [pattern, altPattern] {
            if let regex = try? NSRegularExpression(pattern: p, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        return nil
    }

    private func extractMetaContent(from html: String, name: String) -> String? {
        let pattern = "<meta[^>]+name=[\"']\(name)[\"'][^>]+content=[\"']([^\"']+)[\"']"
        let altPattern = "<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']\(name)[\"']"

        for p in [pattern, altPattern] {
            if let regex = try? NSRegularExpression(pattern: p, options: .caseInsensitive),
               let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                return String(html[range])
            }
        }
        return nil
    }
}

// MARK: - URLValidationError

enum URLValidationError: Error, LocalizedError {
    case invalidURL
    case fetchFailed
    case invalidContent

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            // Task6 User Test Fix: より具体的なエラーメッセージ
            return "無効なURLです。https://で始まる正しいURLを入力してください"
        case .fetchFailed:
            return "ページの取得に失敗しました"
        case .invalidContent:
            return "ページの内容を解析できません"
        }
    }
}
