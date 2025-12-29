//
//  ArticleDetailView.swift
//  KiroBookmark
//
//  Detailed view for a bookmarked article
//

import SwiftUI
import CoreData
import Combine

struct ArticleDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ArticleDetailViewModel

    let bookmark: ArticleBookmark
    let onUpdate: () -> Void

    // Article Preview UI Improvement: showingWebView を削除
    // 理由: カードタップで直接WebView表示するため、詳細画面からの遷移は不要
    @State private var showingAddMemo = false
    @State private var showingTagSelection = false
    @State private var showingDeleteConfirmation = false
    @State private var isFavorite: Bool = false

    init(bookmark: ArticleBookmark, onUpdate: @escaping () -> Void) {
        self.bookmark = bookmark
        self.onUpdate = onUpdate
        self._viewModel = StateObject(wrappedValue: ArticleDetailViewModel(bookmark: bookmark))
        self._isFavorite = State(initialValue: bookmark.isFavorite)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    actionButtons
                    if !viewModel.tags.isEmpty {
                        tagsSection
                    }
                    memosSection
                }
                .padding()
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("記事詳細")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    moreButton
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    closeButton
                }
                ToolbarItem(placement: .automatic) {
                    moreButton
                }
                #endif
            }
            // Article Preview UI Improvement: WebView sheet を削除
            .sheet(isPresented: $showingAddMemo) {
                AddMemoView(bookmark: bookmark) {
                    viewModel.loadData()
                    onUpdate()
                }
            }
            .sheet(isPresented: $showingTagSelection) {
                TagSelectionView(bookmark: bookmark) {
                    viewModel.loadData()
                    onUpdate()
                }
            }
            .alert("ブックマークを削除", isPresented: $showingDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除", role: .destructive) {
                    viewModel.deleteBookmark()
                    onUpdate()
                    dismiss()
                }
            } message: {
                Text("このブックマークと関連するメモを削除しますか？")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(bookmark.title ?? "無題")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // URL
            if let urlString = bookmark.url {
                HStack {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(urlString)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }

            // Domain and date
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .font(.caption)
                    Text(bookmark.domain ?? "")
                        .font(.caption)
                }
                .foregroundColor(.secondary)

                Spacer()

                if let date = bookmark.bookmarkedDate {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatDate(date))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
    }

    // MARK: - Action Buttons
    // Article Preview UI Improvement: 「記事を読む」ボタンを削除
    // 理由: カードタップで直接WebView表示するため、このボタンは不要

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Favorite toggle
            Button {
                isFavorite.toggle()
                viewModel.toggleFavorite()
                onUpdate()
            } label: {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 24))
                    .foregroundColor(isFavorite ? .red : .secondary)
                    .frame(width: 44, height: 44)
            }

            // Add memo
            Button {
                showingAddMemo = true
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }

            // Add tag
            Button {
                showingTagSelection = true
            } label: {
                Image(systemName: "tag")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("タグ")
                    .font(.headline)
                Spacer()
                Button {
                    showingTagSelection = true
                } label: {
                    Text("編集")
                        .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.tags, id: \.id) { tag in
                        tagChip(tag)
                    }
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
    }

    private func tagChip(_ tag: Tag) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "tag.fill")
                .font(.caption2)
            Text(tag.name ?? "")
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }

    // MARK: - Memos Section

    private var memosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("メモ")
                    .font(.headline)
                Text("(\(viewModel.memos.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    showingAddMemo = true
                } label: {
                    Image(systemName: "plus")
                        .font(.caption)
                }
            }

            if viewModel.memos.isEmpty {
                emptyMemosView
            } else {
                ForEach(viewModel.memos, id: \.id) { memo in
                    memoRow(memo)
                }
            }
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
    }

    private var emptyMemosView: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            Text("メモがありません")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button {
                showingAddMemo = true
            } label: {
                Label("メモを追加", systemImage: "plus")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func memoRow(_ memo: TweetMemo) -> some View {
        let memoType = MemoType(rawValue: memo.memoType ?? "") ?? .other

        return VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: memoType.systemIcon)
                        .font(.caption)
                    Text(memoType.displayName)
                        .font(.caption)
                }
                .foregroundColor(memoType.color)

                Spacer()

                if let date = memo.createdDate {
                    Text(formatDate(date))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Quote (if present)
            if memo.isQuote, let selectedText = memo.selectedText {
                Text("「\(selectedText)」")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
            }

            // Content
            Text(memo.content ?? "")
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color.systemGray6)
        .cornerRadius(8)
    }

    // MARK: - Toolbar Buttons

    private var closeButton: some View {
        Button("閉じる") {
            dismiss()
        }
    }

    private var moreButton: some View {
        Menu {
            Button {
                showingTagSelection = true
            } label: {
                Label("タグを編集", systemImage: "tag")
            }

            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("削除", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - ArticleDetailViewModel

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published var memos: [TweetMemo] = []
    @Published var tags: [Tag] = []

    private let bookmark: ArticleBookmark
    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let memoRepository: MemoRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol

    init(
        bookmark: ArticleBookmark,
        bookmarkRepository: BookmarkRepositoryProtocol = BookmarkRepository(),
        memoRepository: MemoRepositoryProtocol = MemoRepository(),
        tagRepository: TagRepositoryProtocol = TagRepository()
    ) {
        self.bookmark = bookmark
        self.bookmarkRepository = bookmarkRepository
        self.memoRepository = memoRepository
        self.tagRepository = tagRepository
        loadData()
    }

    func loadData() {
        // Load memos
        if let bookmarkMemos = bookmark.memos as? Set<TweetMemo> {
            memos = Array(bookmarkMemos).sorted {
                ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast)
            }
        }

        // Load tags
        if let bookmarkTags = bookmark.tags as? Set<Tag> {
            tags = Array(bookmarkTags).sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
    }

    func toggleFavorite() {
        try? bookmarkRepository.toggleFavorite(bookmark)
    }

    func deleteBookmark() {
        try? bookmarkRepository.delete(bookmark)
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "SwiftUIの基礎から応用まで完全解説"
    bookmark.url = "https://example.com/swiftui-guide"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()
    bookmark.isFavorite = true

    return ArticleDetailView(bookmark: bookmark, onUpdate: {})
}
