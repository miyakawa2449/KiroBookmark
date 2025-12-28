//
//  NewEntryViewModel.swift
//  KiroBookmark
//
//  ViewModel for New Entry tab displaying RSS articles
//

import Foundation
import Combine

@MainActor
final class NewEntryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var articles: [RSSArticle] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshDate: Date?

    // MARK: - Dependencies

    private let rssService: RSSServiceProtocol
    private let favoriteBlogRepository: FavoriteBlogRepositoryProtocol
    private let bookmarkRepository: BookmarkRepositoryProtocol

    // MARK: - Initialization

    init(
        rssService: RSSServiceProtocol = RSSService(),
        favoriteBlogRepository: FavoriteBlogRepositoryProtocol = FavoriteBlogRepository(),
        bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository()
    ) {
        self.rssService = rssService
        self.favoriteBlogRepository = favoriteBlogRepository
        self.bookmarkRepository = bookmarkRepository
    }

    // MARK: - Computed Properties

    var hasArticles: Bool {
        !articles.isEmpty
    }

    var hasRegisteredFeeds: Bool {
        (try? favoriteBlogRepository.fetchWithRSSURL().count > 0) ?? false
    }

    // MARK: - Public Methods

    func refreshFeeds() async {
        isLoading = true
        errorMessage = nil

        do {
            let blogs = try favoriteBlogRepository.fetchWithRSSURL()
            let feedData = blogs.compactMap { blog -> (domain: String, name: String, rssURL: URL)? in
                guard let rssURLString = blog.rssURL,
                      let rssURL = URL(string: rssURLString) else {
                    return nil
                }
                return (domain: blog.domain ?? "", name: blog.name ?? blog.domain ?? "", rssURL: rssURL)
            }

            var fetchedArticles = try await rssService.refreshAllFeeds(blogs: feedData)

            // Mark already bookmarked articles
            fetchedArticles = fetchedArticles.map { article in
                var mutableArticle = article
                mutableArticle.isBookmarked = bookmarkRepository.exists(url: article.url.absoluteString)
                return mutableArticle
            }

            articles = fetchedArticles
            lastRefreshDate = Date()
            isLoading = false

        } catch {
            errorMessage = "フィードの更新に失敗しました"
            isLoading = false
        }
    }

    func bookmarkArticle(_ article: RSSArticle) async -> Bool {
        if bookmarkRepository.exists(url: article.url.absoluteString) {
            return false
        }

        do {
            let bookmark = try bookmarkRepository.create(
                url: article.url.absoluteString,
                title: article.title,
                domain: article.blogDomain
            )

            // Associate with FavoriteBlog if exists
            if let blog = try favoriteBlogRepository.fetchByDomain(article.blogDomain) {
                try favoriteBlogRepository.associateArticle(bookmark, with: blog)
            }

            // Update article status in list
            if let index = articles.firstIndex(where: { $0.id == article.id }) {
                articles[index].isBookmarked = true
            }

            return true
        } catch {
            errorMessage = "ブックマークの追加に失敗しました"
            return false
        }
    }

    func formattedLastRefresh() -> String? {
        guard let date = lastRefreshDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.unitsStyle = .short
        return "最終更新: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
}
