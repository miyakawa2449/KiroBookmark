//
//  AddBookmarkViewModel.swift
//  KiroBookmark
//
//  ViewModel for adding new bookmarks
//

import Foundation
import Combine

@MainActor
final class AddBookmarkViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var urlString = ""
    @Published var validationResult: URLValidationResult?
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var isFavoriteBlog = false
    @Published var rssDetectionStatus: RSSDetectionStatus = .notStarted

    // MARK: - RSS Detection Status

    enum RSSDetectionStatus: Equatable {
        case notStarted
        case detecting
        case detected(URL)
        case notFound
        case failed(String)
    }

    // MARK: - Dependencies

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let favoriteBlogRepository: FavoriteBlogRepositoryProtocol
    private let urlValidationService: URLValidationServiceProtocol
    private let rssService: RSSServiceProtocol

    // MARK: - Initialization

    init(
        bookmarkRepository: BookmarkRepositoryProtocol,
        favoriteBlogRepository: FavoriteBlogRepositoryProtocol,
        urlValidationService: URLValidationServiceProtocol,
        rssService: RSSServiceProtocol
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.favoriteBlogRepository = favoriteBlogRepository
        self.urlValidationService = urlValidationService
        self.rssService = rssService
    }
    
    @MainActor
    convenience init() {
        self.init(
            bookmarkRepository: BookmarkRepository(),
            favoriteBlogRepository: FavoriteBlogRepository(),
            urlValidationService: URLValidationService(),
            rssService: RSSService()
        )
    }

    // MARK: - Computed Properties

    var isValid: Bool {
        validationResult?.isValid ?? false
    }

    var canSave: Bool {
        isValid && !isSaving
    }

    // MARK: - Public Methods

    func validateURL() {
        errorMessage = nil
        validationResult = urlValidationService.validate(urlString)

        if let result = validationResult, result.isValid, let domain = result.domain {
            isFavoriteBlog = favoriteBlogRepository.exists(domain: domain)
        }
    }

    func saveBookmark() async -> Bool {
        guard let result = validationResult,
              result.isValid,
              let normalizedURL = result.normalizedURL,
              let domain = result.domain else {
            errorMessage = "URLを確認してください"
            return false
        }

        if bookmarkRepository.exists(url: normalizedURL) {
            errorMessage = "このURLは既にブックマークされています"
            return false
        }

        isSaving = true
        errorMessage = nil

        do {
            var title = domain
            if let url = URL(string: normalizedURL) {
                let metadata = try await urlValidationService.fetchMetadata(from: url)
                title = metadata.title
            }

            let bookmark = try bookmarkRepository.create(
                url: normalizedURL,
                title: title,
                domain: domain
            )

            if let favoriteBlog = try favoriteBlogRepository.fetchByDomain(domain) {
                try favoriteBlogRepository.associateArticle(bookmark, with: favoriteBlog)
            }

            successMessage = "ブックマークを追加しました"
            isSaving = false
            return true

        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    func addToFavoriteBlogs() async {
        guard let result = validationResult,
              result.isValid,
              let domain = result.domain,
              let normalizedURL = result.normalizedURL else {
            return
        }

        if favoriteBlogRepository.exists(domain: domain) {
            // Existing blog: try to detect RSS if not set
            await detectRSSForExistingBlog(domain: domain, articleURL: normalizedURL)
            return
        }

        do {
            let blog = try favoriteBlogRepository.create(domain: domain, name: domain, rssURL: nil)
            isFavoriteBlog = true

            // Auto-detect RSS feed for new blog
            await detectAndSetRSSFeed(for: blog, articleURL: normalizedURL)
        } catch {
            errorMessage = "お気に入りブログの追加に失敗しました"
        }
    }

    // MARK: - RSS Detection

    func detectRSSFeed() async {
        guard let result = validationResult,
              result.isValid,
              let normalizedURL = result.normalizedURL,
              let url = URL(string: normalizedURL) else {
            return
        }

        rssDetectionStatus = .detecting

        do {
            let feedURLs = try await rssService.detectFeed(from: url)
            if let firstFeed = feedURLs.first {
                rssDetectionStatus = .detected(firstFeed)
            } else {
                rssDetectionStatus = .notFound
            }
        } catch {
            rssDetectionStatus = .failed(error.localizedDescription)
        }
    }

    private func detectRSSForExistingBlog(domain: String, articleURL: String) async {
        guard let blog = try? favoriteBlogRepository.fetchByDomain(domain),
              blog.rssURL == nil || blog.rssURL?.isEmpty == true,
              URL(string: articleURL) != nil else {
            return
        }

        await detectAndSetRSSFeed(for: blog, articleURL: articleURL)
    }

    private func detectAndSetRSSFeed(for blog: FavoriteBlog, articleURL: String) async {
        guard let url = URL(string: articleURL) else { return }

        rssDetectionStatus = .detecting

        do {
            let feedURLs = try await rssService.detectFeed(from: url)
            if let firstFeed = feedURLs.first {
                try favoriteBlogRepository.updateRSSURL(blog, rssURL: firstFeed.absoluteString)
                rssDetectionStatus = .detected(firstFeed)
            } else {
                rssDetectionStatus = .notFound
            }
        } catch {
            rssDetectionStatus = .failed(error.localizedDescription)
        }
    }

    func reset() {
        urlString = ""
        validationResult = nil
        errorMessage = nil
        successMessage = nil
        isFavoriteBlog = false
        rssDetectionStatus = .notStarted
    }
}
