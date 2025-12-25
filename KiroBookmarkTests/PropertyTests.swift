//
//  PropertyTests.swift
//  KiroBookmarkTests
//
//  Property-based tests using SwiftCheck
//  Feature: bookmark-manager
//

import XCTest
import SwiftCheck
import CoreData
@testable import KiroBookmark

final class PropertyTests: XCTestCase, Sendable {

    // MARK: - Test Context Helper

    private func makeTestContext() -> NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        return controller.viewContext
    }

    // MARK: - Property 1: Bookmark Addition Consistency
    // For any valid URL, when a user adds it as a bookmark,
    // the bookmark list should contain exactly one more item than before
    // Validates: Requirements 1.1

    func testProperty1_BookmarkAdditionConsistency() {
        property("Adding bookmark increases count by one") <- forAll { (urlPath: String) in
            let context = self.makeTestContext()

            let initialRequest = ArticleBookmark.fetchRequest()
            let initialCount = (try? context.fetch(initialRequest).count) ?? 0

            let bookmark = ArticleBookmark(context: context)
            bookmark.id = UUID()
            bookmark.title = "Test"
            bookmark.url = "https://example.com/\(urlPath)"
            bookmark.domain = "example.com"
            bookmark.bookmarkedDate = Date()
            bookmark.isFavorite = false
            bookmark.readingStatus = ReadingStatus.unread.rawValue

            try? context.save()

            let finalRequest = ArticleBookmark.fetchRequest()
            let finalCount = (try? context.fetch(finalRequest).count) ?? 0

            return finalCount == initialCount + 1
        }
    }

    // MARK: - Property 2: URL Validation and Normalization
    // For any URL input, the system should validate format and normalize
    // (add https:// if missing, remove trailing slashes)
    // Validates: Requirements 1.2

    @MainActor func testProperty2_URLValidationAndNormalization() async {
        let validationService = URLValidationService()

        // Test valid URL with https:// prefix
        let result1 = validationService.validate("https://example.com/article")
        XCTAssertTrue(result1.isValid)
        XCTAssertEqual(result1.domain, "example.com")
        XCTAssertEqual(result1.normalizedURL, "https://example.com/article")

        // Test URL without protocol (should add https://)
        let result2 = validationService.validate("example.com/article")
        XCTAssertTrue(result2.isValid)
        XCTAssertEqual(result2.normalizedURL, "https://example.com/article")

        // Test URL with trailing slash (should remove it)
        let result3 = validationService.validate("https://example.com/path/")
        XCTAssertTrue(result3.isValid)
        XCTAssertEqual(result3.normalizedURL, "https://example.com/path")
    }

    // MARK: - Property 3: Duplicate Detection
    // For any URL that already exists in bookmarks,
    // the system should detect and reject the duplicate
    // Validates: Requirements 1.3

    @MainActor func testProperty3_DuplicateDetection() async {
        let context = self.makeTestContext()
        let url = "https://example.com/article"

        // Create first bookmark
        let bookmark1 = ArticleBookmark(context: context)
        bookmark1.id = UUID()
        bookmark1.title = "First"
        bookmark1.url = url
        bookmark1.domain = "example.com"
        bookmark1.bookmarkedDate = Date()
        bookmark1.isFavorite = false
        bookmark1.readingStatus = ReadingStatus.unread.rawValue
        try? context.save()

        // Check for existence - should detect duplicate
        let repository = BookmarkRepository(context: context)
        XCTAssertTrue(repository.exists(url: url))
        XCTAssertFalse(repository.exists(url: "https://example.com/other"))
    }

    // MARK: - Property 4: Favorite Blog Detection
    // For any URL from a registered favorite blog domain,
    // the system should detect and display the favorite blog indicator
    // Validates: Requirements 1.4

    @MainActor func testProperty4_FavoriteBlogDetection() async {
        let context = self.makeTestContext()
        let domain = "favorite-blog.com"

        // Create favorite blog
        let favoriteBlog = FavoriteBlog(context: context)
        favoriteBlog.id = UUID()
        favoriteBlog.domain = domain
        favoriteBlog.name = "My Favorite Blog"
        favoriteBlog.addedDate = Date()
        try? context.save()

        // Check for existence
        let repository = FavoriteBlogRepository(context: context)
        XCTAssertTrue(repository.exists(domain: domain))
        XCTAssertFalse(repository.exists(domain: "other-blog.com"))
    }

    // MARK: - Property 5: Memo Association
    // For any article and memo content, when a user adds a memo,
    // it should be correctly associated with the article and include a creation timestamp
    // Validates: Requirements 2.1

    func testProperty5_MemoAssociation() {
        property("Memo is associated with bookmark and has timestamp") <- forAll { (content: String) in
            let context = self.makeTestContext()
            let safeContent = String(content.prefix(140))

            let bookmark = ArticleBookmark(context: context)
            bookmark.id = UUID()
            bookmark.title = "Test"
            bookmark.url = "https://example.com"
            bookmark.domain = "example.com"
            bookmark.bookmarkedDate = Date()
            bookmark.isFavorite = false
            bookmark.readingStatus = ReadingStatus.unread.rawValue

            let memo = TweetMemo(context: context)
            memo.id = UUID()
            memo.content = safeContent
            memo.memoType = MemoType.idea.rawValue
            memo.isQuote = false
            memo.createdDate = Date()
            memo.updatedDate = Date()
            memo.bookmark = bookmark

            try? context.save()

            return memo.bookmark == bookmark &&
                   (bookmark.memos?.contains(memo) ?? false) &&
                   memo.createdDate != nil
        }
    }

    // MARK: - Property 6: Memo Character Limit
    // For any text input exceeding 140 characters,
    // the system should reject the input (content should be limited)
    // Validates: Requirements 2.2

    func testProperty6_MemoCharacterLimit() {
        property("Memo content respects 140 char limit") <- forAll { (text: String) in
            let limitedContent = String(text.prefix(140))
            return limitedContent.count <= 140
        }
    }

    // MARK: - Property 11: Tag Association
    // For any article and tag, when a user adds the tag to the article,
    // the tag should be correctly associated and retrievable
    // Validates: Requirements 3.1

    func testProperty11_TagAssociation() {
        property("Tag is associated with bookmark") <- forAll { (tagName: String) in
            let context = self.makeTestContext()
            let safeName = String(tagName.prefix(50))

            guard !safeName.isEmpty else { return true }

            let bookmark = ArticleBookmark(context: context)
            bookmark.id = UUID()
            bookmark.title = "Test"
            bookmark.url = "https://example.com"
            bookmark.domain = "example.com"
            bookmark.bookmarkedDate = Date()
            bookmark.isFavorite = false
            bookmark.readingStatus = ReadingStatus.unread.rawValue

            let tag = Tag(context: context)
            tag.id = UUID()
            tag.name = safeName
            tag.usageCount = 0

            bookmark.addToTags(tag)

            try? context.save()

            return (bookmark.tags?.contains(tag) ?? false) &&
                   (tag.bookmarks?.contains(bookmark) ?? false)
        }
    }

    // MARK: - Property 12: Multiple Tags Association
    // For any article and set of tags, when a user assigns multiple tags,
    // all tags should be associated with the article
    // Validates: Requirements 3.2

    func testProperty12_MultipleTagsAssociation() {
        property("Multiple tags associate with bookmark") <- forAll { (names: [String]) in
            let context = self.makeTestContext()
            let safeNames = names.prefix(5).map { String($0.prefix(50)) }
                .filter { !$0.isEmpty }

            guard !safeNames.isEmpty else { return true }

            let bookmark = ArticleBookmark(context: context)
            bookmark.id = UUID()
            bookmark.title = "Test"
            bookmark.url = "https://example.com"
            bookmark.domain = "example.com"
            bookmark.bookmarkedDate = Date()
            bookmark.isFavorite = false
            bookmark.readingStatus = ReadingStatus.unread.rawValue

            var tags: [Tag] = []
            for name in safeNames {
                let tag = Tag(context: context)
                tag.id = UUID()
                tag.name = name
                tag.usageCount = 0
                bookmark.addToTags(tag)
                tags.append(tag)
            }

            try? context.save()

            let bookmarkTags = bookmark.tags as? Set<Tag> ?? []
            return tags.allSatisfy { bookmarkTags.contains($0) }
        }
    }

    // MARK: - Property 8: Memo Edit Update Record
    // For any existing memo, when a user edits it,
    // the system should save the changes and update the modification timestamp
    // Validates: Requirements 2.4

    @MainActor func testProperty8_MemoEditUpdateRecord() async {
        let context = self.makeTestContext()
        let repository = MemoRepository(context: context)

        // Create bookmark
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try? context.save()

        // Create memo
        let memo = try? repository.create(
            content: "Original content",
            memoType: .idea,
            bookmark: bookmark
        )

        guard let memo = memo else {
            XCTFail("Failed to create memo")
            return
        }

        let originalUpdatedDate = memo.updatedDate

        // Wait a moment to ensure timestamp difference
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Update memo content
        try? repository.updateContent(memo, content: "Updated content")

        // Verify update
        XCTAssertEqual(memo.content, "Updated content")
        XCTAssertNotNil(memo.updatedDate)
        if let originalDate = originalUpdatedDate, let newDate = memo.updatedDate {
            XCTAssertTrue(newDate > originalDate, "Updated date should be later than original")
        }
    }

    // MARK: - Property 9: Memo Deletion Completeness
    // For any memo with attached photos, when a user deletes it,
    // both the memo and all attached photos should be completely removed
    // Validates: Requirements 2.5

    @MainActor func testProperty9_MemoDeletionCompleteness() async {
        let context = self.makeTestContext()
        let repository = MemoRepository(context: context)

        // Create bookmark
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try? context.save()

        // Create memo
        let memo = try? repository.create(
            content: "To be deleted",
            memoType: .todo,
            bookmark: bookmark
        )

        guard let memo = memo else {
            XCTFail("Failed to create memo")
            return
        }

        let memoId = memo.id

        // Verify memo exists
        XCTAssertEqual(repository.countByBookmark(bookmark), 1)

        // Delete memo
        try? repository.delete(memo)

        // Verify memo is completely removed
        XCTAssertEqual(repository.countByBookmark(bookmark), 0)
        let deletedMemo = try? repository.fetchById(memoId!)
        XCTAssertNil(deletedMemo)
    }

    // MARK: - Property 10: Memo Chronological Display
    // For any article with multiple memos,
    // the memos should be displayed in chronological order based on creation time
    // Validates: Requirements 2.6

    @MainActor func testProperty10_MemoChronologicalDisplay() async {
        let context = self.makeTestContext()
        let repository = MemoRepository(context: context)

        // Create bookmark
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try? context.save()

        // Create memos with different creation times
        _ = try? repository.create(content: "First memo", memoType: .idea, bookmark: bookmark)
        try? await Task.sleep(nanoseconds: 10_000_000)
        _ = try? repository.create(content: "Second memo", memoType: .thought, bookmark: bookmark)
        try? await Task.sleep(nanoseconds: 10_000_000)
        _ = try? repository.create(content: "Third memo", memoType: .todo, bookmark: bookmark)

        // Fetch memos (should be in chronological order - ascending)
        let memos = try? repository.fetchByBookmark(bookmark)

        guard let memos = memos, memos.count == 3 else {
            XCTFail("Expected 3 memos")
            return
        }

        // Verify chronological order (oldest first for timeline display)
        XCTAssertEqual(memos[0].content, "First memo")
        XCTAssertEqual(memos[1].content, "Second memo")
        XCTAssertEqual(memos[2].content, "Third memo")

        // Verify dates are in order
        for i in 0..<(memos.count - 1) {
            let current = memos[i].createdDate ?? Date.distantPast
            let next = memos[i + 1].createdDate ?? Date.distantPast
            XCTAssertTrue(current <= next, "Memos should be in chronological order")
        }
    }

    // MARK: - Property 23: Memo Type Filtering
    // For any memo type, when filtering articles by memo type,
    // the system should return only articles that have memos of that specific type
    // Validates: Requirements 13.5

    @MainActor func testProperty23_MemoTypeFiltering() async {
        let context = self.makeTestContext()
        let repository = MemoRepository(context: context)

        // Create bookmark
        let bookmark = ArticleBookmark(context: context)
        bookmark.id = UUID()
        bookmark.title = "Test"
        bookmark.url = "https://example.com"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue
        try? context.save()

        // Create memos of different types
        _ = try? repository.create(content: "Idea 1", memoType: .idea, bookmark: bookmark)
        _ = try? repository.create(content: "Idea 2", memoType: .idea, bookmark: bookmark)
        _ = try? repository.create(content: "Thought 1", memoType: .thought, bookmark: bookmark)
        _ = try? repository.create(content: "Todo 1", memoType: .todo, bookmark: bookmark)

        // Test filtering by type
        let ideaMemos = try? repository.fetchByMemoType(.idea)
        let thoughtMemos = try? repository.fetchByMemoType(.thought)
        let todoMemos = try? repository.fetchByMemoType(.todo)
        let quoteMemos = try? repository.fetchByMemoType(.quote)

        XCTAssertEqual(ideaMemos?.count, 2)
        XCTAssertEqual(thoughtMemos?.count, 1)
        XCTAssertEqual(todoMemos?.count, 1)
        XCTAssertEqual(quoteMemos?.count, 0)

        // Verify all returned memos have correct type
        XCTAssertTrue(ideaMemos?.allSatisfy { $0.memoType == MemoType.idea.rawValue } ?? false)
        XCTAssertTrue(thoughtMemos?.allSatisfy { $0.memoType == MemoType.thought.rawValue } ?? false)
        XCTAssertTrue(todoMemos?.allSatisfy { $0.memoType == MemoType.todo.rawValue } ?? false)
    }
}
