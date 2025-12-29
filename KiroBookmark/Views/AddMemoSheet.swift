//
//  AddMemoSheet.swift
//  KiroBookmark
//
//  Sheet view for adding memos to a bookmark (Task 2: Article Preview UI Improvement)
//

import SwiftUI
import CoreData

struct AddMemoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var memoContent = ""
    @State private var selectedMemoType: MemoType
    @FocusState private var isTextFieldFocused: Bool

    let bookmark: ArticleBookmark
    let preselectedType: MemoType?  // Task 3: 事前選択されたメモタイプ
    let onDismiss: () -> Void

    private let memoRepository = MemoRepository()

    // MARK: - Constants

    private static let maxCharacterCount = 300
    private static let memoTypes: [MemoType] = [.thought, .idea, .todo, .other]

    // MARK: - Initialization

    init(bookmark: ArticleBookmark, preselectedType: MemoType? = nil, onDismiss: @escaping () -> Void) {
        self.bookmark = bookmark
        self.preselectedType = preselectedType
        self.onDismiss = onDismiss
        // 事前選択がある場合はそれを使用、なければ.thought
        _selectedMemoType = State(initialValue: preselectedType ?? .thought)
    }

    // MARK: - Computed Properties

    private var navigationTitle: String {
        if preselectedType == .todo {
            return "TODOを追加"
        }
        return "メモ追加"
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // Article Preview UI Improvement: 記事セクションを削除して入力欄を広くする
                memoTypeSection
                contentSection
                Spacer()
            }
            .padding()
            .background(Color.systemGroupedBackground)
            .navigationTitle(navigationTitle)
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

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("メモ内容", systemImage: "pencil")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                characterCounter
            }

            TextField("メモを入力...", text: $memoContent, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(5...15)
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

    // MARK: - Buttons

    private var cancelButton: some View {
        Button("キャンセル") {
            onDismiss()
            dismiss()
        }
    }

    private var saveButton: some View {
        Button("保存") {
            saveMemo()
        }
        .fontWeight(.semibold)
        .disabled(memoContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Actions

    private func saveMemo() {
        let trimmedContent = memoContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        do {
            _ = try memoRepository.create(
                content: trimmedContent,
                memoType: selectedMemoType,
                bookmark: bookmark
            )
            onDismiss()
            dismiss()
        } catch {
            print("Failed to save memo: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    AddMemoSheet(
        bookmark: {
            let context = PersistenceController.preview.container.viewContext
            let bookmark = ArticleBookmark(context: context)
            bookmark.id = UUID()
            bookmark.title = "サンプル記事タイトル"
            bookmark.domain = "example.com"
            bookmark.url = "https://example.com/article"
            return bookmark
        }(),
        onDismiss: {}
    )
}
