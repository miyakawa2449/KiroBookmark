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
    @State private var showingSettings = false
    @State private var showingAddBookmark = false
    @State private var selectedBookmark: ArticleBookmark?
    @State private var showingWebView = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
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
            .sheet(item: $selectedBookmark) { bookmark in
                ArticleDetailView(bookmark: bookmark, onUpdate: {
                    viewModel.loadData()
                })
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Tab Bar
            tabBar

            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredBookmarks.isEmpty {
                emptyStateView
            } else {
                bookmarkList
            }
        }
        .background(Color.systemGroupedBackground)
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
                    ArticleCardView(
                        bookmark: bookmark,
                        onFavoriteTap: {
                            viewModel.toggleFavorite(bookmark)
                        },
                        onCardTap: {
                            selectedBookmark = bookmark
                        }
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
            Button {
                viewModel.toggleFavorite(bookmark)
            } label: {
                Label(
                    bookmark.isFavorite ? "お気に入り解除" : "お気に入り",
                    systemImage: bookmark.isFavorite ? "heart.slash" : "heart"
                )
            }

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
            addButton
        }
        #else
        ToolbarItem(placement: .automatic) {
            HStack {
                menuButton
                Spacer()
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
