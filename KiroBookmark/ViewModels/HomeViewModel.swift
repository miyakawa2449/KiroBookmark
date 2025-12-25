//
//  HomeViewModel.swift
//  KiroBookmark
//
//  ViewModel for managing home screen state (2-tab + side menu system)
//

import Foundation
import Combine
import CoreData

@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published Properties

    // Tab State
    @Published var currentTab: MainTabType = .bookmark
    @Published var isSideMenuOpen = false

    // Data
    @Published var bookmarks: [ArticleBookmark] = []
    @Published var filteredBookmarks: [ArticleBookmark] = []
    @Published var selectedMenuItem: SideMenuItem?

    // Menu State
    @Published var visibleMenuItems: [SideMenuItem] = []
    @Published var menuItemCounts: [SideMenuItem: Int] = [:]

    // Loading State
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let memoRepository: MemoRepositoryProtocol

    // MARK: - Constants

    private static let menuAnimationDuration: Double = 0.3

    // MARK: - Initialization

    init(
        bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository(),
        memoRepository: MemoRepositoryProtocol = MemoRepository()
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.memoRepository = memoRepository
    }

    // MARK: - Data Loading

    func loadData() {
        isLoading = true
        errorMessage = nil

        do {
            bookmarks = try bookmarkRepository.fetchAllSortedByActivity()
            updateMenuItemCounts()
            updateVisibleMenuItems()
            applyCurrentFilter()
        } catch {
            errorMessage = "データの読み込みに失敗しました"
        }

        isLoading = false
    }

    func refresh() {
        loadData()
    }

    // MARK: - Tab Management

    func selectTab(_ tab: MainTabType) {
        currentTab = tab
        selectedMenuItem = nil
        closeSideMenu()
        applyCurrentFilter()
    }

    // MARK: - Side Menu Management

    func openSideMenu() {
        withAnimation(.easeInOut(duration: Self.menuAnimationDuration)) {
            isSideMenuOpen = true
        }
    }

    func closeSideMenu() {
        withAnimation(.easeInOut(duration: Self.menuAnimationDuration)) {
            isSideMenuOpen = false
        }
    }

    func toggleSideMenu() {
        if isSideMenuOpen {
            closeSideMenu()
        } else {
            openSideMenu()
        }
    }

    func selectMenuItem(_ item: SideMenuItem) {
        selectedMenuItem = item
        closeSideMenu()
        applyMenuFilter(item)
    }

    func clearMenuSelection() {
        selectedMenuItem = nil
        applyCurrentFilter()
    }

    // MARK: - Menu Item Visibility

    private func updateMenuItemCounts() {
        var counts: [SideMenuItem: Int] = [:]

        for item in SideMenuItem.allCases {
            if item == .favorite {
                // Count favorite bookmarks
                counts[item] = bookmarks.filter { $0.isFavorite }.count
            } else if let memoType = item.associatedMemoType {
                // Count bookmarks with memos of this type
                counts[item] = countBookmarksWithMemoType(memoType)
            }
        }

        menuItemCounts = counts
    }

    private func countBookmarksWithMemoType(_ memoType: MemoType) -> Int {
        return bookmarks.filter { bookmark in
            guard let memos = bookmark.memos as? Set<TweetMemo> else { return false }
            return memos.contains { $0.memoType == memoType.rawValue }
        }.count
    }

    private func updateVisibleMenuItems() {
        // Show all menu items, but mark empty ones
        // In MVP, show all items regardless of count
        visibleMenuItems = SideMenuItem.allCases
    }

    func getMenuItemCount(_ item: SideMenuItem) -> Int {
        return menuItemCounts[item] ?? 0
    }

    func isMenuItemEmpty(_ item: SideMenuItem) -> Bool {
        return getMenuItemCount(item) == 0
    }

    // MARK: - Filtering

    private func applyCurrentFilter() {
        switch currentTab {
        case .newEntry:
            // Show bookmarks from favorite blogs (sorted by publish date)
            filteredBookmarks = bookmarks.filter { bookmark in
                // For MVP, show all bookmarks in New Entry
                // Later: filter by favorite blog domains
                true
            }.sorted { ($0.bookmarkedDate ?? Date.distantPast) > ($1.bookmarkedDate ?? Date.distantPast) }

        case .bookmark:
            // Show all bookmarks sorted by latest activity
            filteredBookmarks = bookmarks.sorted { b1, b2 in
                let date1 = getLatestActivityDate(for: b1)
                let date2 = getLatestActivityDate(for: b2)
                return date1 > date2
            }
        }
    }

    private func applyMenuFilter(_ item: SideMenuItem) {
        if item == .favorite {
            // Filter by favorite bookmarks
            filteredBookmarks = bookmarks.filter { $0.isFavorite }
        } else if let memoType = item.associatedMemoType {
            // Filter by memo type
            filteredBookmarks = bookmarks.filter { bookmark in
                guard let memos = bookmark.memos as? Set<TweetMemo> else { return false }
                return memos.contains { $0.memoType == memoType.rawValue }
            }
        }

        // Sort by latest activity
        filteredBookmarks.sort { b1, b2 in
            let date1 = getLatestActivityDate(for: b1)
            let date2 = getLatestActivityDate(for: b2)
            return date1 > date2
        }
    }

    private func getLatestActivityDate(for bookmark: ArticleBookmark) -> Date {
        var latestDate = bookmark.bookmarkedDate ?? Date.distantPast

        // Check memo dates
        if let memos = bookmark.memos as? Set<TweetMemo> {
            for memo in memos {
                if let memoDate = memo.updatedDate ?? memo.createdDate {
                    if memoDate > latestDate {
                        latestDate = memoDate
                    }
                }
            }
        }

        return latestDate
    }

    // MARK: - Bookmark Operations

    func toggleFavorite(_ bookmark: ArticleBookmark) {
        do {
            try bookmarkRepository.toggleFavorite(bookmark)
            loadData()
        } catch {
            errorMessage = "お気に入りの更新に失敗しました"
        }
    }

    func deleteBookmark(_ bookmark: ArticleBookmark) {
        do {
            try bookmarkRepository.delete(bookmark)
            loadData()
        } catch {
            errorMessage = "ブックマークの削除に失敗しました"
        }
    }

    // MARK: - Navigation Title

    var navigationTitle: String {
        if let menuItem = selectedMenuItem {
            return menuItem.displayName
        }
        return currentTab.displayName
    }

    // MARK: - Swipe Gesture Handling

    func handleSwipeGesture(translation: CGFloat, velocity: CGFloat) {
        let threshold: CGFloat = 50

        if translation > threshold && !isSideMenuOpen {
            openSideMenu()
        } else if translation < -threshold && isSideMenuOpen {
            closeSideMenu()
        }
    }
}

// MARK: - Helper for Animation

import SwiftUI

private func withAnimation<Result>(_ animation: Animation?, _ body: () throws -> Result) rethrows -> Result {
    try SwiftUI.withAnimation(animation, body)
}
