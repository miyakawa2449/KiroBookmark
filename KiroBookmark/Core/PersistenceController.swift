//
//  PersistenceController.swift
//  KiroBookmark
//
//  Core Data stack for local persistence
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    // Preview instance for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        let bookmark = ArticleBookmark(context: viewContext)
        bookmark.id = UUID()
        bookmark.title = "Sample Article"
        bookmark.url = "https://example.com/article"
        bookmark.domain = "example.com"
        bookmark.bookmarkedDate = Date()
        bookmark.isFavorite = false
        bookmark.readingStatus = ReadingStatus.unread.rawValue

        let tag = Tag(context: viewContext)
        tag.id = UUID()
        tag.name = "Swift"
        tag.usageCount = 1

        bookmark.addToTags(tag)

        // Create sample favorite blog
        let favoriteBlog = FavoriteBlog(context: viewContext)
        favoriteBlog.id = UUID()
        favoriteBlog.domain = "example.com"
        favoriteBlog.name = "Example Blog"
        favoriteBlog.addedDate = Date()
        bookmark.favoriteBlog = favoriteBlog

        let memo = TweetMemo(context: viewContext)
        memo.id = UUID()
        memo.content = "This is a sample memo"
        memo.memoType = MemoType.idea.rawValue
        memo.isQuote = false
        memo.createdDate = Date()
        memo.updatedDate = Date()
        memo.bookmark = bookmark

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview data error: \(nsError), \(nsError.userInfo)")
        }

        return controller
    }()

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "KiroBookmark")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // TODO: Refactor later (Date: 2024-12-24)
                // Replace fatalError with proper error handling
                fatalError("Core Data store failed: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Convenience Methods

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
