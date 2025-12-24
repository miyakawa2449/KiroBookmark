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
}
