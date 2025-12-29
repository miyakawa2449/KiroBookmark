//
//  NewEntryViewModel.swift
//  KiroBookmark
//
//  ViewModel for New Entry tab displaying RSS articles as ArticleBookmark
//

import Foundation
import Combine

@MainActor
final class NewEntryViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var articles: [ArticleBookmark] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastRefreshDate: Date?

    // Toast notification
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastView.ToastType = .success

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

    /// Load New Entry articles from Core Data
    func loadArticles() {
        do {
            articles = try bookmarkRepository.fetchNewEntryArticles()
        } catch {
            errorMessage = "記事の読み込みに失敗しました"
        }
    }

    /// Refresh RSS feeds and save new articles to Core Data
    func refreshFeeds() async {
        isLoading = true
        errorMessage = nil

        do {
            // Cleanup old New Entry articles (20+ days)
            let deletedCount = try bookmarkRepository.cleanupOldNewEntries()
            if deletedCount > 0 {
                print("Cleaned up \(deletedCount) old New Entry articles")
            }

            let blogs = try favoriteBlogRepository.fetchWithRSSURL()
            let feedData = blogs.compactMap { blog -> (domain: String, name: String, rssURL: URL)? in
                guard let rssURLString = blog.rssURL,
                      let rssURL = URL(string: rssURLString) else {
                    return nil
                }
                return (domain: blog.domain ?? "", name: blog.name ?? blog.domain ?? "", rssURL: rssURL)
            }

            let fetchedArticles = try await rssService.refreshAllFeeds(blogs: feedData)

            // Save new articles to Core Data as New Entry (isUserBookmarked = false)
            for rssArticle in fetchedArticles {
                // Skip if already exists
                if bookmarkRepository.exists(url: rssArticle.url.absoluteString) {
                    continue
                }

                _ = try bookmarkRepository.createFromRSS(
                    url: rssArticle.url.absoluteString,
                    title: rssArticle.title,
                    domain: rssArticle.blogDomain,
                    summary: rssArticle.summary,
                    publishedDate: rssArticle.publishedDate
                )
            }

            // Reload articles from Core Data
            loadArticles()
            lastRefreshDate = Date()
            isLoading = false

        } catch {
            errorMessage = "フィードの更新に失敗しました"
            isLoading = false
        }
    }

    /// Add article to user bookmarks
    func addToBookmark(_ article: ArticleBookmark) {
        do {
            try bookmarkRepository.addToBookmark(article)
            // Remove from current list
            articles.removeAll { $0.id == article.id }

            // Show success toast
            toastMessage = "ブックマークに登録しました"
            toastType = .success
            showToast = true

        } catch {
            errorMessage = "ブックマークの追加に失敗しました"

            // Show error toast
            toastMessage = "ブックマークの追加に失敗しました"
            toastType = .error
            showToast = true
        }
    }

    /// Mark article as viewed
    func markAsViewed(_ article: ArticleBookmark) {
        do {
            try bookmarkRepository.markAsViewed(article)
            // Reload to update UI
            loadArticles()
        } catch {
            print("Failed to mark as viewed: \(error)")
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
