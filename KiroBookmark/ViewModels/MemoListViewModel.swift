//
//  MemoListViewModel.swift
//  KiroBookmark
//
//  ViewModel for memo list management with type filtering
//

import Foundation
import Combine
import CoreData

@MainActor
final class MemoListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var memos: [TweetMemo] = []
    @Published var selectedMemoType: MemoType?
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var memoCountsByType: [MemoType: Int] {
        var counts: [MemoType: Int] = [:]
        for type in MemoType.allCases {
            counts[type] = memoRepository.countByMemoType(type)
        }
        return counts
    }

    var filteredMemos: [TweetMemo] {
        guard let selectedType = selectedMemoType else {
            return memos
        }
        return memos.filter { $0.memoType == selectedType.rawValue }
    }

    var hasMemos: Bool {
        return !memos.isEmpty
    }

    // MARK: - Dependencies

    private let memoRepository: MemoRepositoryProtocol
    private var bookmark: ArticleBookmark?

    // MARK: - Initialization

    init(memoRepository: MemoRepositoryProtocol = MemoRepository()) {
        self.memoRepository = memoRepository
    }

    // MARK: - Configuration

    func configure(with bookmark: ArticleBookmark) {
        self.bookmark = bookmark
        loadMemos()
    }

    // MARK: - Load Methods

    func loadMemos() {
        guard let bookmark = bookmark else {
            loadAllMemos()
            return
        }
        loadMemosByBookmark(bookmark)
    }

    func loadAllMemos() {
        isLoading = true
        errorMessage = nil

        do {
            memos = try memoRepository.fetchAll()
        } catch {
            errorMessage = "メモの読み込みに失敗しました"
        }

        isLoading = false
    }

    func loadMemosByBookmark(_ bookmark: ArticleBookmark) {
        isLoading = true
        errorMessage = nil

        do {
            memos = try memoRepository.fetchByBookmark(bookmark)
        } catch {
            errorMessage = "メモの読み込みに失敗しました"
        }

        isLoading = false
    }

    func loadMemosByType(_ memoType: MemoType) {
        isLoading = true
        errorMessage = nil

        do {
            if let bookmark = bookmark {
                memos = try memoRepository.fetchByBookmarkAndType(bookmark, memoType: memoType)
            } else {
                memos = try memoRepository.fetchByMemoType(memoType)
            }
            selectedMemoType = memoType
        } catch {
            errorMessage = "メモの読み込みに失敗しました"
        }

        isLoading = false
    }

    // MARK: - Filter Methods

    func selectMemoType(_ memoType: MemoType?) {
        selectedMemoType = memoType
        if let type = memoType {
            loadMemosByType(type)
        } else {
            loadMemos()
        }
    }

    func clearFilter() {
        selectedMemoType = nil
        loadMemos()
    }

    // MARK: - CRUD Methods

    func deleteMemo(_ memo: TweetMemo) {
        do {
            try memoRepository.delete(memo)
            loadMemos()
        } catch {
            errorMessage = "メモの削除に失敗しました"
        }
    }

    func deleteMemos(at offsets: IndexSet) {
        let memosToDelete = offsets.map { filteredMemos[$0] }
        for memo in memosToDelete {
            do {
                try memoRepository.delete(memo)
            } catch {
                errorMessage = "メモの削除に失敗しました"
            }
        }
        loadMemos()
    }

    func updateMemoContent(_ memo: TweetMemo, content: String) {
        do {
            try memoRepository.updateContent(memo, content: content)
            loadMemos()
        } catch {
            errorMessage = "メモの更新に失敗しました"
        }
    }

    func updateMemoType(_ memo: TweetMemo, memoType: MemoType) {
        do {
            try memoRepository.updateMemoType(memo, memoType: memoType)
            loadMemos()
        } catch {
            errorMessage = "メモ種類の更新に失敗しました"
        }
    }

    // MARK: - Count Methods

    func memoCount(for memoType: MemoType) -> Int {
        if let bookmark = bookmark {
            return memos.filter {
                $0.bookmark == bookmark && $0.memoType == memoType.rawValue
            }.count
        }
        return memoRepository.countByMemoType(memoType)
    }

    func totalMemoCount() -> Int {
        return memos.count
    }

    // MARK: - Grouping

    func memosByType() -> [MemoType: [TweetMemo]] {
        var grouped: [MemoType: [TweetMemo]] = [:]
        for type in MemoType.allCases {
            grouped[type] = memos.filter { $0.memoType == type.rawValue }
        }
        return grouped
    }

    func availableMemoTypes() -> [MemoType] {
        let grouped = memosByType()
        return MemoType.allCases.filter { (grouped[$0]?.count ?? 0) > 0 }
    }
}
