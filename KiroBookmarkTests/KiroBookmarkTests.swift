//
//  KiroBookmarkTests.swift
//  KiroBookmarkTests
//
//  Created by Tsuyoshi Miyakawa on 2025/12/22.
//

import XCTest
import CoreData
@testable import KiroBookmark

final class KiroBookmarkTests: XCTestCase, Sendable {

    // MARK: - Test Context Helper

    private func makeTestContext() -> NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        return controller.viewContext
    }

    // MARK: - ArticleBookmark Tests

    func testArticleBookmarkCreation() throws {
        let context = makeTestContext()

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test Article"
        bookmark.url = "https://example.com/article"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue

        try context.save()

        let request = ArticleBookmark.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Article")
        XCTAssertEqual(results.first?.isFavorite, false)
        XCTAssertEqual(results.first?.readingStatus, "unread")
    }

    func testTweetMemoCreation() throws {
        let context = makeTestContext()

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = "Test memo content"
        memo.memoType = MemoType.idea.rawValue
        memo.isQuote = false
        memo.createdDate = Date()
        memo.updatedDate = Date()

        try context.save()

        let request = TweetMemo.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Test memo content")
        XCTAssertEqual(results.first?.memoType, "idea")
        XCTAssertEqual(results.first?.isQuote, false)
    }

    func testQuoteMemoCreation() throws {
        let context = makeTestContext()

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = "This is a quote memo"
        memo.memoType = MemoType.quote.rawValue
        memo.isQuote = true
        memo.selectedText = "Selected text from article"
        memo.sourceURL = "https://example.com/article"
        memo.selectionContext = "Context around the selection"
        memo.createdDate = Date()
        memo.updatedDate = Date()

        try context.save()

        let request = TweetMemo.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.isQuote, true)
        XCTAssertEqual(results.first?.selectedText, "Selected text from article")
        XCTAssertEqual(results.first?.sourceURL, "https://example.com/article")
    }

    func testTagCreation() throws {
        let context = makeTestContext()

        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = "Swift"
        tag.usageCount = 0

        try context.save()

        let request = Tag.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Swift")
    }

    func testBookmarkMemoRelationship() throws {
        let context = makeTestContext()

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Article with Memo"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = "Related memo"
        memo.memoType = MemoType.thought.rawValue
        memo.isQuote = false
        memo.createdDate = Date()
        memo.updatedDate = Date()
        memo.bookmark = bookmark

        try context.save()

        let memos = bookmark.memos as? Set<TweetMemo> ?? []
        XCTAssertEqual(memos.count, 1)
        XCTAssertTrue(memo.bookmark === bookmark)
    }

    func testBookmarkTagRelationship() throws {
        let context = makeTestContext()

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Tagged Article"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue

        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = "iOS"
        tag.usageCount = 1

        bookmark.addToTags(tag)

        try context.save()

        let tags = bookmark.tags as? Set<Tag> ?? []
        let bookmarks = tag.bookmarks as? Set<ArticleBookmark> ?? []
        XCTAssertEqual(tags.count, 1)
        XCTAssertEqual(bookmarks.count, 1)
    }

    func testBookmarkFavoriteToggle() throws {
        let context = makeTestContext()

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Favorite Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue

        try context.save()

        XCTAssertEqual(bookmark.isFavorite, false)

        bookmark.isFavorite = true
        try context.save()

        XCTAssertEqual(bookmark.isFavorite, true)
    }

    func testMemoTypeEnum() {
        XCTAssertEqual(MemoType.idea.displayName, "アイディア")
        XCTAssertEqual(MemoType.thought.displayName, "感想")
        XCTAssertEqual(MemoType.todo.displayName, "TODO")
        XCTAssertEqual(MemoType.quote.displayName, "引用")
        XCTAssertEqual(MemoType.other.displayName, "その他")
    }

    func testReadingStatusEnum() {
        XCTAssertEqual(ReadingStatus.unread.displayName, "未読")
        XCTAssertEqual(ReadingStatus.reading.displayName, "読みかけ")
        XCTAssertEqual(ReadingStatus.read.displayName, "既読")
        XCTAssertEqual(ReadingStatus.favorite.displayName, "お気に入り")
    }

    func testSideMenuItemAssociatedMemoType() {
        XCTAssertNil(SideMenuItem.favorite.associatedMemoType)
        XCTAssertEqual(SideMenuItem.idea.associatedMemoType, .idea)
        XCTAssertEqual(SideMenuItem.thought.associatedMemoType, .thought)
        XCTAssertEqual(SideMenuItem.todo.associatedMemoType, .todo)
        XCTAssertEqual(SideMenuItem.other.associatedMemoType, .other)
    }

    // MARK: - BookmarkRepository Tests

    @MainActor func testBookmarkRepositoryCreate() async throws {
        let context = makeTestContext()
        let repository = BookmarkRepository(context: context)

        let bookmark = try repository.create(
            url: "https://example.com/test",
            title: "Test Article",
            domain: "example.com"
        )

        XCTAssertNotNil(bookmark.id)
        XCTAssertEqual(bookmark.title, "Test Article")
        XCTAssertEqual(bookmark.url, "https://example.com/test")
        XCTAssertEqual(bookmark.domain, "example.com")
    }

    @MainActor func testBookmarkRepositoryFetchAll() async throws {
        let context = makeTestContext()
        let repository = BookmarkRepository(context: context)

        _ = try repository.create(url: "https://a.com", title: "A", domain: "a.com")
        _ = try repository.create(url: "https://b.com", title: "B", domain: "b.com")
        _ = try repository.create(url: "https://c.com", title: "C", domain: "c.com")

        let bookmarks = try repository.fetchAll()
        XCTAssertEqual(bookmarks.count, 3)
    }

    @MainActor func testBookmarkRepositoryExists() async throws {
        let context = makeTestContext()
        let repository = BookmarkRepository(context: context)

        _ = try repository.create(
            url: "https://existing.com/article",
            title: "Existing",
            domain: "existing.com"
        )

        XCTAssertTrue(repository.exists(url: "https://existing.com/article"))
        XCTAssertFalse(repository.exists(url: "https://new.com/article"))
    }

    @MainActor func testBookmarkRepositoryToggleFavorite() async throws {
        let context = makeTestContext()
        let repository = BookmarkRepository(context: context)

        let bookmark = try repository.create(
            url: "https://example.com",
            title: "Test",
            domain: "example.com"
        )

        XCTAssertFalse(bookmark.isFavorite)

        try repository.toggleFavorite(bookmark)
        XCTAssertTrue(bookmark.isFavorite)

        try repository.toggleFavorite(bookmark)
        XCTAssertFalse(bookmark.isFavorite)
    }

    @MainActor func testBookmarkRepositoryDelete() async throws {
        let context = makeTestContext()
        let repository = BookmarkRepository(context: context)

        let bookmark = try repository.create(
            url: "https://delete.com",
            title: "Delete Me",
            domain: "delete.com"
        )

        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(bookmark)
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    // MARK: - FavoriteBlogRepository Tests

    @MainActor func testFavoriteBlogRepositoryCreate() async throws {
        let context = makeTestContext()
        let repository = FavoriteBlogRepository(context: context)

        let blog = try repository.create(
            domain: "favorite.com",
            name: "My Favorite Blog",
            rssURL: "https://favorite.com/rss"
        )

        XCTAssertNotNil(blog.id)
        XCTAssertEqual(blog.domain, "favorite.com")
        XCTAssertEqual(blog.name, "My Favorite Blog")
        XCTAssertEqual(blog.rssURL, "https://favorite.com/rss")
    }

    @MainActor func testFavoriteBlogRepositoryExists() async throws {
        let context = makeTestContext()
        let repository = FavoriteBlogRepository(context: context)

        _ = try repository.create(
            domain: "registered.com",
            name: "Registered Blog",
            rssURL: nil
        )

        XCTAssertTrue(repository.exists(domain: "registered.com"))
        XCTAssertFalse(repository.exists(domain: "unregistered.com"))
    }

    @MainActor func testFavoriteBlogRepositoryFetchByDomain() async throws {
        let context = makeTestContext()
        let repository = FavoriteBlogRepository(context: context)

        _ = try repository.create(
            domain: "findme.com",
            name: "Find Me Blog",
            rssURL: nil
        )

        let found = try repository.fetchByDomain("findme.com")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.name, "Find Me Blog")

        let notFound = try repository.fetchByDomain("notexist.com")
        XCTAssertNil(notFound)
    }

    // MARK: - URLValidationService Tests

    @MainActor func testURLValidationServiceValidURL() async {
        let service = URLValidationService()

        let result = service.validate("https://example.com/article")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.domain, "example.com")
        XCTAssertEqual(result.normalizedURL, "https://example.com/article")
    }

    @MainActor func testURLValidationServiceAddProtocol() async {
        let service = URLValidationService()

        let result = service.validate("example.com/article")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedURL, "https://example.com/article")
    }

    @MainActor func testURLValidationServiceInvalidURL() async {
        let service = URLValidationService()

        let result1 = service.validate("")
        XCTAssertFalse(result1.isValid)
        XCTAssertNotNil(result1.errorMessage)

        let result2 = service.validate("not a url")
        XCTAssertFalse(result2.isValid)
    }

    @MainActor func testURLValidationServiceRemoveTrailingSlash() async {
        let service = URLValidationService()

        let result = service.validate("https://example.com/path/")
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.normalizedURL, "https://example.com/path")
    }

    // MARK: - MemoRepository Tests

    @MainActor func testMemoRepositoryCreate() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        // Create bookmark first
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test Article"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        let memo = try repository.create(
            content: "Test memo content",
            memoType: .idea,
            bookmark: bookmark
        )

        XCTAssertNotNil(memo.id)
        XCTAssertEqual(memo.content, "Test memo content")
        XCTAssertEqual(memo.memoType, MemoType.idea.rawValue)
        XCTAssertNotNil(memo.createdDate)
        XCTAssertNotNil(memo.updatedDate)
        XCTAssertEqual(memo.bookmark, bookmark)
    }

    @MainActor func testMemoRepositoryCreateQuoteMemo() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test Article"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        let memo = try repository.createQuoteMemo(
            content: "My comment on this quote",
            selectedText: "Important text from the article",
            sourceURL: "https://example.com/article",
            bookmark: bookmark
        )

        XCTAssertTrue(memo.isQuote)
        XCTAssertEqual(memo.memoType, MemoType.quote.rawValue)
        XCTAssertEqual(memo.selectedText, "Important text from the article")
        XCTAssertEqual(memo.sourceURL, "https://example.com/article")
    }

    @MainActor func testMemoRepositoryFetchByBookmark() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        _ = try repository.create(content: "Memo 1", memoType: .idea, bookmark: bookmark)
        _ = try repository.create(content: "Memo 2", memoType: .thought, bookmark: bookmark)
        _ = try repository.create(content: "Memo 3", memoType: .todo, bookmark: bookmark)

        let memos = try repository.fetchByBookmark(bookmark)
        XCTAssertEqual(memos.count, 3)
    }

    @MainActor func testMemoRepositoryFetchByMemoType() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        _ = try repository.create(content: "Idea 1", memoType: .idea, bookmark: bookmark)
        _ = try repository.create(content: "Idea 2", memoType: .idea, bookmark: bookmark)
        _ = try repository.create(content: "Thought", memoType: .thought, bookmark: bookmark)

        let ideaMemos = try repository.fetchByMemoType(.idea)
        XCTAssertEqual(ideaMemos.count, 2)
        XCTAssertTrue(ideaMemos.allSatisfy { $0.memoType == MemoType.idea.rawValue })
    }

    @MainActor func testMemoRepositoryUpdateContent() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        let memo = try repository.create(content: "Original", memoType: .idea, bookmark: bookmark)
        XCTAssertEqual(memo.content, "Original")

        try repository.updateContent(memo, content: "Updated")
        XCTAssertEqual(memo.content, "Updated")
    }

    @MainActor func testMemoRepositoryDelete() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        let memo = try repository.create(content: "To delete", memoType: .idea, bookmark: bookmark)
        XCTAssertEqual(try repository.fetchByBookmark(bookmark).count, 1)

        try repository.delete(memo)
        XCTAssertEqual(try repository.fetchByBookmark(bookmark).count, 0)
    }

    @MainActor func testMemoRepositoryContentValidation() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        // Valid content (140 chars)
        let validContent = String(repeating: "a", count: 140)
        XCTAssertTrue(repository.validateContent(validContent))

        // Invalid content (141 chars)
        let invalidContent = String(repeating: "a", count: 141)
        XCTAssertFalse(repository.validateContent(invalidContent))
    }

    @MainActor func testMemoRepositoryContentTooLongError() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        let longContent = String(repeating: "a", count: 150)

        do {
            _ = try repository.create(content: longContent, memoType: .idea, bookmark: bookmark)
            XCTFail("Should throw contentTooLong error")
        } catch let error as MemoRepositoryError {
            XCTAssertEqual(error, .contentTooLong)
        }
    }

    @MainActor func testMemoRepositoryCountByMemoType() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        _ = try repository.create(content: "Idea 1", memoType: .idea, bookmark: bookmark)
        _ = try repository.create(content: "Idea 2", memoType: .idea, bookmark: bookmark)
        _ = try repository.create(content: "Thought", memoType: .thought, bookmark: bookmark)

        XCTAssertEqual(repository.countByMemoType(.idea), 2)
        XCTAssertEqual(repository.countByMemoType(.thought), 1)
        XCTAssertEqual(repository.countByMemoType(.todo), 0)
    }

    @MainActor func testMemoRepositoryCountByBookmark() async throws {
        let context = makeTestContext()
        let repository = MemoRepository(context: context)

        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try context.save()

        XCTAssertEqual(repository.countByBookmark(bookmark), 0)

        _ = try repository.create(content: "Memo 1", memoType: .idea, bookmark: bookmark)
        _ = try repository.create(content: "Memo 2", memoType: .thought, bookmark: bookmark)

        XCTAssertEqual(repository.countByBookmark(bookmark), 2)
    }
}
