//
//  AddMemoView.swift
//  KiroBookmark
//
//  View for adding and editing memos with type selection and character counter
//

import SwiftUI
import CoreData

struct AddMemoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddMemoViewModel()
    @FocusState private var isTextEditorFocused: Bool

    let bookmark: ArticleBookmark
    let memo: TweetMemo?
    let onSave: () -> Void

    init(bookmark: ArticleBookmark, memo: TweetMemo? = nil, onSave: @escaping () -> Void) {
        self.bookmark = bookmark
        self.memo = memo
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    memoTypeSection
                    contentSection
                    if viewModel.isQuoteMemo {
                        quotePreviewSection
                    }
                    if let error = viewModel.errorMessage {
                        errorSection(error)
                    }
                }
                .padding(16)
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle(viewModel.isEditing ? "メモを編集" : "メモを追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }
                ToolbarItem(placement: .confirmationAction) {
                    saveButton
                }
                #endif
            }
            .onAppear {
                configureViewModel()
            }
            .onChange(of: viewModel.isSaved) { _, isSaved in
                if isSaved {
                    onSave()
                    dismiss()
                }
            }
        }
    }

    // MARK: - Memo Type Section

    private var memoTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("メモ種類")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if viewModel.isQuoteMemo {
                quoteMemoTypeBadge
            } else {
                memoTypePicker
            }
        }
    }

    private var quoteMemoTypeBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: MemoType.quote.systemIcon)
            Text(MemoType.quote.displayName)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MemoType.quote.color)
        .cornerRadius(8)
    }

    private var memoTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MemoType.allCases.filter { $0 != .quote }, id: \.self) { type in
                    memoTypeButton(for: type)
                }
            }
        }
    }

    private func memoTypeButton(for type: MemoType) -> some View {
        let isSelected = viewModel.selectedMemoType == type

        return Button {
            viewModel.selectedMemoType = type
        } label: {
            HStack(spacing: 6) {
                Image(systemName: type.systemIcon)
                Text(type.displayName)
            }
            .font(.subheadline)
            .foregroundColor(isSelected ? .white : type.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? type.color : type.color.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("メモ内容")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                characterCounter
            }

            textEditor
        }
    }

    private var characterCounter: some View {
        Text(viewModel.characterCountText)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(viewModel.isOverLimit ? .red : .secondary)
    }

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $viewModel.content)
                .frame(minHeight: 150)
                .padding(8)
                .focused($isTextEditorFocused)

            if viewModel.content.isEmpty {
                Text("ここにメモを入力...")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                    .allowsHitTesting(false)
            }
        }
        .background(Color.systemBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    viewModel.isOverLimit ? Color.red : Color.systemGray4,
                    lineWidth: 1
                )
        )
    }

    // MARK: - Quote Preview Section

    private var quotePreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("引用元")
                .font(.subheadline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                if !viewModel.selectedText.isEmpty {
                    Text("「\(viewModel.selectedText)」")
                        .font(.callout)
                        .italic()
                        .foregroundColor(.secondary)
                        .lineLimit(5)
                }

                if !viewModel.sourceURL.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text(viewModel.sourceURL)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                Rectangle()
                    .fill(Color.purple)
                    .frame(width: 3),
                alignment: .leading
            )
        }
    }

    // MARK: - Error Section

    private func errorSection(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text(message)
        }
        .font(.subheadline)
        .foregroundColor(.red)
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Buttons

    private var cancelButton: some View {
        Button("キャンセル") {
            dismiss()
        }
    }

    private var saveButton: some View {
        Button("保存") {
            viewModel.save()
        }
        .fontWeight(.semibold)
        .disabled(!viewModel.isValid || viewModel.isLoading)
    }

    // MARK: - Configuration

    private func configureViewModel() {
        if let memo = memo {
            viewModel.configure(bookmark: bookmark, memo: memo)
        } else {
            viewModel.configure(bookmark: bookmark)
        }
        isTextEditorFocused = true
    }
}

// MARK: - Quote Memo Initializer

extension AddMemoView {
    init(
        bookmark: ArticleBookmark,
        selectedText: String,
        sourceURL: String,
        onSave: @escaping () -> Void
    ) {
        self.bookmark = bookmark
        self.memo = nil
        self.onSave = onSave
        // Note: configureForQuote will be called in onAppear
    }
}

// MARK: - Preview

#Preview("Add Memo") {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "SwiftUIで美しいUIを作る方法"
    bookmark.url = "https://example.com/swiftui"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()

    return AddMemoView(bookmark: bookmark, onSave: {})
}

#Preview("Edit Memo") {
    let controller = PersistenceController.preview
    let context = controller.container.viewContext

    let bookmark = ArticleBookmark(context: context)
    bookmark.id = UUID()
    bookmark.title = "SwiftUIで美しいUIを作る方法"
    bookmark.url = "https://example.com/swiftui"
    bookmark.domain = "example.com"
    bookmark.bookmarkedDate = Date()

    let memo = TweetMemo(context: context)
    memo.id = UUID()
    memo.content = "これは編集中のメモです"
    memo.memoType = MemoType.idea.rawValue
    memo.createdDate = Date()
    memo.updatedDate = Date()
    memo.bookmark = bookmark

    return AddMemoView(bookmark: bookmark, memo: memo, onSave: {})
}
