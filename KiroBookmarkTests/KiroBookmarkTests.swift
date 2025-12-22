//
//  KiroBookmarkTests.swift
//  KiroBookmarkTests
//
//  Created by Tsuyoshi Miyakawa on 2025/12/22.
//

import XCTest
import CoreData
@testable import KiroBookmark

final class KiroBookmarkTests: XCTestCase {

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

        try context.save()

        let request = ArticleBookmark.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Test Article")
    }

    func testTweetMemoCreation() throws {
        let context = makeTestContext()

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = "Test memo content"
        memo.createdDate = Date()
        memo.updatedDate = Date()

        try context.save()

        let request = TweetMemo.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Test memo content")
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

        let memo = TweetMemo(context: context)
        memo.id = UUID()
        memo.content = "Related memo"
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
}
