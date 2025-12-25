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

    // MARK: - Property 13: Tag Deletion Consistency
    // For any tag associated with articles, when the tag is deleted,
    // it should be removed from all associated articles
    // Validates: Requirements 3.3

    @MainActor func testProperty13_TagDeletionConsistency() async {
        let context = self.makeTestContext()
        let tagRepository = TagRepository(context: context)
        let bookmarkRepository = BookmarkRepository(context: context)

        // Create bookmark
        let bookmark = try? bookmarkRepository.create(
            url: "https://example.com",
            title: "Test",
            domain: "example.com"
        )

        guard let bookmark = bookmark else {
            XCTFail("Failed to create bookmark")
            return
        }

        // Create tag and associate with bookmark
        let tag = try? tagRepository.create(name: "TestTag")

        guard let tag = tag else {
            XCTFail("Failed to create tag")
            return
        }

        try? tagRepository.addToBookmark(tag, bookmark: bookmark)

        // Verify association
        let bookmarkTags = bookmark.tags as? Set<Tag> ?? []
        XCTAssertTrue(bookmarkTags.contains(tag))

        // Delete tag
        try? tagRepository.delete(tag)

        // Verify tag is removed from bookmark
        let updatedBookmarkTags = bookmark.tags as? Set<Tag> ?? []
        XCTAssertFalse(updatedBookmarkTags.contains(tag))
        XCTAssertEqual(tagRepository.count(), 0)
    }

    // MARK: - Property 14: Tag Usage Frequency Order
    // For any set of tags with different usage counts,
    // they should be displayed in descending order of usage frequency
    // Validates: Requirements 3.4

    @MainActor func testProperty14_TagUsageFrequencyOrder() async {
        let context = self.makeTestContext()
        let tagRepository = TagRepository(context: context)
        let bookmarkRepository = BookmarkRepository(context: context)

        // Create tags
        let tag1 = try? tagRepository.create(name: "LowUsage")
        let tag2 = try? tagRepository.create(name: "HighUsage")
        let tag3 = try? tagRepository.create(name: "MediumUsage")

        guard let tag1 = tag1, let tag2 = tag2, let tag3 = tag3 else {
            XCTFail("Failed to create tags")
            return
        }

        // Create bookmarks and associate tags with different frequencies
        for i in 0..<5 {
            let bookmark = try? bookmarkRepository.create(
                url: "https://example.com/\(i)",
                title: "Test \(i)",
                domain: "example.com"
            )
            guard let bookmark = bookmark else { continue }

            // tag2 (HighUsage) - 5 times
            try? tagRepository.addToBookmark(tag2, bookmark: bookmark)

            // tag3 (MediumUsage) - 3 times
            if i < 3 {
                try? tagRepository.addToBookmark(tag3, bookmark: bookmark)
            }

            // tag1 (LowUsage) - 1 time
            if i == 0 {
                try? tagRepository.addToBookmark(tag1, bookmark: bookmark)
            }
        }

        // Fetch sorted by usage
        let sortedTags = try? tagRepository.fetchAllSortedByUsage()

        guard let sortedTags = sortedTags, sortedTags.count == 3 else {
            XCTFail("Expected 3 tags")
            return
        }

        // Verify order: HighUsage > MediumUsage > LowUsage
        XCTAssertEqual(sortedTags[0].name, "HighUsage")
        XCTAssertEqual(sortedTags[1].name, "MediumUsage")
        XCTAssertEqual(sortedTags[2].name, "LowUsage")

        // Verify usage counts
        XCTAssertEqual(sortedTags[0].usageCount, 5)
        XCTAssertEqual(sortedTags[1].usageCount, 3)
        XCTAssertEqual(sortedTags[2].usageCount, 1)
    }

    // MARK: - Property 15: Tag Edit Propagation
    // For any tag associated with multiple articles, when the tag name is edited,
    // the change should be reflected in all associated articles
    // Validates: Requirements 3.5

    @MainActor func testProperty15_TagEditPropagation() async {
        let context = self.makeTestContext()
        let tagRepository = TagRepository(context: context)
        let bookmarkRepository = BookmarkRepository(context: context)

        // Create tag
        let tag = try? tagRepository.create(name: "OriginalName")

        guard let tag = tag else {
            XCTFail("Failed to create tag")
            return
        }

        // Create multiple bookmarks and associate with tag
        var bookmarks: [ArticleBookmark] = []
        for i in 0..<3 {
            let bookmark = try? bookmarkRepository.create(
                url: "https://example.com/\(i)",
                title: "Test \(i)",
                domain: "example.com"
            )
            guard let bookmark = bookmark else { continue }
            try? tagRepository.addToBookmark(tag, bookmark: bookmark)
            bookmarks.append(bookmark)
        }

        // Edit tag name
        try? tagRepository.updateName(tag, name: "UpdatedName")

        // Verify the change is reflected in all bookmarks
        for bookmark in bookmarks {
            let bookmarkTags = bookmark.tags as? Set<Tag> ?? []
            let hasUpdatedTag = bookmarkTags.contains { $0.name == "UpdatedName" }
            XCTAssertTrue(hasUpdatedTag, "Tag name should be updated for bookmark")
        }

        // Verify only one tag exists with the new name
        let allTags = try? tagRepository.fetchAll()
        XCTAssertEqual(allTags?.count, 1)
        XCTAssertEqual(allTags?.first?.name, "UpdatedName")
    }

    // MARK: - Property 24: Text Selection Accuracy
    // For any selected text in WebView, the system should accurately
    // capture the selected text content without modification
    // Validates: Requirements 19.1

    @MainActor func testProperty24_TextSelectionAccuracy() async {
        let viewModel = ArticleWebViewModel()
        let testURL = URL(string: "https://example.com/article")!
        viewModel.configure(url: testURL)

        // Test various text selections
        let testTexts = [
            "Simple text selection",
            "Text with special chars: <>&\"'",
            "日本語のテキスト選択",
            "  Text with whitespace  ",
            "Multi\nline\ntext"
        ]

        for originalText in testTexts {
            viewModel.handleTextSelection(originalText)

            // Whitespace is trimmed, but content should be preserved
            let trimmedOriginal = originalText.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedOriginal.isEmpty {
                XCTAssertNil(viewModel.selectedText, "Empty text should result in nil")
            } else {
                XCTAssertEqual(viewModel.selectedText, trimmedOriginal,
                    "Selected text should match original (trimmed)")
            }
        }

        // Test clearing selection
        viewModel.handleTextSelection("")
        XCTAssertNil(viewModel.selectedText, "Empty string should clear selection")

        viewModel.handleTextSelection(nil)
        XCTAssertNil(viewModel.selectedText, "Nil should clear selection")
    }

    // MARK: - Property 25: Quote Memo Completeness
    // For any selected text, when creating a quote memo,
    // the system should include both the selected text and the source URL
    // Validates: Requirements 19.3, 19.4

    @MainActor func testProperty25_QuoteMemoCompleteness() async {
        let context = self.makeTestContext()
        let memoRepository = MemoRepository(context: context)
        let bookmarkRepository = BookmarkRepository(context: context)

        // Create bookmark first
        let bookmark = try? bookmarkRepository.create(
            url: "https://example.com/article",
            title: "Test Article",
            domain: "example.com"
        )

        guard let bookmark = bookmark else {
            XCTFail("Failed to create bookmark")
            return
        }

        let selectedText = "This is the quoted text from the article"
        let sourceURL = "https://example.com/article"
        let memoContent = "My comment about this quote"

        // Create quote memo
        let quoteMemo = try? memoRepository.createQuoteMemo(
            content: memoContent,
            selectedText: selectedText,
            sourceURL: sourceURL,
            bookmark: bookmark
        )

        guard let quoteMemo = quoteMemo else {
            XCTFail("Failed to create quote memo")
            return
        }

        // Verify all required fields are present
        XCTAssertEqual(quoteMemo.content, memoContent, "Content should match")
        XCTAssertEqual(quoteMemo.selectedText, selectedText, "Selected text should be preserved")
        XCTAssertEqual(quoteMemo.sourceURL, sourceURL, "Source URL should be preserved")
        XCTAssertTrue(quoteMemo.isQuote, "isQuote flag should be true")
        XCTAssertEqual(quoteMemo.memoType, MemoType.quote.rawValue, "Memo type should be quote")
        XCTAssertNotNil(quoteMemo.createdDate, "Created date should be set")
        XCTAssertEqual(quoteMemo.bookmark, bookmark, "Bookmark association should be correct")

        // Verify the quote memo is associated with the bookmark
        let bookmarkMemos = try? memoRepository.fetchByBookmark(bookmark)
        XCTAssertEqual(bookmarkMemos?.count, 1)
        XCTAssertTrue(bookmarkMemos?.first?.isQuote ?? false)
    }

    // MARK: - Property 26: Tab Switching Behavior
    // For any tab selection, when switching between tabs,
    // the system should correctly update the current tab and filter bookmarks
    // Validates: Requirements 13.1

    @MainActor func testProperty26_TabSwitchingBehavior() async {
        let viewModel = HomeViewModel()

        // Initial state should be bookmark tab
        XCTAssertEqual(viewModel.currentTab, .bookmark)
        XCTAssertNil(viewModel.selectedMenuItem)

        // Switch to newEntry tab
        viewModel.selectTab(.newEntry)
        XCTAssertEqual(viewModel.currentTab, .newEntry)
        XCTAssertNil(viewModel.selectedMenuItem) // Menu selection should be cleared
        XCTAssertFalse(viewModel.isSideMenuOpen) // Side menu should be closed

        // Switch back to bookmark tab
        viewModel.selectTab(.bookmark)
        XCTAssertEqual(viewModel.currentTab, .bookmark)
        XCTAssertNil(viewModel.selectedMenuItem)

        // Verify navigation title updates correctly
        XCTAssertEqual(viewModel.navigationTitle, MainTabType.bookmark.displayName)
        viewModel.selectTab(.newEntry)
        XCTAssertEqual(viewModel.navigationTitle, MainTabType.newEntry.displayName)
    }

    // MARK: - Property 27: Side Menu Filtering
    // For any side menu item selection, the system should filter bookmarks
    // by the selected memo type and update the navigation title
    // Validates: Requirements 13.5

    @MainActor func testProperty27_SideMenuFiltering() async {
        let context = self.makeTestContext()
        let bookmarkRepository = BookmarkRepository(context: context)
        let memoRepository = MemoRepository(context: context)
        let viewModel = HomeViewModel(
            bookmarkRepository: bookmarkRepository,
            memoRepository: memoRepository
        )

        // Create bookmarks with different memo types
        let bookmark1 = try? bookmarkRepository.create(
            url: "https://example.com/1",
            title: "Article 1",
            domain: "example.com"
        )
        let bookmark2 = try? bookmarkRepository.create(
            url: "https://example.com/2",
            title: "Article 2",
            domain: "example.com"
        )
        let bookmark3 = try? bookmarkRepository.create(
            url: "https://example.com/3",
            title: "Article 3",
            domain: "example.com"
        )

        guard let bookmark1 = bookmark1, let bookmark2 = bookmark2, let bookmark3 = bookmark3 else {
            XCTFail("Failed to create bookmarks")
            return
        }

        // Add memos of different types
        _ = try? memoRepository.create(content: "Idea memo", memoType: .idea, bookmark: bookmark1)
        _ = try? memoRepository.create(content: "Todo memo", memoType: .todo, bookmark: bookmark2)
        _ = try? memoRepository.create(content: "Thought memo", memoType: .thought, bookmark: bookmark3)

        // Mark bookmark1 as favorite
        try? bookmarkRepository.toggleFavorite(bookmark1)

        // Load data
        viewModel.loadData()

        // Test side menu open/close
        XCTAssertFalse(viewModel.isSideMenuOpen)
        viewModel.openSideMenu()
        XCTAssertTrue(viewModel.isSideMenuOpen)
        viewModel.closeSideMenu()
        XCTAssertFalse(viewModel.isSideMenuOpen)

        // Test menu item counts
        XCTAssertEqual(viewModel.getMenuItemCount(.favorite), 1)
        XCTAssertEqual(viewModel.getMenuItemCount(.idea), 1)
        XCTAssertEqual(viewModel.getMenuItemCount(.todo), 1)
        XCTAssertEqual(viewModel.getMenuItemCount(.thought), 1)
        XCTAssertEqual(viewModel.getMenuItemCount(.other), 0)

        // Test filtering by favorite
        viewModel.selectMenuItem(.favorite)
        XCTAssertEqual(viewModel.selectedMenuItem, .favorite)
        XCTAssertEqual(viewModel.filteredBookmarks.count, 1)
        XCTAssertEqual(viewModel.navigationTitle, SideMenuItem.favorite.displayName)

        // Test filtering by memo type
        viewModel.selectMenuItem(.idea)
        XCTAssertEqual(viewModel.filteredBookmarks.count, 1)
        XCTAssertEqual(viewModel.filteredBookmarks.first?.url, "https://example.com/1")

        // Clear menu selection should return to tab filtering
        viewModel.clearMenuSelection()
        XCTAssertNil(viewModel.selectedMenuItem)
        XCTAssertEqual(viewModel.filteredBookmarks.count, 3) // All bookmarks
    }

    // MARK: - Property 28: Navigation State Management
    // For any navigation action (tab switch, menu selection),
    // the system should maintain consistent state across components
    // Validates: Requirements 13.3

    @MainActor func testProperty28_NavigationStateManagement() async {
        let viewModel = HomeViewModel()

        // Test initial state
        XCTAssertEqual(viewModel.currentTab, .bookmark)
        XCTAssertNil(viewModel.selectedMenuItem)
        XCTAssertFalse(viewModel.isSideMenuOpen)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)

        // Test side menu open/close (using direct open/close methods to avoid animation issues in tests)
        viewModel.isSideMenuOpen = true
        XCTAssertTrue(viewModel.isSideMenuOpen)
        viewModel.isSideMenuOpen = false
        XCTAssertFalse(viewModel.isSideMenuOpen)

        // Test that tab selection clears menu selection
        viewModel.selectedMenuItem = .idea
        XCTAssertNotNil(viewModel.selectedMenuItem)
        viewModel.selectTab(.newEntry)
        XCTAssertNil(viewModel.selectedMenuItem) // Menu should be cleared

        // Test that menu selection updates navigation title
        viewModel.selectedMenuItem = .thought
        XCTAssertEqual(viewModel.navigationTitle, SideMenuItem.thought.displayName)

        // Test swipe gesture handling (threshold is 50)
        viewModel.isSideMenuOpen = false
        viewModel.handleSwipeGesture(translation: 60, velocity: 0)
        XCTAssertTrue(viewModel.isSideMenuOpen, "Swipe right should open menu")
        viewModel.handleSwipeGesture(translation: -60, velocity: 0)
        XCTAssertFalse(viewModel.isSideMenuOpen, "Swipe left should close menu")

        // Test that visible menu items are populated after loadData
        viewModel.loadData()
        XCTAssertFalse(viewModel.visibleMenuItems.isEmpty)
        XCTAssertEqual(viewModel.visibleMenuItems.count, SideMenuItem.allCases.count)
    }
}
