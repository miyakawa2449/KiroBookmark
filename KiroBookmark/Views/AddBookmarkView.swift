//
//  AddBookmarkView.swift
//  KiroBookmark
//
//  View for adding new bookmarks
//

import SwiftUI

struct AddBookmarkView: View {
    @StateObject private var viewModel = AddBookmarkViewModel()
    @Environment(\.dismiss) private var dismiss

    let onComplete: (Bool) -> Void

    var body: some View {
        NavigationStack {
            Form {
                urlInputSection
                validationStatusSection
                favoriteBlogSection
            }
            .navigationTitle("ブックマーク追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - URL Input Section

    private var urlInputSection: some View {
        Section {
            TextField("https://example.com/article", text: $viewModel.urlString)
                .keyboardType(.URL)
                .textContentType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .onChange(of: viewModel.urlString) { _, _ in
                    viewModel.validateURL()
                }
        } header: {
            Text("URL")
        } footer: {
            if let error = viewModel.validationResult?.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
    }

    // MARK: - Validation Status Section

    @ViewBuilder
    private var validationStatusSection: some View {
        if let result = viewModel.validationResult, result.isValid {
            Section("プレビュー") {
                HStack {
                    Image(systemName: "globe")
                        .foregroundColor(.secondary)
                    Text(result.domain ?? "")
                        .foregroundColor(.primary)
                }

                HStack {
                    Image(systemName: "link")
                        .foregroundColor(.secondary)
                    Text(result.normalizedURL ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("有効なURL")
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Favorite Blog Section

    @ViewBuilder
    private var favoriteBlogSection: some View {
        if let result = viewModel.validationResult, result.isValid {
            Section {
                if viewModel.isFavoriteBlog {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("お気に入りブログに登録済み")
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button {
                        Task {
                            await viewModel.addToFavoriteBlogs()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "star")
                            Text("お気に入りブログに追加")
                        }
                    }
                }
            } header: {
                Text("ブログ設定")
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("キャンセル") {
                dismiss()
                onComplete(false)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("追加") {
                Task {
                    let success = await viewModel.saveBookmark()
                    if success {
                        dismiss()
                        onComplete(true)
                    }
                }
            }
            .disabled(!viewModel.canSave)
        }
    }
}

// MARK: - Preview

#Preview {
    AddBookmarkView { _ in }
}
