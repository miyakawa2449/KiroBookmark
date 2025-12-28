//
//  RSSArticle.swift
//  KiroBookmark
//
//  RSS article DTO (non-persistent, in-memory only)
//

import Foundation

// MARK: - RSSArticle

struct RSSArticle: Identifiable, Hashable {
    let id: UUID
    let title: String
    let url: URL
    let publishedDate: Date?
    let summary: String?
    let blogDomain: String
    let blogName: String
    var isBookmarked: Bool

    init(
        id: UUID = UUID(),
        title: String,
        url: URL,
        publishedDate: Date? = nil,
        summary: String? = nil,
        blogDomain: String,
        blogName: String,
        isBookmarked: Bool = false
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.publishedDate = publishedDate
        self.summary = summary
        self.blogDomain = blogDomain
        self.blogName = blogName
        self.isBookmarked = isBookmarked
    }
}

// MARK: - RSSFeedMetadata

struct RSSFeedMetadata {
    let title: String
    let description: String?
    let feedURL: URL
    let siteURL: URL?
    let lastUpdated: Date?
}

// MARK: - Date Formatting

extension RSSArticle {
    var formattedDate: String? {
        guard let date = publishedDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
