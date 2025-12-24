//
//  BookmarkListViewModel.swift
//  KiroBookmark
//
//  ViewModel for bookmark list management
//

import Foundation
import Combine

@MainActor
final class BookmarkListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var bookmarks: [ArticleBookmark] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let favoriteBlogRepository: FavoriteBlogRepositoryProtocol

    // MARK: - Initialization

    init(
        bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository(),
        favoriteBlogRepository: FavoriteBlogRepositoryProtocol = FavoriteBlogRepository()
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.favoriteBlogRepository = favoriteBlogRepository
    }

    // MARK: - Public Methods

    func loadBookmarks() {
        isLoading = true
        errorMessage = nil

        do {
            bookmarks = try bookmarkRepository.fetchAll()
        } catch {
            errorMessage = "ブックマークの読み込みに失敗しました"
        }

        isLoading = false
    }

    func loadFavorites() {
        isLoading = true
        errorMessage = nil

        do {
            bookmarks = try bookmarkRepository.fetchFavorites()
        } catch {
            errorMessage = "お気に入りの読み込みに失敗しました"
        }

        isLoading = false
    }

    func toggleFavorite(_ bookmark: ArticleBookmark) {
        do {
            try bookmarkRepository.toggleFavorite(bookmark)
            loadBookmarks()
        } catch {
            errorMessage = "お気に入りの更新に失敗しました"
        }
    }

    func deleteBookmark(_ bookmark: ArticleBookmark) {
        do {
            try bookmarkRepository.delete(bookmark)
            loadBookmarks()
        } catch {
            errorMessage = "ブックマークの削除に失敗しました"
        }
    }

    func deleteBookmarks(at offsets: IndexSet) {
        for index in offsets {
            let bookmark = bookmarks[index]
            do {
                try bookmarkRepository.delete(bookmark)
            } catch {
                errorMessage = "ブックマークの削除に失敗しました"
            }
        }
        loadBookmarks()
    }

    func updateReadingStatus(_ bookmark: ArticleBookmark, status: ReadingStatus) {
        do {
            try bookmarkRepository.updateReadingStatus(bookmark, status: status)
            loadBookmarks()
        } catch {
            errorMessage = "読書状態の更新に失敗しました"
        }
    }

    // MARK: - Sorting

    func sortByBookmarkDate() {
        bookmarks.sort { ($0.bookmarkedDate ?? Date.distantPast) > ($1.bookmarkedDate ?? Date.distantPast) }
    }

    func sortByPublishDate() {
        bookmarks.sort {
            let date0 = $0.publishedDate ?? $0.bookmarkedDate ?? Date.distantPast
            let date1 = $1.publishedDate ?? $1.bookmarkedDate ?? Date.distantPast
            return date0 > date1
        }
    }

    func sortByTitle() {
        bookmarks.sort { ($0.title ?? "") < ($1.title ?? "") }
    }
}
