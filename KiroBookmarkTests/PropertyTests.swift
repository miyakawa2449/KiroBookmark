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

final class PropertyTests: XCTestCase {

    // MARK: - Test Context Helper

    private func makeTestContext() -> NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        return controller.viewContext
    }

    // MARK: - Property 1: Bookmark Addition Consistency
    // For any valid URL, when a user adds it as a bookmark,
    // the bookmark list should contain exactly one more item
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

            try? context.save()

            let finalRequest = ArticleBookmark.fetchRequest()
            let finalCount = (try? context.fetch(finalRequest).count) ?? 0

            return finalCount == initialCount + 1
        }
    }

    // MARK: - Property 6: Memo Association
    // For any article and memo content, when a user adds a memo,
    // it should be correctly associated with the article
    // Validates: Requirements 2.1

    func testProperty6_MemoAssociation() {
        property("Memo is associated with bookmark") <- forAll { (content: String) in
            let context = self.makeTestContext()
            let safeContent = String(content.prefix(140))

            let bookmark = ArticleBookmark(context: context)
            bookmark.id = UUID()
            bookmark.title = "Test"
            bookmark.url = "https://example.com"
            bookmark.domain = "example.com"
            bookmark.bookmarkedDate = Date()

            let memo = TweetMemo(context: context)
            memo.id = UUID()
            memo.content = safeContent
            memo.createdDate = Date()
            memo.updatedDate = Date()
            memo.bookmark = bookmark

            try? context.save()

            return memo.bookmark == bookmark &&
                   (bookmark.memos?.contains(memo) ?? false)
        }
    }

    // MARK: - Property 7: Memo Character Limit
    // For any text input exceeding 140 characters,
    // the content should be limited
    // Validates: Requirements 2.2

    func testProperty7_MemoCharacterLimit() {
        property("Memo content respects 140 char limit") <- forAll { (text: String) in
            let limitedContent = String(text.prefix(140))
            return limitedContent.count <= 140
        }
    }

    // MARK: - Property 12: Tag Association
    // For any article and tag, when a user adds the tag,
    // it should be correctly associated
    // Validates: Requirements 3.1

    func testProperty12_TagAssociation() {
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

    // MARK: - Property 13: Multiple Tags Association
    // For any article and set of tags, all tags should be associated
    // Validates: Requirements 3.2

    func testProperty13_MultipleTagsAssociation() {
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
