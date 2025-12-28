//
//  BookmarkRepository.swift
//  KiroBookmark
//
//  Repository for ArticleBookmark CRUD operations
//

import Foundation
import CoreData

// MARK: - BookmarkRepositoryProtocol

protocol BookmarkRepositoryProtocol {
    func create(url: String, title: String, domain: String) throws -> ArticleBookmark
    func fetchAll() throws -> [ArticleBookmark]
    func fetchAllSortedByActivity() throws -> [ArticleBookmark]
    func fetchById(_ id: UUID) throws -> ArticleBookmark?
    func fetchByURL(_ url: String) throws -> ArticleBookmark?
    func fetchFavorites() throws -> [ArticleBookmark]
    func fetchByReadingStatus(_ status: ReadingStatus) throws -> [ArticleBookmark]
    func update(_ bookmark: ArticleBookmark) throws
    func delete(_ bookmark: ArticleBookmark) throws
    func deleteById(_ id: UUID) throws
    func toggleFavorite(_ bookmark: ArticleBookmark) throws
    func updateReadingStatus(_ bookmark: ArticleBookmark, status: ReadingStatus) throws
    func exists(url: String) -> Bool
}

// MARK: - BookmarkRepository

final class BookmarkRepository: BookmarkRepositoryProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - Create

    func create(url: String, title: String, domain: String) throws -> ArticleBookmark {
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.url = url
        bookmark.title = title
        bookmark.domain = domain
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue

        try context.save()
        return bookmark
    }

    // MARK: - Read

    func fetchAll() throws -> [ArticleBookmark] {
        let request = ArticleBookmark.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleBookmark.bookmarkedDate, ascending: false)]
        return try context.fetch(request)
    }

    func fetchAllSortedByActivity() throws -> [ArticleBookmark] {
        let bookmarks = try fetchAll()

        // Sort by latest activity (memo date or bookmark date)
        return bookmarks.sorted { b1, b2 in
            let date1 = getLatestActivityDate(for: b1)
            let date2 = getLatestActivityDate(for: b2)
            return date1 > date2
        }
    }

    private func getLatestActivityDate(for bookmark: ArticleBookmark) -> Date {
        var latestDate = bookmark.bookmarkedDate ?? Date.distantPast

        // Check memo dates
        if let memos = bookmark.memos as? Set<TweetMemo> {
            for memo in memos {
                if let memoDate = memo.updatedDate ?? memo.createdDate {
                    if memoDate > latestDate {
                        latestDate = memoDate
                    }
                }
            }
        }

        return latestDate
    }

    func fetchById(_ id: UUID) throws -> ArticleBookmark? {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchByURL(_ url: String) throws -> ArticleBookmark? {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", url)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchFavorites() throws -> [ArticleBookmark] {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "isFavorite == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleBookmark.bookmarkedDate, ascending: false)]
        return try context.fetch(request)
    }

    func fetchByReadingStatus(_ status: ReadingStatus) throws -> [ArticleBookmark] {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "readingStatus == %@", status.rawValue)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleBookmark.bookmarkedDate, ascending: false)]
        return try context.fetch(request)
    }

    // MARK: - Update

    func update(_ bookmark: ArticleBookmark) throws {
        try context.save()
    }

    func toggleFavorite(_ bookmark: ArticleBookmark) throws {
        bookmark.isFavorite.toggle()
        try context.save()
    }

    func updateReadingStatus(_ bookmark: ArticleBookmark, status: ReadingStatus) throws {
        bookmark.readingStatus = status.rawValue
        try context.save()
    }

    // MARK: - Delete

    func delete(_ bookmark: ArticleBookmark) throws {
        context.delete(bookmark)
        try context.save()
    }

    func deleteById(_ id: UUID) throws {
        guard let bookmark = try fetchById(id) else { return }
        try delete(bookmark)
    }

    // MARK: - Utility

    func exists(url: String) -> Bool {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "url == %@", url)
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }
}

// MARK: - BookmarkRepositoryError

enum BookmarkRepositoryError: Error, LocalizedError {
    case invalidURL
    case duplicateBookmark
    case bookmarkNotFound
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            // Task6 User Test Fix: より具体的なエラーメッセージ
            return "無効なURLです。https://で始まる正しいURLを入力してください"
        case .duplicateBookmark:
            return "このURLは既にブックマークされています"
        case .bookmarkNotFound:
            return "ブックマークが見つかりません"
        case .saveFailed(let error):
            return "保存に失敗しました: \(error.localizedDescription)"
        }
    }
}
