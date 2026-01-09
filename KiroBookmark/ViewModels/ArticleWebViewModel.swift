//
//  ArticleWebViewModel.swift
//  KiroBookmark
//
//  ViewModel for managing WebView state and text selection
//

import Foundation
import Combine
import WebKit
import CoreData

@MainActor
final class ArticleWebViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    @Published var errorMessage: String?
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var currentURL: URL?
    @Published var pageTitle: String?

    // Text Selection
    @Published var selectedText: String?
    @Published var showingQuoteMemoSheet = false

    // Scroll Detection
    @Published var isScrolling = false
    @Published var showBookmarkButton = false
    @Published var isBookmarked = false

    // Toolbar State (Task 2/3: Article Preview UI Improvement)
    @Published var isFavorite = false
    @Published var showingMemoSheet = false
    @Published var showingDetailView = false
    @Published var preselectedMemoType: MemoType? = nil  // Task 3: メモタイプ事前選択
    @Published var isUserBookmarked = true  // New Entry/Bookmark separation

    // Toast notification
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastView.ToastType = .success

    // MARK: - Properties

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let memoRepository: MemoRepositoryProtocol
    private var bookmark: ArticleBookmark?
    private var scrollTimer: Timer?

    // MARK: - Constants

    private static let scrollStopDelay: TimeInterval = 1.5
    private static let bookmarkButtonShowDuration: TimeInterval = 3.0

    // MARK: - Initialization

    init(
        bookmarkRepository: BookmarkRepositoryProtocol,
        memoRepository: MemoRepositoryProtocol
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.memoRepository = memoRepository
    }
    
    @MainActor
    convenience init() {
        self.init(
            bookmarkRepository: BookmarkRepository(),
            memoRepository: MemoRepository()
        )
    }

    // MARK: - Configuration

    func configure(url: URL, bookmark: ArticleBookmark? = nil) {
        self.currentURL = url
        self.bookmark = bookmark
        checkIfBookmarked()
    }

    func configure(bookmark: ArticleBookmark) {
        self.bookmark = bookmark
        if let urlString = bookmark.url, let url = URL(string: urlString) {
            self.currentURL = url
        }
        self.isBookmarked = true
        self.isFavorite = bookmark.isFavorite
        self.isUserBookmarked = bookmark.isUserBookmarked

        // Mark as read when article is opened
        markAsRead()
    }

    // MARK: - Reading Status

    /// Mark the current bookmark as read
    private func markAsRead() {
        guard let bookmark = bookmark else { return }

        // Only update if currently unread
        if bookmark.readingStatus == ReadingStatus.unread.rawValue {
            do {
                try bookmarkRepository.updateReadingStatus(bookmark, status: .read)
            } catch {
                print("Failed to mark as read: \(error)")
            }
        }
    }

    // MARK: - WebView State Updates

    func updateLoadingState(_ loading: Bool) {
        isLoading = loading
        if !loading {
            errorMessage = nil
        }
    }

    func updateProgress(_ progress: Double) {
        loadingProgress = progress
    }

    func updateNavigationState(canGoBack: Bool, canGoForward: Bool) {
        self.canGoBack = canGoBack
        self.canGoForward = canGoForward
    }

    func updateCurrentURL(_ url: URL?) {
        currentURL = url
        checkIfBookmarked()
    }

    func updatePageTitle(_ title: String?) {
        pageTitle = title
    }

    func setError(_ message: String) {
        errorMessage = message
        isLoading = false
    }

    // MARK: - Text Selection

    func handleTextSelection(_ text: String?) {
        let trimmedText = text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let text = trimmedText, !text.isEmpty {
            selectedText = text
        } else {
            selectedText = nil
        }
    }

    func clearSelection() {
        selectedText = nil
    }

    func showQuoteMemoSheet() {
        guard selectedText != nil else { return }
        showingQuoteMemoSheet = true
    }

    func createQuoteMemo(content: String, memoType: MemoType) throws -> TweetMemo? {
        guard let bookmark = bookmark,
              let selectedText = selectedText,
              let sourceURL = currentURL?.absoluteString else {
            return nil
        }

        let memo = try memoRepository.createQuoteMemo(
            content: content,
            selectedText: selectedText,
            sourceURL: sourceURL,
            bookmark: bookmark
        )

        self.selectedText = nil
        showingQuoteMemoSheet = false

        return memo
    }

    // MARK: - Scroll Detection

    func handleScrollStart() {
        isScrolling = true
        showBookmarkButton = false
        scrollTimer?.invalidate()
    }

    func handleScrollEnd() {
        scrollTimer?.invalidate()
        scrollTimer = Timer.scheduledTimer(withTimeInterval: Self.scrollStopDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.onScrollStopped()
            }
        }
    }

    private func onScrollStopped() {
        isScrolling = false

        // Show bookmark button if not already bookmarked
        if !isBookmarked {
            showBookmarkButton = true

            // Auto-hide after duration
            Timer.scheduledTimer(withTimeInterval: Self.bookmarkButtonShowDuration, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    self.showBookmarkButton = false
                }
            }
        }
    }

    // MARK: - Bookmark Operations

    func checkIfBookmarked() {
        guard let url = currentURL else {
            isBookmarked = false
            return
        }
        isBookmarked = bookmarkRepository.exists(url: url.absoluteString)
    }

    func registerBookmark() throws -> ArticleBookmark? {
        guard let url = currentURL, !isBookmarked else { return nil }

        let title = pageTitle ?? url.absoluteString
        let domain = url.host ?? ""

        let newBookmark = try bookmarkRepository.create(
            url: url.absoluteString,
            title: title,
            domain: domain
        )

        self.bookmark = newBookmark
        self.isBookmarked = true
        self.showBookmarkButton = false

        return newBookmark
    }

    /// Add New Entry article to user bookmarks (New Entry/Bookmark separation)
    func addToBookmark() {
        guard let bookmark = bookmark, !isUserBookmarked else { return }

        do {
            try bookmarkRepository.addToBookmark(bookmark)

            // Update state
            isUserBookmarked = true

            // Show success toast
            toastMessage = "ブックマークに登録しました"
            toastType = .success
            showToast = true

        } catch {
            // Show error toast
            toastMessage = "ブックマークの追加に失敗しました"
            toastType = .error
            showToast = true
        }
    }

    // MARK: - Utility

    func getBookmark() -> ArticleBookmark? {
        return bookmark
    }

    func setBookmark(_ bookmark: ArticleBookmark?) {
        self.bookmark = bookmark
        if bookmark != nil {
            isBookmarked = true
        }
    }

    // MARK: - Toolbar Actions (Task 2: Article Preview UI Improvement)

    /// Toggle favorite status for the current bookmark
    func toggleFavorite() {
        guard let bookmark = bookmark else { return }

        do {
            try bookmarkRepository.toggleFavorite(bookmark)
            isFavorite = bookmark.isFavorite
        } catch {
            print("Failed to toggle favorite: \(error)")
        }
    }

    /// Task 3: Open memo sheet with TODO type preselected
    func addQuickTodo() {
        preselectedMemoType = .todo
        showingMemoSheet = true
    }

    /// Task 3: Open memo sheet for regular memo
    func openMemoSheet() {
        preselectedMemoType = nil
        showingMemoSheet = true
    }

    /// Enable text selection mode for quote creation
    func enableTextSelection() {
        // Text selection is already enabled in WebView
        // This can be enhanced to show visual feedback
    }
}

// MARK: - SelectedTextInfo

struct SelectedTextInfo {
    let content: String
    let sourceURL: URL
    let timestamp: Date

    init(content: String, sourceURL: URL) {
        self.content = content
        self.sourceURL = sourceURL
        self.timestamp = Date()
    }
}
