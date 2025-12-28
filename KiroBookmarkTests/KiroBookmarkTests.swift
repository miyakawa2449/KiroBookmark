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

        // Valid content (300 chars)
        let validContent = String(repeating: "a", count: 300)
        XCTAssertTrue(repository.validateContent(validContent))

        // Invalid content (301 chars)
        let invalidContent = String(repeating: "a", count: 301)
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

        // Task6 User Test Fix: 文字数制限を300文字に変更したため、301文字でテスト
        let longContent = String(repeating: "a", count: 301)

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

    // MARK: - TagRepository Tests

    @MainActor func testTagRepositoryCreate() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        let tag = try repository.create(name: "Swift")

        XCTAssertNotNil(tag.id)
        XCTAssertEqual(tag.name, "Swift")
        XCTAssertEqual(tag.usageCount, 0)
    }

    @MainActor func testTagRepositoryCreateIfNotExists() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        let tag1 = try repository.createIfNotExists(name: "Swift")
        let tag2 = try repository.createIfNotExists(name: "Swift")

        XCTAssertEqual(tag1.id, tag2.id)
        XCTAssertEqual(repository.count(), 1)
    }

    @MainActor func testTagRepositoryDuplicatePrevention() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        _ = try repository.create(name: "Swift")

        do {
            _ = try repository.create(name: "Swift")
            XCTFail("Should throw duplicate error")
        } catch let error as TagRepositoryError {
            XCTAssertEqual(error, .duplicateTag)
        }
    }

    @MainActor func testTagRepositoryCaseInsensitiveDuplicate() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        _ = try repository.create(name: "Swift")

        do {
            _ = try repository.create(name: "SWIFT")
            XCTFail("Should throw duplicate error for case-insensitive match")
        } catch let error as TagRepositoryError {
            XCTAssertEqual(error, .duplicateTag)
        }
    }

    @MainActor func testTagRepositoryFetchAllSortedByUsage() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)
        let bookmarkRepository = BookmarkRepository(context: context)

        let tag1 = try repository.create(name: "Low")
        let tag2 = try repository.create(name: "High")

        let bookmark1 = try bookmarkRepository.create(url: "https://a.com", title: "A", domain: "a.com")
        let bookmark2 = try bookmarkRepository.create(url: "https://b.com", title: "B", domain: "b.com")

        try repository.addToBookmark(tag2, bookmark: bookmark1)
        try repository.addToBookmark(tag2, bookmark: bookmark2)
        try repository.addToBookmark(tag1, bookmark: bookmark1)

        let sorted = try repository.fetchAllSortedByUsage()

        XCTAssertEqual(sorted[0].name, "High")
        XCTAssertEqual(sorted[1].name, "Low")
    }

    @MainActor func testTagRepositorySearch() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        _ = try repository.create(name: "Swift")
        _ = try repository.create(name: "SwiftUI")
        _ = try repository.create(name: "UIKit")

        let results = try repository.search(query: "Swift")

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { ($0.name ?? "").contains("Swift") })
    }

    @MainActor func testTagRepositoryUpdateName() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        let tag = try repository.create(name: "OldName")
        try repository.updateName(tag, name: "NewName")

        XCTAssertEqual(tag.name, "NewName")
    }

    @MainActor func testTagRepositoryIncrementDecrementUsage() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        let tag = try repository.create(name: "Test")
        XCTAssertEqual(tag.usageCount, 0)

        try repository.incrementUsageCount(tag)
        XCTAssertEqual(tag.usageCount, 1)

        try repository.incrementUsageCount(tag)
        XCTAssertEqual(tag.usageCount, 2)

        try repository.decrementUsageCount(tag)
        XCTAssertEqual(tag.usageCount, 1)

        try repository.decrementUsageCount(tag)
        XCTAssertEqual(tag.usageCount, 0)

        // Should not go below 0
        try repository.decrementUsageCount(tag)
        XCTAssertEqual(tag.usageCount, 0)
    }

    @MainActor func testTagRepositoryDelete() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        let tag = try repository.create(name: "ToDelete")
        XCTAssertEqual(repository.count(), 1)

        try repository.delete(tag)
        XCTAssertEqual(repository.count(), 0)
    }

    @MainActor func testTagRepositoryAddRemoveFromBookmark() async throws {
        let context = makeTestContext()
        let tagRepository = TagRepository(context: context)
        let bookmarkRepository = BookmarkRepository(context: context)

        let tag = try tagRepository.create(name: "Test")
        let bookmark = try bookmarkRepository.create(url: "https://example.com", title: "Test", domain: "example.com")

        try tagRepository.addToBookmark(tag, bookmark: bookmark)

        let bookmarkTags = bookmark.tags as? Set<Tag> ?? []
        XCTAssertTrue(bookmarkTags.contains(tag))
        XCTAssertEqual(tag.usageCount, 1)

        try tagRepository.removeFromBookmark(tag, bookmark: bookmark)

        let updatedTags = bookmark.tags as? Set<Tag> ?? []
        XCTAssertFalse(updatedTags.contains(tag))
        XCTAssertEqual(tag.usageCount, 0)
    }

    @MainActor func testTagRepositoryValidateName() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        XCTAssertTrue(repository.validateName("Valid"))
        XCTAssertTrue(repository.validateName("A"))
        XCTAssertFalse(repository.validateName(""))
        XCTAssertFalse(repository.validateName("   "))

        let longName = String(repeating: "a", count: 51)
        XCTAssertFalse(repository.validateName(longName))
    }

    @MainActor func testTagRepositoryExists() async throws {
        let context = makeTestContext()
        let repository = TagRepository(context: context)

        XCTAssertFalse(repository.exists(name: "Swift"))

        _ = try repository.create(name: "Swift")

        XCTAssertTrue(repository.exists(name: "Swift"))
        XCTAssertTrue(repository.exists(name: "swift"))
        XCTAssertFalse(repository.exists(name: "Java"))
    }

    // MARK: - ArticleWebViewModel Tests

    @MainActor func testArticleWebViewModelConfiguration() async {
        let viewModel = ArticleWebViewModel()
        let testURL = URL(string: "https://example.com/article")!

        viewModel.configure(url: testURL)

        XCTAssertEqual(viewModel.currentURL, testURL)
        XCTAssertFalse(viewModel.isBookmarked)
        XCTAssertNil(viewModel.selectedText)
    }

    @MainActor func testArticleWebViewModelTextSelection() async {
        let viewModel = ArticleWebViewModel()
        let testURL = URL(string: "https://example.com")!
        viewModel.configure(url: testURL)

        // Test selecting text
        viewModel.handleTextSelection("Selected text")
        XCTAssertEqual(viewModel.selectedText, "Selected text")

        // Test empty string clears selection
        viewModel.handleTextSelection("")
        XCTAssertNil(viewModel.selectedText)

        // Test whitespace-only clears selection
        viewModel.handleTextSelection("   ")
        XCTAssertNil(viewModel.selectedText)

        // Test nil clears selection
        viewModel.handleTextSelection("Some text")
        XCTAssertEqual(viewModel.selectedText, "Some text")
        viewModel.handleTextSelection(nil)
        XCTAssertNil(viewModel.selectedText)
    }

    @MainActor func testArticleWebViewModelLoadingState() async {
        let viewModel = ArticleWebViewModel()

        viewModel.updateLoadingState(true)
        XCTAssertTrue(viewModel.isLoading)

        viewModel.updateLoadingState(false)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor func testArticleWebViewModelNavigationState() async {
        let viewModel = ArticleWebViewModel()

        viewModel.updateNavigationState(canGoBack: true, canGoForward: false)
        XCTAssertTrue(viewModel.canGoBack)
        XCTAssertFalse(viewModel.canGoForward)

        viewModel.updateNavigationState(canGoBack: false, canGoForward: true)
        XCTAssertFalse(viewModel.canGoBack)
        XCTAssertTrue(viewModel.canGoForward)
    }

    @MainActor func testArticleWebViewModelError() async {
        let viewModel = ArticleWebViewModel()

        viewModel.updateLoadingState(true)
        XCTAssertTrue(viewModel.isLoading)

        viewModel.setError("Page failed to load")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Page failed to load")
    }

    @MainActor func testArticleWebViewModelScrollDetection() async {
        let viewModel = ArticleWebViewModel()
        let testURL = URL(string: "https://example.com")!
        viewModel.configure(url: testURL)

        // Start scrolling
        viewModel.handleScrollStart()
        XCTAssertTrue(viewModel.isScrolling)
        XCTAssertFalse(viewModel.showBookmarkButton)
    }

    @MainActor func testArticleWebViewModelBookmarkCheck() async throws {
        let context = makeTestContext()
        let bookmarkRepository = BookmarkRepository(context: context)

        let viewModel = ArticleWebViewModel(
            bookmarkRepository: bookmarkRepository,
            memoRepository: MemoRepository(context: context)
        )

        let testURL = URL(string: "https://example.com/article")!
        viewModel.configure(url: testURL)

        // Initially not bookmarked
        XCTAssertFalse(viewModel.isBookmarked)

        // Create a bookmark
        _ = try bookmarkRepository.create(
            url: "https://example.com/article",
            title: "Test",
            domain: "example.com"
        )

        // Check again
        viewModel.checkIfBookmarked()
        XCTAssertTrue(viewModel.isBookmarked)
    }

    @MainActor func testArticleWebViewModelRegisterBookmark() async throws {
        let context = makeTestContext()
        let bookmarkRepository = BookmarkRepository(context: context)

        let viewModel = ArticleWebViewModel(
            bookmarkRepository: bookmarkRepository,
            memoRepository: MemoRepository(context: context)
        )

        let testURL = URL(string: "https://example.com/new-article")!
        viewModel.configure(url: testURL)
        viewModel.updatePageTitle("New Article Title")

        // Register bookmark
        let bookmark = try viewModel.registerBookmark()

        XCTAssertNotNil(bookmark)
        XCTAssertEqual(bookmark?.title, "New Article Title")
        XCTAssertEqual(bookmark?.url, "https://example.com/new-article")
        XCTAssertTrue(viewModel.isBookmarked)
        XCTAssertFalse(viewModel.showBookmarkButton)

        // Should not create duplicate
        let duplicate = try viewModel.registerBookmark()
        XCTAssertNil(duplicate)
    }
}
