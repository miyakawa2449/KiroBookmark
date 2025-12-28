//
//  RSSFeedViewModel.swift
//  KiroBookmark
//
//  ViewModel for managing RSS feeds
//

import Foundation
import Combine

@MainActor
final class RSSFeedViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var blogs: [FavoriteBlog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var manualRSSURL = ""
    @Published var isValidatingRSS = false
    @Published var rssValidationResult: RSSValidationResult?

    // MARK: - RSS Validation Result

    enum RSSValidationResult: Equatable {
        case valid(title: String)
        case invalid(String)
    }

    // MARK: - Dependencies

    private let favoriteBlogRepository: FavoriteBlogRepositoryProtocol
    private let rssService: RSSServiceProtocol

    // MARK: - Initialization

    init(
        favoriteBlogRepository: FavoriteBlogRepositoryProtocol = FavoriteBlogRepository(),
        rssService: RSSServiceProtocol = RSSService()
    ) {
        self.favoriteBlogRepository = favoriteBlogRepository
        self.rssService = rssService
    }

    // MARK: - Data Loading

    func loadBlogs() {
        isLoading = true
        errorMessage = nil

        do {
            blogs = try favoriteBlogRepository.fetchAll()
        } catch {
            errorMessage = "ブログの読み込みに失敗しました"
        }

        isLoading = false
    }

    // MARK: - Feed Management

    func updateRSSURL(for blog: FavoriteBlog, rssURL: String?) async {
        do {
            try favoriteBlogRepository.updateRSSURL(blog, rssURL: rssURL)
            loadBlogs()
        } catch {
            errorMessage = "RSS URLの更新に失敗しました"
        }
    }

    func clearRSSURL(for blog: FavoriteBlog) async {
        do {
            try favoriteBlogRepository.clearRSSURL(blog)
            loadBlogs()
        } catch {
            errorMessage = "RSS URLのクリアに失敗しました"
        }
    }

    func deleteBlog(_ blog: FavoriteBlog) async {
        do {
            try favoriteBlogRepository.delete(blog)
            loadBlogs()
        } catch {
            errorMessage = "ブログの削除に失敗しました"
        }
    }

    // MARK: - Manual RSS Validation

    func validateManualRSSURL() async {
        let trimmed = manualRSSURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            rssValidationResult = .invalid("URLを入力してください")
            return
        }

        guard let url = URL(string: trimmed) else {
            rssValidationResult = .invalid("無効なURL形式です")
            return
        }

        isValidatingRSS = true
        rssValidationResult = nil

        do {
            let metadata = try await rssService.fetchFeedMetadata(from: url)
            rssValidationResult = .valid(title: metadata.title)
        } catch {
            rssValidationResult = .invalid("RSSフィードの取得に失敗しました")
        }

        isValidatingRSS = false
    }

    func saveManualRSSURL(for blog: FavoriteBlog) async -> Bool {
        let trimmed = manualRSSURL.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else { return false }

        await updateRSSURL(for: blog, rssURL: trimmed)
        manualRSSURL = ""
        rssValidationResult = nil
        return true
    }

    func resetManualInput() {
        manualRSSURL = ""
        rssValidationResult = nil
        isValidatingRSS = false
    }

    // MARK: - Computed Properties

    var blogsWithRSS: [FavoriteBlog] {
        blogs.filter { $0.rssURL != nil && !($0.rssURL?.isEmpty ?? true) }
    }

    var blogsWithoutRSS: [FavoriteBlog] {
        blogs.filter { $0.rssURL == nil || $0.rssURL?.isEmpty == true }
    }
}
