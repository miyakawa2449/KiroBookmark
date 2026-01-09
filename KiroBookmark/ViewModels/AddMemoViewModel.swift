//
//  AddMemoViewModel.swift
//  KiroBookmark
//
//  ViewModel for adding and editing memos
//

import Foundation
import Combine
import CoreData

@MainActor
final class AddMemoViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var content: String = ""
    @Published var selectedMemoType: MemoType = .other
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isSaved = false

    // Quote memo properties
    @Published var isQuoteMemo = false
    @Published var selectedText: String = ""
    @Published var sourceURL: String = ""

    // MARK: - Computed Properties

    var characterCount: Int {
        return content.count
    }

    var maxCharacterCount: Int {
        return MemoRepository.maxContentLength
    }

    var remainingCharacters: Int {
        return maxCharacterCount - characterCount
    }

    var isOverLimit: Bool {
        return characterCount > maxCharacterCount
    }

    var isValid: Bool {
        return !content.isEmpty && !isOverLimit
    }

    var isEditing: Bool {
        return editingMemo != nil
    }

    var characterCountText: String {
        return "\(characterCount)/\(maxCharacterCount)"
    }

    // MARK: - Dependencies

    private let memoRepository: MemoRepositoryProtocol
    private var bookmark: ArticleBookmark?
    private var editingMemo: TweetMemo?

    // MARK: - Initialization

    init(memoRepository: MemoRepositoryProtocol) {
        self.memoRepository = memoRepository
    }
    
    @MainActor
    convenience init() {
        self.init(memoRepository: MemoRepository())
    }

    // MARK: - Configuration

    func configure(bookmark: ArticleBookmark) {
        self.bookmark = bookmark
        self.editingMemo = nil
        resetForm()
    }

    func configure(bookmark: ArticleBookmark, memo: TweetMemo) {
        self.bookmark = bookmark
        self.editingMemo = memo
        loadMemoForEditing(memo)
    }

    func configureForQuote(
        bookmark: ArticleBookmark,
        selectedText: String,
        sourceURL: String
    ) {
        self.bookmark = bookmark
        self.editingMemo = nil
        self.isQuoteMemo = true
        self.selectedText = selectedText
        self.sourceURL = sourceURL
        self.selectedMemoType = .quote
        self.content = ""
    }

    // MARK: - Form Management

    private func resetForm() {
        content = ""
        selectedMemoType = .other
        isQuoteMemo = false
        selectedText = ""
        sourceURL = ""
        errorMessage = nil
        isSaved = false
    }

    private func loadMemoForEditing(_ memo: TweetMemo) {
        content = memo.content ?? ""
        selectedMemoType = MemoType(rawValue: memo.memoType ?? "") ?? .other
        isQuoteMemo = memo.isQuote
        selectedText = memo.selectedText ?? ""
        sourceURL = memo.sourceURL ?? ""
        errorMessage = nil
        isSaved = false
    }

    // MARK: - Validation

    func validateContent() -> Bool {
        if content.isEmpty {
            errorMessage = "メモ内容を入力してください"
            return false
        }

        if isOverLimit {
            errorMessage = "メモは\(maxCharacterCount)文字以内で入力してください"
            return false
        }

        errorMessage = nil
        return true
    }

    // MARK: - Save Methods

    func save() {
        guard validateContent() else { return }
        guard let bookmark = bookmark else {
            errorMessage = "ブックマークが指定されていません"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if let existingMemo = editingMemo {
                try updateMemo(existingMemo)
            } else {
                try createMemo(bookmark: bookmark)
            }
            isSaved = true
        } catch let error as MemoRepositoryError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "保存に失敗しました"
        }

        isLoading = false
    }

    private func createMemo(bookmark: ArticleBookmark) throws {
        if isQuoteMemo {
            _ = try memoRepository.createQuoteMemo(
                content: content,
                selectedText: selectedText,
                sourceURL: sourceURL,
                bookmark: bookmark
            )
        } else {
            _ = try memoRepository.create(
                content: content,
                memoType: selectedMemoType,
                bookmark: bookmark
            )
        }
    }

    private func updateMemo(_ memo: TweetMemo) throws {
        try memoRepository.updateContent(memo, content: content)
        if !isQuoteMemo {
            try memoRepository.updateMemoType(memo, memoType: selectedMemoType)
        }
    }

    // MARK: - Content Management

    func truncateContentIfNeeded() {
        if content.count > maxCharacterCount {
            content = String(content.prefix(maxCharacterCount))
        }
    }

    func appendQuotedText() {
        if !selectedText.isEmpty {
            let quotedText = "「\(selectedText)」"
            let newContent = content.isEmpty ? quotedText : "\(content)\n\(quotedText)"

            if newContent.count <= maxCharacterCount {
                content = newContent
            } else {
                let available = maxCharacterCount - content.count - 1
                if available > 3 {
                    let truncated = String(selectedText.prefix(available - 3)) + "..."
                    content = content.isEmpty ? "「\(truncated)」" : "\(content)\n「\(truncated)」"
                }
            }
        }
    }
}
