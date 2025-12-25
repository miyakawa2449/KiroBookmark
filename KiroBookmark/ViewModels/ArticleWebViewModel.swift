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
        bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository(),
        memoRepository: MemoRepositoryProtocol = MemoRepository()
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.memoRepository = memoRepository
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
            Task { @MainActor in
                self?.onScrollStopped()
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
                Task { @MainActor in
                    self?.showBookmarkButton = false
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
