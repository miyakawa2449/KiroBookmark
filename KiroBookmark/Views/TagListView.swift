//
//  TagListView.swift
//  KiroBookmark
//
//  View for displaying and managing all tags
//

import SwiftUI
import CoreData

struct TagListView: View {
    @StateObject private var viewModel = TagListViewModel()
    @State private var showingAddTag = false
    @State private var editingTag: Tag?
    @State private var showingDeleteConfirmation = false
    @State private var tagToDelete: Tag?
    @State private var newTagName = ""
    @State private var editTagName = ""

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            tagListSection
        }
        .navigationTitle("タグ管理")
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
        .alert("タグを追加", isPresented: $showingAddTag) {
            TextField("タグ名", text: $newTagName)
            Button("キャンセル", role: .cancel) {
                newTagName = ""
            }
            Button("追加") {
                _ = viewModel.createTag(name: newTagName)
                newTagName = ""
            }
            .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .alert("タグを編集", isPresented: .init(
            get: { editingTag != nil },
            set: { if !$0 { editingTag = nil } }
        )) {
            TextField("タグ名", text: $editTagName)
            Button("キャンセル", role: .cancel) {
                editingTag = nil
                editTagName = ""
            }
            Button("保存") {
                if let tag = editingTag {
                    viewModel.updateTagName(tag, name: editTagName)
                }
                editingTag = nil
                editTagName = ""
            }
        }
        .alert("タグを削除", isPresented: $showingDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                if let tag = tagToDelete {
                    viewModel.deleteTag(tag)
                }
            }
        } message: {
            Text("「\(tagToDelete?.name ?? "")」を削除しますか？関連する記事からもこのタグが外れます。")
        }
        .onAppear {
            viewModel.loadTags()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("タグを検索...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .onChange(of: viewModel.searchQuery) { _, newValue in
                    viewModel.search(newValue)
                }
            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.loadTags()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
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
            Text(viewModel.searchQuery.isEmpty ? "タグがありません" : "検索結果がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            if viewModel.searchQuery.isEmpty {
                Text("「+」ボタンからタグを追加できます")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var tagList: some View {
        List {
            ForEach(viewModel.filteredTags, id: \.id) { tag in
                TagRowView(
                    tag: tag,
                    onEdit: {
                        editTagName = tag.name ?? ""
                        editingTag = tag
                    },
                    onDelete: {
                        tagToDelete = tag
                        showingDeleteConfirmation = true
                    }
                )
            }
            .onDelete(perform: viewModel.deleteTags)
        }
        .listStyle(.plain)
    }

    // MARK: - Add Button

    private var addButton: some View {
        Button {
            showingAddTag = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .semibold))
        }
    }
}

// MARK: - Tag Row View

struct TagRowView: View {
    let tag: Tag
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            tagIcon
            tagInfo
            Spacer()
            usageCountBadge
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("編集", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("削除", systemImage: "trash")
            }
        }
    }

    private var tagIcon: some View {
        Image(systemName: "tag.fill")
            .font(.system(size: 16))
            .foregroundColor(tagColor)
    }

    private var tagInfo: some View {
        Text(tag.name ?? "")
            .font(.body)
            .foregroundColor(.primary)
    }

    private var usageCountBadge: some View {
        Text("\(tag.usageCount)")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.systemGray5)
            .cornerRadius(10)
    }

    private var tagColor: Color {
        if let colorString = tag.color, !colorString.isEmpty {
            // Parse color from string if needed
            return .blue
        }
        return .blue
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TagListView()
    }
}
