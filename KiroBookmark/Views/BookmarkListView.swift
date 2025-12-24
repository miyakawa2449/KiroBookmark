//
//  BookmarkListView.swift
//  KiroBookmark
//
//  List view for displaying bookmarks
//

import SwiftUI
import CoreData

struct BookmarkListView: View {
    @StateObject private var viewModel = BookmarkListViewModel()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bookmark")
                .toolbar { toolbarContent }
                .sheet(isPresented: $showingAddSheet) {
                    AddBookmarkView { success in
                        if success {
                            viewModel.loadBookmarks()
                        }
                    }
                }
        }
        .onAppear {
            viewModel.loadBookmarks()
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            ProgressView("読み込み中...")
        } else if viewModel.bookmarks.isEmpty {
            emptyStateView
        } else {
            bookmarkList
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("ブックマークがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("右上の+ボタンから追加してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    private var bookmarkList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.bookmarks, id: \.id) { bookmark in
                    BookmarkCardView(
                        bookmark: bookmark,
                        onFavoriteToggle: {
                            viewModel.toggleFavorite(bookmark)
                        },
                        onDelete: {
                            viewModel.deleteBookmark(bookmark)
                        }
                    )
                    .contextMenu {
                        contextMenuItems(for: bookmark)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            viewModel.loadBookmarks()
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for bookmark: ArticleBookmark) -> some View {
        Button {
            viewModel.toggleFavorite(bookmark)
        } label: {
            Label(
                bookmark.isFavorite ? "お気に入り解除" : "お気に入り",
                systemImage: bookmark.isFavorite ? "heart.slash" : "heart"
            )
        }

        Menu("読書状態") {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Button {
                    viewModel.updateReadingStatus(bookmark, status: status)
                } label: {
                    Label(status.displayName, systemImage: status.systemIcon)
                }
            }
        }

        Divider()

        Button(role: .destructive) {
            viewModel.deleteBookmark(bookmark)
        } label: {
            Label("削除", systemImage: "trash")
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
        }

        ToolbarItem(placement: .secondaryAction) {
            Menu {
                Button {
                    viewModel.sortByBookmarkDate()
                } label: {
                    Label("登録日順", systemImage: "calendar")
                }
                Button {
                    viewModel.sortByPublishDate()
                } label: {
                    Label("公開日順", systemImage: "clock")
                }
                Button {
                    viewModel.sortByTitle()
                } label: {
                    Label("タイトル順", systemImage: "textformat")
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BookmarkListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
