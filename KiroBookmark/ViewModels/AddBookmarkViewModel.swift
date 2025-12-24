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

    // MARK: - Dependencies

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let favoriteBlogRepository: FavoriteBlogRepositoryProtocol
    private let urlValidationService: URLValidationServiceProtocol

    // MARK: - Initialization

    init(
        bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository(),
        favoriteBlogRepository: FavoriteBlogRepositoryProtocol = FavoriteBlogRepository(),
        urlValidationService: URLValidationServiceProtocol = URLValidationService()
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.favoriteBlogRepository = favoriteBlogRepository
        self.urlValidationService = urlValidationService
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
              let domain = result.domain else {
            return
        }

        if favoriteBlogRepository.exists(domain: domain) {
            return
        }

        do {
            _ = try favoriteBlogRepository.create(domain: domain, name: domain, rssURL: nil)
            isFavoriteBlog = true
        } catch {
            errorMessage = "お気に入りブログの追加に失敗しました"
        }
    }

    func reset() {
        urlString = ""
        validationResult = nil
        errorMessage = nil
        successMessage = nil
        isFavoriteBlog = false
    }
}
