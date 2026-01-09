//
//  RSSService.swift
//  KiroBookmark
//
//  Service for RSS/Atom feed detection, parsing, and fetching
//

import Foundation

// MARK: - RSSServiceProtocol

protocol RSSServiceProtocol {
    func detectFeed(from url: URL) async throws -> [URL]
    func fetchFeedMetadata(from feedURL: URL) async throws -> RSSFeedMetadata
    func fetchLatestArticles(from feedURL: URL, blogName: String) async throws -> [RSSArticle]
    func refreshAllFeeds(blogs: [(domain: String, name: String, rssURL: URL)]) async throws -> [RSSArticle]
}

// MARK: - RSSService

final class RSSService: RSSServiceProtocol {

    private let urlSession: URLSession

    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    @MainActor
    convenience init() {
        self.init(urlSession: .shared)
    }

    // MARK: - Feed Detection

    func detectFeed(from url: URL) async throws -> [URL] {
        let (data, response) = try await urlSession.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RSSServiceError.fetchFailed
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw RSSServiceError.invalidContent
        }

        return extractFeedURLs(from: html, baseURL: url)
    }

    private func extractFeedURLs(from html: String, baseURL: URL) -> [URL] {
        var feedURLs: [URL] = []

        // Pattern for RSS/Atom link tags
        let patterns = [
            "<link[^>]+type=[\"']application/rss\\+xml[\"'][^>]+href=[\"']([^\"']+)[\"']",
            "<link[^>]+href=[\"']([^\"']+)[\"'][^>]+type=[\"']application/rss\\+xml[\"']",
            "<link[^>]+type=[\"']application/atom\\+xml[\"'][^>]+href=[\"']([^\"']+)[\"']",
            "<link[^>]+href=[\"']([^\"']+)[\"'][^>]+type=[\"']application/atom\\+xml[\"']"
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(html.startIndex..., in: html)
                let matches = regex.matches(in: html, range: range)

                for match in matches {
                    if let urlRange = Range(match.range(at: 1), in: html) {
                        let urlString = String(html[urlRange])
                        if let feedURL = resolveURL(urlString, baseURL: baseURL) {
                            if !feedURLs.contains(feedURL) {
                                feedURLs.append(feedURL)
                            }
                        }
                    }
                }
            }
        }

        // Try site-specific feed URLs if no link tags found
        if feedURLs.isEmpty {
            feedURLs = trySiteSpecificFeedURLs(baseURL: baseURL)
        }

        // Try common feed paths as last resort
        if feedURLs.isEmpty {
            feedURLs = tryCommonFeedPaths(baseURL: baseURL)
        }

        return feedURLs
    }

    // MARK: - Site-Specific Feed Detection

    private func trySiteSpecificFeedURLs(baseURL: URL) -> [URL] {
        guard let host = baseURL.host?.lowercased() else { return [] }

        // Qiita: https://qiita.com/{username}/feed
        if host == "qiita.com" {
            return tryQiitaFeedURL(baseURL: baseURL)
        }

        // Zenn: https://zenn.dev/{username}/feed
        if host == "zenn.dev" {
            return tryZennFeedURL(baseURL: baseURL)
        }

        // note: https://note.com/{username}/rss
        if host == "note.com" {
            return tryNoteFeedURL(baseURL: baseURL)
        }

        // Medium: https://medium.com/feed/@username
        if host == "medium.com" {
            return tryMediumFeedURL(baseURL: baseURL)
        }

        // Dev.to: https://dev.to/feed/username
        if host == "dev.to" {
            return tryDevToFeedURL(baseURL: baseURL)
        }

        return []
    }

    private func tryQiitaFeedURL(baseURL: URL) -> [URL] {
        // Extract username from path
        // Pattern: /username or /username/items/xxx
        let pathComponents = baseURL.pathComponents.filter { $0 != "/" }
        guard let username = pathComponents.first, !username.isEmpty else { return [] }

        // Skip if username looks like a system path
        let systemPaths = ["search", "tags", "organizations", "advent-calendar", "timeline"]
        if systemPaths.contains(username) { return [] }

        let feedURLString = "https://qiita.com/\(username)/feed"
        if let feedURL = URL(string: feedURLString) {
            return [feedURL]
        }
        return []
    }

    private func tryZennFeedURL(baseURL: URL) -> [URL] {
        // Extract username from path
        // Pattern: /username or /username/articles/xxx
        let pathComponents = baseURL.pathComponents.filter { $0 != "/" }
        guard let username = pathComponents.first, !username.isEmpty else { return [] }

        // Skip if username looks like a system path
        let systemPaths = ["search", "topics", "scraps", "books"]
        if systemPaths.contains(username) { return [] }

        let feedURLString = "https://zenn.dev/\(username)/feed"
        if let feedURL = URL(string: feedURLString) {
            return [feedURL]
        }
        return []
    }

    private func tryNoteFeedURL(baseURL: URL) -> [URL] {
        // Extract username from path
        // Pattern: /username or /username/n/xxx
        let pathComponents = baseURL.pathComponents.filter { $0 != "/" }
        guard let username = pathComponents.first, !username.isEmpty else { return [] }

        // Skip if username looks like a system path
        let systemPaths = ["search", "hashtag", "explore", "magazines"]
        if systemPaths.contains(username) { return [] }

        let feedURLString = "https://note.com/\(username)/rss"
        if let feedURL = URL(string: feedURLString) {
            return [feedURL]
        }
        return []
    }

    private func tryMediumFeedURL(baseURL: URL) -> [URL] {
        // Extract username from path
        // Pattern: /@username or /@username/article-title-xxx
        let pathComponents = baseURL.pathComponents.filter { $0 != "/" }
        guard let firstComponent = pathComponents.first, !firstComponent.isEmpty else { return [] }

        // Medium usernames start with @
        let username = firstComponent
        if !username.hasPrefix("@") {
            // Could be a publication, skip for now
            return []
        }

        // Skip if it looks like a system path
        let systemPaths = ["@me", "@following", "@list"]
        if systemPaths.contains(username.lowercased()) { return [] }

        let feedURLString = "https://medium.com/feed/\(username)"
        if let feedURL = URL(string: feedURLString) {
            return [feedURL]
        }
        return []
    }

    private func tryDevToFeedURL(baseURL: URL) -> [URL] {
        // Extract username from path
        // Pattern: /username or /username/article-slug-xxx
        let pathComponents = baseURL.pathComponents.filter { $0 != "/" }
        guard let username = pathComponents.first, !username.isEmpty else { return [] }

        // Skip if username looks like a system path
        let systemPaths = ["search", "tags", "t", "top", "latest", "videos", "podcasts", "listings", "reading-list", "settings", "admin"]
        if systemPaths.contains(username) { return [] }

        let feedURLString = "https://dev.to/feed/\(username)"
        if let feedURL = URL(string: feedURLString) {
            return [feedURL]
        }
        return []
    }

    private func resolveURL(_ urlString: String, baseURL: URL) -> URL? {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString)
        } else if urlString.hasPrefix("//") {
            return URL(string: "https:" + urlString)
        } else if urlString.hasPrefix("/") {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
            components?.path = urlString
            components?.query = nil
            return components?.url
        } else {
            return URL(string: urlString, relativeTo: baseURL)?.absoluteURL
        }
    }

    private func tryCommonFeedPaths(baseURL: URL) -> [URL] {
        let commonPaths = ["/feed", "/rss", "/feed.xml", "/rss.xml", "/atom.xml", "/index.xml"]
        var feedURLs: [URL] = []

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            return []
        }

        for path in commonPaths {
            components.path = path
            components.query = nil
            if let feedURL = components.url {
                feedURLs.append(feedURL)
            }
        }

        return feedURLs
    }

    // MARK: - Feed Metadata

    func fetchFeedMetadata(from feedURL: URL) async throws -> RSSFeedMetadata {
        let (data, response) = try await urlSession.data(from: feedURL)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RSSServiceError.fetchFailed
        }

        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw RSSServiceError.invalidContent
        }

        return try parseMetadata(from: xmlString, feedURL: feedURL)
    }

    private func parseMetadata(from xml: String, feedURL: URL) throws -> RSSFeedMetadata {
        let title = extractXMLElement(from: xml, tag: "title") ?? "Unknown Feed"
        let description = extractXMLElement(from: xml, tag: "description")
                       ?? extractXMLElement(from: xml, tag: "subtitle")
        let link = extractXMLElement(from: xml, tag: "link")
        let siteURL = link.flatMap { URL(string: $0) }

        return RSSFeedMetadata(
            title: title,
            description: description,
            feedURL: feedURL,
            siteURL: siteURL,
            lastUpdated: Date()
        )
    }

    // MARK: - Fetch Articles

    func fetchLatestArticles(from feedURL: URL, blogName: String) async throws -> [RSSArticle] {
        let (data, response) = try await urlSession.data(from: feedURL)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RSSServiceError.fetchFailed
        }

        guard let xmlString = String(data: data, encoding: .utf8) else {
            throw RSSServiceError.invalidContent
        }

        let domain = feedURL.host ?? "unknown"
        return parseArticles(from: xmlString, blogDomain: domain, blogName: blogName)
    }

    private func parseArticles(from xml: String, blogDomain: String, blogName: String) -> [RSSArticle] {
        var articles: [RSSArticle] = []

        // Try RSS 2.0 <item> format
        let rssItems = extractItems(from: xml, itemTag: "item")
        for item in rssItems {
            if let article = parseRSSItem(item, blogDomain: blogDomain, blogName: blogName) {
                articles.append(article)
            }
        }

        // Try Atom <entry> format if no RSS items found
        if articles.isEmpty {
            let atomEntries = extractItems(from: xml, itemTag: "entry")
            for entry in atomEntries {
                if let article = parseAtomEntry(entry, blogDomain: blogDomain, blogName: blogName) {
                    articles.append(article)
                }
            }
        }

        return articles.sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }

    private func extractItems(from xml: String, itemTag: String) -> [String] {
        var items: [String] = []
        let pattern = "<\(itemTag)[^>]*>([\\s\\S]*?)</\(itemTag)>"

        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let range = NSRange(xml.startIndex..., in: xml)
            let matches = regex.matches(in: xml, range: range)

            for match in matches {
                if let itemRange = Range(match.range(at: 0), in: xml) {
                    items.append(String(xml[itemRange]))
                }
            }
        }

        return items
    }

    private func parseRSSItem(_ item: String, blogDomain: String, blogName: String) -> RSSArticle? {
        guard let title = extractXMLElement(from: item, tag: "title"),
              let link = extractXMLElement(from: item, tag: "link"),
              let url = URL(string: link) else {
            return nil
        }

        let description = extractXMLElement(from: item, tag: "description")
        let pubDateString = extractXMLElement(from: item, tag: "pubDate")
        let publishedDate = pubDateString.flatMap { parseRSSDate($0) }

        return RSSArticle(
            title: decodeHTMLEntities(title),
            url: url,
            publishedDate: publishedDate,
            summary: description.map { decodeHTMLEntities($0) },
            blogDomain: blogDomain,
            blogName: blogName
        )
    }

    private func parseAtomEntry(_ entry: String, blogDomain: String, blogName: String) -> RSSArticle? {
        guard let title = extractXMLElement(from: entry, tag: "title") else {
            return nil
        }

        // Atom uses <link href="..."/> format
        let link = extractAtomLink(from: entry)
        guard let urlString = link, let url = URL(string: urlString) else {
            return nil
        }

        let summary = extractXMLElement(from: entry, tag: "summary")
                    ?? extractXMLElement(from: entry, tag: "content")
        let pubDateString = extractXMLElement(from: entry, tag: "published")
                          ?? extractXMLElement(from: entry, tag: "updated")
        let publishedDate = pubDateString.flatMap { parseAtomDate($0) }

        return RSSArticle(
            title: decodeHTMLEntities(title),
            url: url,
            publishedDate: publishedDate,
            summary: summary.map { decodeHTMLEntities($0) },
            blogDomain: blogDomain,
            blogName: blogName
        )
    }

    private func extractAtomLink(from entry: String) -> String? {
        let pattern = "<link[^>]+href=[\"']([^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: entry, range: NSRange(entry.startIndex..., in: entry)),
           let range = Range(match.range(at: 1), in: entry) {
            return String(entry[range])
        }
        return nil
    }

    // MARK: - Refresh All Feeds

    func refreshAllFeeds(blogs: [(domain: String, name: String, rssURL: URL)]) async throws -> [RSSArticle] {
        var allArticles: [RSSArticle] = []

        for blog in blogs {
            do {
                let articles = try await fetchLatestArticles(from: blog.rssURL, blogName: blog.name)
                allArticles.append(contentsOf: articles)
            } catch {
                // Skip failed feeds, continue with others
                continue
            }
        }

        return allArticles.sorted { ($0.publishedDate ?? .distantPast) > ($1.publishedDate ?? .distantPast) }
    }

    // MARK: - Helper Methods

    private func extractXMLElement(from xml: String, tag: String) -> String? {
        // Handle CDATA sections
        let cdataPattern = "<\(tag)[^>]*><!\\[CDATA\\[([\\s\\S]*?)\\]\\]></\(tag)>"
        if let regex = try? NSRegularExpression(pattern: cdataPattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
           let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Handle regular content
        let pattern = "<\(tag)[^>]*>([^<]+)</\(tag)>"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: xml, range: NSRange(xml.startIndex..., in: xml)),
           let range = Range(match.range(at: 1), in: xml) {
            return String(xml[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    private func parseRSSDate(_ dateString: String) -> Date? {
        let formatters = [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm:ss zzz",
            "yyyy-MM-dd'T'HH:mm:ssZ"
        ]

        for format in formatters {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }

        return nil
    }

    private func parseAtomDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: dateString) {
            return date
        }

        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func decodeHTMLEntities(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
    }
}

// MARK: - RSSServiceError

enum RSSServiceError: Error, LocalizedError {
    case fetchFailed
    case invalidContent
    case noFeedFound
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "フィードの取得に失敗しました"
        case .invalidContent:
            return "フィードの内容を解析できません"
        case .noFeedFound:
            return "RSSフィードが見つかりませんでした"
        case .parsingFailed:
            return "フィードの解析に失敗しました"
        }
    }
}
