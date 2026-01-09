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
    func createFromRSS(url: String, title: String, domain: String, summary: String?, publishedDate: Date?) throws -> ArticleBookmark
    func fetchAll() throws -> [ArticleBookmark]
    func fetchAllSortedByActivity() throws -> [ArticleBookmark]
    func fetchById(_ id: UUID) throws -> ArticleBookmark?
    func fetchByURL(_ url: String) throws -> ArticleBookmark?
    func fetchFavorites() throws -> [ArticleBookmark]
    func fetchByReadingStatus(_ status: ReadingStatus) throws -> [ArticleBookmark]
    func fetchNewEntryArticles() throws -> [ArticleBookmark]
    func fetchUserBookmarks() throws -> [ArticleBookmark]
    func update(_ bookmark: ArticleBookmark) throws
    func delete(_ bookmark: ArticleBookmark) throws
    func deleteById(_ id: UUID) throws
    func toggleFavorite(_ bookmark: ArticleBookmark) throws
    func updateReadingStatus(_ bookmark: ArticleBookmark, status: ReadingStatus) throws
    func addToBookmark(_ bookmark: ArticleBookmark) throws
    func markAsViewed(_ bookmark: ArticleBookmark) throws
    func cleanupOldNewEntries() throws -> Int
    func exists(url: String) -> Bool

    // Domain organization methods
    func fetchByDomain(_ domain: String) throws -> [ArticleBookmark]
    func getDomainsWithCounts() throws -> [(domain: String, count: Int)]
}

// MARK: - BookmarkRepository

final class BookmarkRepository: BookmarkRepositoryProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    @MainActor
    convenience init() {
        self.init(context: PersistenceController.shared.viewContext)
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
        bookmark.isUserBookmarked = true
        bookmark.isFromRSS = false
        bookmark.viewCount = 0

        try context.save()
        return bookmark
    }

    func createFromRSS(url: String, title: String, domain: String, summary: String?, publishedDate: Date?) throws -> ArticleBookmark {
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.url = url
        bookmark.title = title
        bookmark.domain = domain
        bookmark.summary = summary
        bookmark.publishedDate = publishedDate
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        bookmark.isUserBookmarked = false
        bookmark.isFromRSS = true
        bookmark.rssAddedDate = Date()
        bookmark.viewCount = 0

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

    func fetchNewEntryArticles() throws -> [ArticleBookmark] {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "isUserBookmarked == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ArticleBookmark.publishedDate, ascending: false)]
        return try context.fetch(request)
    }

    func fetchUserBookmarks() throws -> [ArticleBookmark] {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(format: "isUserBookmarked == YES")
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

    func addToBookmark(_ bookmark: ArticleBookmark) throws {
        bookmark.isUserBookmarked = true
        bookmark.bookmarkedDate = Date()
        try context.save()
    }

    func markAsViewed(_ bookmark: ArticleBookmark) throws {
        bookmark.viewedDate = Date()
        bookmark.viewCount += 1
        bookmark.readingStatus = ReadingStatus.read.rawValue
        try context.save()
    }

    func cleanupOldNewEntries() throws -> Int {
        guard let twentyDaysAgo = Calendar.current.date(byAdding: .day, value: -20, to: Date()) else {
            return 0
        }

        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(
            format: "isUserBookmarked == NO AND rssAddedDate != nil AND rssAddedDate < %@",
            twentyDaysAgo as CVarArg
        )

        let oldArticles = try context.fetch(request)
        let count = oldArticles.count

        for article in oldArticles {
            context.delete(article)
        }

        if count > 0 {
            try context.save()
        }

        return count
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

    // MARK: - Domain Organization

    func fetchByDomain(_ domain: String) throws -> [ArticleBookmark] {
        let request = ArticleBookmark.fetchRequest()
        request.predicate = NSPredicate(
            format: "domain == %@ AND isUserBookmarked == YES",
            domain
        )
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ArticleBookmark.bookmarkedDate, ascending: false)
        ]
        return try context.fetch(request)
    }

    func getDomainsWithCounts() throws -> [(domain: String, count: Int)] {
        let bookmarks = try fetchUserBookmarks()
        var domainCounts: [String: Int] = [:]

        for bookmark in bookmarks {
            let domain = bookmark.domain ?? ""
            if !domain.isEmpty {
                domainCounts[domain, default: 0] += 1
            }
        }

        return domainCounts
            .map { (domain: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
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
