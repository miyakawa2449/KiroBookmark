//
//  MemoRepository.swift
//  KiroBookmark
//
//  Repository for TweetMemo CRUD operations with memo type filtering
//

import Foundation
import CoreData

// MARK: - MemoRepositoryProtocol

protocol MemoRepositoryProtocol {
    // Create
    func create(
        content: String,
        memoType: MemoType,
        bookmark: ArticleBookmark
    ) throws -> TweetMemo

    func createQuoteMemo(
        content: String,
        selectedText: String,
        sourceURL: String,
        bookmark: ArticleBookmark
    ) throws -> TweetMemo

    // Read
    func fetchAll() throws -> [TweetMemo]
    func fetchById(_ id: UUID) throws -> TweetMemo?
    func fetchByBookmark(_ bookmark: ArticleBookmark) throws -> [TweetMemo]
    func fetchByMemoType(_ memoType: MemoType) throws -> [TweetMemo]
    func fetchByBookmarkAndType(_ bookmark: ArticleBookmark, memoType: MemoType) throws -> [TweetMemo]

    // Update
    func update(_ memo: TweetMemo) throws
    func updateContent(_ memo: TweetMemo, content: String) throws
    func updateMemoType(_ memo: TweetMemo, memoType: MemoType) throws

    // Delete
    func delete(_ memo: TweetMemo) throws
    func deleteById(_ id: UUID) throws
    func deleteAllByBookmark(_ bookmark: ArticleBookmark) throws

    // Utility
    func countByMemoType(_ memoType: MemoType) -> Int
    func countByBookmark(_ bookmark: ArticleBookmark) -> Int
    func validateContent(_ content: String) -> Bool
}

// MARK: - MemoRepository

final class MemoRepository: MemoRepositoryProtocol {

    // MARK: - Constants

    static let maxContentLength = 140

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - Create

    func create(
        content: String,
        memoType: MemoType,
        bookmark: ArticleBookmark
    ) throws -> TweetMemo {
        guard validateContent(content) else {
            throw MemoRepositoryError.contentTooLong
        }

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = content
        memo.memoType = memoType.rawValue
        memo.createdDate = Date()
        memo.updatedDate = Date()
        memo.isQuote = false
        memo.bookmark = bookmark

        try context.save()
        return memo
    }

    func createQuoteMemo(
        content: String,
        selectedText: String,
        sourceURL: String,
        bookmark: ArticleBookmark
    ) throws -> TweetMemo {
        guard validateContent(content) else {
            throw MemoRepositoryError.contentTooLong
        }

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = content
        memo.memoType = MemoType.quote.rawValue
        memo.createdDate = Date()
        memo.updatedDate = Date()
        memo.isQuote = true
        memo.selectedText = selectedText
        memo.sourceURL = sourceURL
        memo.bookmark = bookmark

        try context.save()
        return memo
    }

    // MARK: - Read

    func fetchAll() throws -> [TweetMemo] {
        let request = TweetMemo.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TweetMemo.createdDate, ascending: false)
        ]
        return try context.fetch(request)
    }

    func fetchById(_ id: UUID) throws -> TweetMemo? {
        let request = TweetMemo.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchByBookmark(_ bookmark: ArticleBookmark) throws -> [TweetMemo] {
        let request = TweetMemo.fetchRequest()
        request.predicate = NSPredicate(format: "bookmark == %@", bookmark)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TweetMemo.createdDate, ascending: true)
        ]
        return try context.fetch(request)
    }

    func fetchByMemoType(_ memoType: MemoType) throws -> [TweetMemo] {
        let request = TweetMemo.fetchRequest()
        request.predicate = NSPredicate(format: "memoType == %@", memoType.rawValue)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TweetMemo.createdDate, ascending: false)
        ]
        return try context.fetch(request)
    }

    func fetchByBookmarkAndType(
        _ bookmark: ArticleBookmark,
        memoType: MemoType
    ) throws -> [TweetMemo] {
        let request = TweetMemo.fetchRequest()
        request.predicate = NSPredicate(
            format: "bookmark == %@ AND memoType == %@",
            bookmark,
            memoType.rawValue
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TweetMemo.createdDate, ascending: true)
        ]
        return try context.fetch(request)
    }

    // MARK: - Update

    func update(_ memo: TweetMemo) throws {
        memo.updatedDate = Date()
        try context.save()
    }

    func updateContent(_ memo: TweetMemo, content: String) throws {
        guard validateContent(content) else {
            throw MemoRepositoryError.contentTooLong
        }

        memo.content = content
        memo.updatedDate = Date()
        try context.save()
    }

    func updateMemoType(_ memo: TweetMemo, memoType: MemoType) throws {
        memo.memoType = memoType.rawValue
        memo.updatedDate = Date()
        try context.save()
    }

    // MARK: - Delete

    func delete(_ memo: TweetMemo) throws {
        context.delete(memo)
        try context.save()
    }

    func deleteById(_ id: UUID) throws {
        guard let memo = try fetchById(id) else {
            throw MemoRepositoryError.memoNotFound
        }
        try delete(memo)
    }

    func deleteAllByBookmark(_ bookmark: ArticleBookmark) throws {
        let memos = try fetchByBookmark(bookmark)
        for memo in memos {
            context.delete(memo)
        }
        try context.save()
    }

    // MARK: - Utility

    func countByMemoType(_ memoType: MemoType) -> Int {
        let request = TweetMemo.fetchRequest()
        request.predicate = NSPredicate(format: "memoType == %@", memoType.rawValue)
        return (try? context.count(for: request)) ?? 0
    }

    func countByBookmark(_ bookmark: ArticleBookmark) -> Int {
        let request = TweetMemo.fetchRequest()
        request.predicate = NSPredicate(format: "bookmark == %@", bookmark)
        return (try? context.count(for: request)) ?? 0
    }

    func validateContent(_ content: String) -> Bool {
        return content.count <= Self.maxContentLength
    }
}

// MARK: - MemoRepositoryError

enum MemoRepositoryError: Error, LocalizedError, Equatable {
    case contentTooLong
    case contentEmpty
    case memoNotFound
    case invalidBookmark
    case saveFailed(String)

    static func == (lhs: MemoRepositoryError, rhs: MemoRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.contentTooLong, .contentTooLong),
             (.contentEmpty, .contentEmpty),
             (.memoNotFound, .memoNotFound),
             (.invalidBookmark, .invalidBookmark):
            return true
        case (.saveFailed(let lhsMsg), .saveFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .contentTooLong:
            return "メモは\(MemoRepository.maxContentLength)文字以内で入力してください"
        case .contentEmpty:
            return "メモ内容を入力してください"
        case .memoNotFound:
            return "メモが見つかりません"
        case .invalidBookmark:
            return "無効なブックマークです"
        case .saveFailed(let message):
            return "保存に失敗しました: \(message)"
        }
    }
}
