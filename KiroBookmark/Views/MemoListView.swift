//
//  MemoListView.swift
//  KiroBookmark
//
//  List view for displaying memos with type filtering
//

import SwiftUI
import CoreData

struct MemoListView: View {
    @StateObject private var viewModel = MemoListViewModel()
    @State private var showingAddMemo = false
    @State private var editingMemo: TweetMemo?
    @State private var showingDeleteConfirmation = false
    @State private var memoToDelete: TweetMemo?

    let bookmark: ArticleBookmark

    var body: some View {
        VStack(spacing: 0) {
            memoTypeFilterSection
            memoListSection
        }
        .navigationTitle("メモ")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                addButton
            }
            #else
            ToolbarItem(placement: .automatic) {
                addButton
            }
            #endif
        }
        .sheet(isPresented: $showingAddMemo) {
            AddMemoView(bookmark: bookmark, onSave: {
                viewModel.loadMemos()
            })
        }
        .sheet(item: $editingMemo) { memo in
            AddMemoView(bookmark: bookmark, memo: memo, onSave: {
                viewModel.loadMemos()
            })
        }
        .alert("メモを削除", isPresented: $showingDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                if let memo = memoToDelete {
                    viewModel.deleteMemo(memo)
                }
            }
        } message: {
            Text("このメモを削除しますか？")
        }
        .onAppear {
            viewModel.configure(with: bookmark)
        }
    }

    // MARK: - Memo Type Filter Section

    private var memoTypeFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFilterButton
                ForEach(MemoType.allCases, id: \.self) { memoType in
                    memoTypeFilterButton(for: memoType)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.systemBackground)
    }

    private var allFilterButton: some View {
        Button {
            viewModel.clearFilter()
        } label: {
            HStack(spacing: 4) {
                Text("すべて")
                    .font(.subheadline)
                Text("(\(viewModel.totalMemoCount()))")
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                viewModel.selectedMemoType == nil
                    ? Color.blue
                    : Color.systemGray5
            )
            .foregroundColor(
                viewModel.selectedMemoType == nil
                    ? .white
                    : .primary
            )
            .cornerRadius(16)
        }
    }

    private func memoTypeFilterButton(for memoType: MemoType) -> some View {
        let count = viewModel.memoCount(for: memoType)
        let isSelected = viewModel.selectedMemoType == memoType

        return Button {
            viewModel.selectMemoType(memoType)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: memoType.systemIcon)
                    .font(.caption)
                Text(memoType.displayName)
                    .font(.subheadline)
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? memoType.color : Color.systemGray5)
            .foregroundColor(isSelected ? .white : memoType.color)
            .cornerRadius(16)
        }
        .opacity(count > 0 ? 1.0 : 0.5)
    }

    // MARK: - Memo List Section

    private var memoListSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredMemos.isEmpty {
                emptyStateView
            } else {
                memoList
            }
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("メモがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("「+」ボタンからメモを追加できます")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var memoList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredMemos, id: \.id) { memo in
                    MemoCardView(
                        memo: memo,
                        onEdit: {
                            editingMemo = memo
                        },
                        onDelete: {
                            memoToDelete = memo
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(16)
        }
        .background(Color.systemGroupedBackground)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showingAddMemo = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
        }
    }
}

// MARK: - Memo Type Section View

struct MemoTypeSectionView: View {
    let memoType: MemoType
    let memos: [TweetMemo]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAddMemo: () -> Void
    let onEditMemo: (TweetMemo) -> Void
    let onDeleteMemo: (TweetMemo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader
            if isExpanded && !memos.isEmpty {
                sectionContent
            }
        }
        .background(Color.systemBackground)
        .cornerRadius(12)
    }

    private var sectionHeader: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: memoType.systemIcon)
                    .foregroundColor(memoType.color)
                Text(memoType.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("(\(memos.count))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: onAddMemo) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(memoType.color)
                }
                .buttonStyle(.plain)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding(12)
        }
        .buttonStyle(.plain)
    }

    private var sectionContent: some View {
        VStack(spacing: 8) {
            ForEach(memos, id: \.id) { memo in
                MemoCardView(
                    memo: memo,
                    onEdit: { onEditMemo(memo) },
                    onDelete: { onDeleteMemo(memo) }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "SwiftUIで美しいUIを作る方法"
    bookmark.url = "https://example.com/swiftui-beautiful-ui"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()

    return NavigationStack {
        MemoListView(bookmark: bookmark)
    }
}
