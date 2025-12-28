//
//  QuoteMemoSheet.swift
//  KiroBookmark
//
//  Sheet view for creating quote memos from selected text
//

import SwiftUI
import CoreData

struct QuoteMemoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memoContent = ""
    @State private var selectedMemoType: MemoType = .quote
    @FocusState private var isTextFieldFocused: Bool

    let selectedText: String
    let sourceURL: URL
    let bookmark: ArticleBookmark?
    let onSave: (String, MemoType) -> Void
    let onCancel: () -> Void

    // MARK: - Constants

    // Task6 User Test Fix: 引用メモの文字数制限を140文字から300文字に緩和
    private static let maxCharacterCount = 300
    private static let memoTypes: [MemoType] = [.quote, .idea, .thought, .todo, .other]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    quoteSection
                    memoTypeSection
                    commentSection
                    sourceSection
                }
                .padding()
            }
            .background(Color.systemGroupedBackground)
            .navigationTitle("引用メモ作成")
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
                isTextFieldFocused = true
            }
        }
    }

    // MARK: - Quote Section

    private var quoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("選択テキスト", systemImage: "text.quote")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(selectedText)
                .font(.body)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // MARK: - Memo Type Section

    private var memoTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("メモの種類", systemImage: "tag")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.memoTypes, id: \.self) { memoType in
                        memoTypeButton(memoType)
                    }
                }
            }
        }
    }

    private func memoTypeButton(_ memoType: MemoType) -> some View {
        let isSelected = selectedMemoType == memoType
        return Button {
            selectedMemoType = memoType
        } label: {
            HStack(spacing: 4) {
                Image(systemName: memoType.systemIcon)
                    .font(.caption)
                Text(memoType.displayName)
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? memoType.color : Color.systemGray5)
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Comment Section

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("コメント", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                characterCounter
            }

            TextField("コメントを追加（任意）", text: $memoContent, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.systemBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(characterCountColor.opacity(0.3), lineWidth: 1)
                )
                .focused($isTextFieldFocused)
                .onChange(of: memoContent) { _, newValue in
                    if newValue.count > Self.maxCharacterCount {
                        memoContent = String(newValue.prefix(Self.maxCharacterCount))
                    }
                }
        }
    }

    private var characterCounter: some View {
        Text("\(memoContent.count)/\(Self.maxCharacterCount)")
            .font(.caption)
            .foregroundColor(characterCountColor)
    }

    private var characterCountColor: Color {
        let remaining = Self.maxCharacterCount - memoContent.count
        if remaining <= 0 {
            return .red
        } else if remaining <= 20 {
            return .orange
        }
        return .secondary
    }

    // MARK: - Source Section

    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("引用元", systemImage: "link")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                if let bookmark = bookmark {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bookmark.title ?? "")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(sourceURL.host ?? sourceURL.absoluteString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text(sourceURL.absoluteString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.systemBackground)
            .cornerRadius(8)
        }
    }

    // MARK: - Buttons

    private var cancelButton: some View {
        Button("キャンセル") {
            onCancel()
            dismiss()
        }
    }

    private var saveButton: some View {
        Button("保存") {
            saveQuoteMemo()
        }
        .fontWeight(.semibold)
        .disabled(bookmark == nil)
    }

    // MARK: - Actions

    private func saveQuoteMemo() {
        // Create memo content combining comment and selected text
        let content: String
        if memoContent.isEmpty {
            content = "「\(selectedText)」"
        } else {
            content = memoContent
        }

        onSave(content, selectedMemoType)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    QuoteMemoSheet(
        selectedText: "これはサンプルの選択テキストです。引用メモのプレビュー用のテキストとして使用されています。",
        sourceURL: URL(string: "https://example.com/article")!,
        bookmark: nil,
        onSave: { _, _ in },
        onCancel: { }
    )
}
