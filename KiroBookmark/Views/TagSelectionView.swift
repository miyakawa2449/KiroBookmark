//
//  TagSelectionView.swift
//  KiroBookmark
//
//  View for selecting tags for a bookmark with search and create functionality
//

import SwiftUI
import CoreData

struct TagSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = TagSelectionViewModel()

    let bookmark: ArticleBookmark
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchAndCreateSection
                if !viewModel.frequentTags.isEmpty && viewModel.searchQuery.isEmpty {
                    frequentTagsSection
                }
                tagListSection
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("タグ選択")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    doneButton
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItem(placement: .confirmationAction) {
                    doneButton
                }
                #endif
            }
            .onAppear {
                viewModel.configure(bookmark: bookmark)
            }
        }
    }

    // MARK: - Search and Create Section

    private var searchAndCreateSection: some View {
        VStack(spacing: 12) {
            searchBar
            if viewModel.canCreateNewTag {
                createTagButton
            }
        }
        .padding(16)
        .background(Color.systemBackground)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("タグを検索または追加...", text: $viewModel.newTagName)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.newTagName) { _, newValue in
                    viewModel.search(newValue)
                }
            if !viewModel.newTagName.isEmpty {
                Button {
                    viewModel.newTagName = ""
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.systemGray5)
        .cornerRadius(10)
    }

    private var createTagButton: some View {
        Button {
            viewModel.createAndSelectTag()
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("「\(viewModel.newTagName)」を作成")
                Spacer()
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(12)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Frequent Tags Section

    private var frequentTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("よく使うタグ")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.frequentTags, id: \.id) { tag in
                        TagChipView(
                            tag: tag,
                            isSelected: viewModel.isSelected(tag),
                            onTap: {
                                viewModel.toggleSelection(tag)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color.systemBackground)
    }

    // MARK: - Tag List Section

    private var tagListSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.filteredTags.isEmpty {
                emptyStateView
            } else {
                tagList
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
            Image(systemName: "tag")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("タグがありません")
                .font(.headline)
                .foregroundColor(.secondary)
            if !viewModel.newTagName.isEmpty && viewModel.canCreateNewTag {
                Text("上のボタンで新規タグを作成できます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var tagList: some View {
        List {
            Section {
                ForEach(viewModel.filteredTags, id: \.id) { tag in
                    TagSelectionRowView(
                        tag: tag,
                        isSelected: viewModel.isSelected(tag),
                        onToggle: {
                            viewModel.toggleSelection(tag)
                        }
                    )
                }
            } header: {
                Text("すべてのタグ（使用頻度順）")
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.plain)
        #endif
    }

    // MARK: - Buttons

    private var cancelButton: some View {
        Button("キャンセル") {
            dismiss()
        }
    }

    private var doneButton: some View {
        Button("完了") {
            viewModel.saveSelectionToBookmark()
            onSave()
            dismiss()
        }
        .fontWeight(.semibold)
    }
}

// MARK: - Tag Chip View

struct TagChipView: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "tag.fill")
                    .font(.caption)
                Text(tag.name ?? "")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.systemGray5)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tag Selection Row View

struct TagSelectionRowView: View {
    let tag: Tag
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text(tag.name ?? "")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(tag.usageCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.system(size: 20))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "Test Article"
    bookmark.url = "https://example.com"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()

    return TagSelectionView(bookmark: bookmark, onSave: {})
}
