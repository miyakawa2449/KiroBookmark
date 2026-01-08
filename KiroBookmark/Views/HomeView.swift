//
//  HomeView.swift
//  KiroBookmark
//
//  Main home view with 2-tab + side menu system
//

import SwiftUI
import CoreData

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var newEntryViewModel = NewEntryViewModel()
    @State private var showingSettings = false
    @State private var showingAddBookmark = false
    @State private var showingSearch = false
    @State private var selectedBookmarkForDetail: ArticleBookmark?  // For ArticleDetailView (Task 2 toolbar)
    @State private var navigationPath = NavigationPath()  // For WebView navigation
    @State private var dragOffset: CGFloat = 0

    // Task 4: Quick Actions from long press menu
    @State private var selectedBookmarkForMemo: ArticleBookmark?
    @State private var selectedBookmarkForTags: ArticleBookmark?
    @State private var bookmarkToDelete: ArticleBookmark?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Main Content
                mainContent
                    .offset(x: viewModel.isSideMenuOpen ? 280 : 0)

                // Side Menu Overlay
                if viewModel.isSideMenuOpen {
                    sideMenuOverlay
                }
            }
            .gesture(swipeGesture)
            .navigationTitle(viewModel.navigationTitle)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                toolbarContent
            }
            // Article Preview UI Improvement: カードタップで直接WebView表示
            .navigationDestination(for: ArticleBookmark.self) { bookmark in
                if let urlString = bookmark.url, let url = URL(string: urlString) {
                    ArticleWebView(url: url, bookmark: bookmark)
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .sheet(isPresented: $showingAddBookmark) {
                AddBookmarkView(onComplete: { success in
                    if success {
                        viewModel.loadData()
                    }
                })
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .sheet(item: $selectedBookmarkForDetail) { bookmark in
                ArticleDetailView(bookmark: bookmark, onUpdate: {
                    viewModel.loadData()
                })
            }
            // Task 4: Quick Action sheets
            .sheet(item: $selectedBookmarkForMemo) { bookmark in
                AddMemoSheet(
                    bookmark: bookmark,
                    onDismiss: {
                        selectedBookmarkForMemo = nil
                        viewModel.loadData()
                    }
                )
            }
            .sheet(item: $selectedBookmarkForTags) { bookmark in
                TagSelectionView(
                    bookmark: bookmark,
                    onSave: {
                        selectedBookmarkForTags = nil
                        viewModel.loadData()
                    }
                )
            }
            .alert("ブックマークを削除", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {
                    bookmarkToDelete = nil
                }
                Button("削除", role: .destructive) {
                    if let bookmark = bookmarkToDelete {
                        viewModel.deleteBookmark(bookmark)
                        bookmarkToDelete = nil
                    }
                }
            } message: {
                Text("このブックマークを削除してもよろしいですか？")
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Tab Bar
            tabBar

            // Content based on current tab
            if viewModel.currentTab == .newEntry && viewModel.selectedMenuItem == nil && viewModel.selectedDomain == nil {
                newEntryContent
            } else if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredBookmarks.isEmpty {
                emptyStateView
            } else {
                bookmarkList
            }
        }
        .background(Color.systemGroupedBackground)
    }

    // MARK: - New Entry Content

    private var newEntryContent: some View {
        Group {
            if newEntryViewModel.isLoading {
                loadingView
            } else if !newEntryViewModel.hasRegisteredFeeds {
                newEntryEmptyNoFeeds
            } else if newEntryViewModel.articles.isEmpty {
                newEntryEmptyNoArticles
            } else {
                newEntryList
            }
        }
        .onAppear {
            // Load cached articles first, then refresh in background
            newEntryViewModel.loadArticles()
            Task {
                await newEntryViewModel.refreshFeeds()
            }
        }
        .toast(
            isPresented: $newEntryViewModel.showToast,
            message: newEntryViewModel.toastMessage,
            type: newEntryViewModel.toastType
        )
    }

    private var newEntryList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Last refresh info
                if let refreshInfo = newEntryViewModel.formattedLastRefresh() {
                    HStack {
                        Text(refreshInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button {
                            Task {
                                await newEntryViewModel.refreshFeeds()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal)
                }

                ForEach(newEntryViewModel.articles, id: \.id) { article in
                    ArticleCardView(
                        bookmark: article,
                        onFavoriteTap: {},
                        onCardTap: {
                            // Mark as viewed and navigate to WebView
                            newEntryViewModel.markAsViewed(article)
                            navigationPath.append(article)
                        },
                        onAddBookmark: {
                            newEntryViewModel.addToBookmark(article)
                            // Refresh Bookmark list immediately
                            viewModel.loadData()
                        },
                        onFollowBlog: {
                            Task {
                                await viewModel.followBlog(
                                    domain: article.domain ?? "",
                                    articleURL: article.url ?? ""
                                )
                            }
                        },
                        onUnfollowBlog: {
                            viewModel.unfollowBlog(domain: article.domain ?? "")
                        },
                        isFollowingBlog: viewModel.isFollowingBlog(domain: article.domain ?? "")
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await newEntryViewModel.refreshFeeds()
        }
    }

    private var newEntryEmptyNoFeeds: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("RSSフィードがありません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("ブックマークを追加すると、自動的にRSSフィードを検出します")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showingAddBookmark = true
            } label: {
                Label("ブックマークを追加", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)

            Spacer()
        }
    }

    private var newEntryEmptyNoArticles: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("新しい記事はありません")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("登録済みブログの新着記事がここに表示されます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await newEntryViewModel.refreshFeeds()
                }
            } label: {
                Label("更新", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTabType.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .background(Color.systemBackground)
    }

    private func tabButton(_ tab: MainTabType) -> some View {
        let isSelected = viewModel.currentTab == tab && viewModel.selectedMenuItem == nil

        return Button {
            viewModel.selectTab(tab)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.systemIcon)
                    .font(.system(size: 20))
                Text(tab.displayName)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                VStack {
                    Spacer()
                    if isSelected {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 2)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bookmark List

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredBookmarks, id: \.id) { bookmark in
                    // Article Preview UI Improvement: カードタップで直接WebView表示
                    // Task 4: ロングプレスメニュー対応
                    ArticleCardView(
                        bookmark: bookmark,
                        onFavoriteTap: {
                            viewModel.toggleFavorite(bookmark)
                        },
                        onCardTap: {
                            navigationPath.append(bookmark)
                        },
                        onAddMemo: {
                            selectedBookmarkForMemo = bookmark
                        },
                        onEditTags: {
                            selectedBookmarkForTags = bookmark
                        },
                        onShowDetail: {
                            selectedBookmarkForDetail = bookmark
                        },
                        onDelete: {
                            bookmarkToDelete = bookmark
                            showDeleteConfirmation = true
                        },
                        onFollowBlog: {
                            Task {
                                await viewModel.followBlog(
                                    domain: bookmark.domain ?? "",
                                    articleURL: bookmark.url ?? ""
                                )
                            }
                        },
                        onUnfollowBlog: {
                            viewModel.unfollowBlog(domain: bookmark.domain ?? "")
                        },
                        isFollowingBlog: viewModel.isFollowingBlog(domain: bookmark.domain ?? "")
                    )
                    .contextMenu {
                        bookmarkContextMenu(bookmark)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    private func bookmarkContextMenu(_ bookmark: ArticleBookmark) -> some View {
        Group {
            // この記事を保存（お気に入り）
            Button {
                viewModel.toggleFavorite(bookmark)
            } label: {
                Label(
                    bookmark.isFavorite ? "この記事の保存を解除" : "この記事を保存",
                    systemImage: bookmark.isFavorite ? "star.slash" : "star"
                )
            }

            // このブログをフォロー
            if viewModel.isFollowingBlog(domain: bookmark.domain ?? "") {
                Button {
                    viewModel.unfollowBlog(domain: bookmark.domain ?? "")
                } label: {
                    Label("このブログのフォローを解除", systemImage: "newspaper.circle.fill")
                }
            } else {
                Button {
                    Task {
                        await viewModel.followBlog(
                            domain: bookmark.domain ?? "",
                            articleURL: bookmark.url ?? ""
                        )
                    }
                } label: {
                    Label("このブログをフォロー", systemImage: "newspaper.circle")
                }
            }

            Divider()

            // 削除（破壊的操作）
            Button(role: .destructive) {
                viewModel.deleteBookmark(bookmark)
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Spacer()
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: emptyStateIcon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text(emptyStateTitle)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if viewModel.selectedMenuItem == nil {
                Button {
                    showingAddBookmark = true
                } label: {
                    Label("ブックマークを追加", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var emptyStateIcon: String {
        if let menuItem = viewModel.selectedMenuItem {
            return menuItem.systemIcon
        }
        return viewModel.currentTab.systemIcon
    }

    private var emptyStateTitle: String {
        if let menuItem = viewModel.selectedMenuItem {
            return "\(menuItem.displayName)がありません"
        }
        return "ブックマークがありません"
    }

    private var emptyStateMessage: String {
        if viewModel.selectedMenuItem != nil {
            return "このカテゴリにはまだ記事がありません"
        }
        return "「+」ボタンからブックマークを追加してください"
    }

    // MARK: - Side Menu Overlay

    private var sideMenuOverlay: some View {
        SideMenuView(
            viewModel: viewModel,
            onSettingsTap: {
                viewModel.closeSideMenu()
                showingSettings = true
            }
        )
        .transition(.move(edge: .leading))
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .global)
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let translation = value.translation.width
                let velocity = value.predictedEndLocation.x - value.location.x
                let startX = value.startLocation.x

                print("Swipe detected - startX: \(startX), translation: \(translation), velocity: \(velocity)")

                // Open menu: swipe right from left edge or with strong velocity
                // Task6 User Test Fix: スワイプ感度を改善（反応エリア拡大、閾値緩和）
                if !viewModel.isSideMenuOpen {
                    // Must start near left edge (within 120pt) AND swipe right significantly
                    if startX < 120 && (translation > 80 || velocity > 200) {
                        print("Opening side menu")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.openSideMenu()
                        }
                    }
                }
                // Close menu: swipe left when menu is open
                else {
                    if translation < -50 || velocity < -100 {
                        print("Closing side menu")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.closeSideMenu()
                        }
                    }
                }

                dragOffset = 0
            }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarLeading) {
            menuButton
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 16) {
                searchButton
                addButton
            }
        }
        #else
        ToolbarItem(placement: .automatic) {
            HStack {
                menuButton
                Spacer()
                searchButton
                addButton
            }
        }
        #endif
    }

    private var menuButton: some View {
        Button {
            viewModel.toggleSideMenu()
        } label: {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18))
        }
    }

    private var searchButton: some View {
        Button {
            showingSearch = true
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18))
        }
    }

    private var addButton: some View {
        Button {
            showingAddBookmark = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
