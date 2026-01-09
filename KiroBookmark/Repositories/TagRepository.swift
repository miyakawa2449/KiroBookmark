//
//  TagRepository.swift
//  KiroBookmark
//
//  Repository for Tag CRUD operations with usage frequency tracking
//

import Foundation
import CoreData

// MARK: - TagRepositoryProtocol

protocol TagRepositoryProtocol {
    // Create
    func create(name: String) throws -> Tag
    func create(name: String, color: String?) throws -> Tag
    func createIfNotExists(name: String) throws -> Tag

    // Read
    func fetchAll() throws -> [Tag]
    func fetchAllSortedByUsage() throws -> [Tag]
    func fetchById(_ id: UUID) throws -> Tag?
    func fetchByName(_ name: String) throws -> Tag?
    func fetchByBookmark(_ bookmark: ArticleBookmark) throws -> [Tag]
    func search(query: String) throws -> [Tag]

    // Update
    func update(_ tag: Tag) throws
    func updateName(_ tag: Tag, name: String) throws
    func updateColor(_ tag: Tag, color: String?) throws
    func incrementUsageCount(_ tag: Tag) throws
    func decrementUsageCount(_ tag: Tag) throws

    // Delete
    func delete(_ tag: Tag) throws
    func deleteById(_ id: UUID) throws

    // Association
    func addToBookmark(_ tag: Tag, bookmark: ArticleBookmark) throws
    func removeFromBookmark(_ tag: Tag, bookmark: ArticleBookmark) throws

    // Utility
    func exists(name: String) -> Bool
    func count() -> Int
    func validateName(_ name: String) -> Bool
}

// MARK: - TagRepository

final class TagRepository: TagRepositoryProtocol {

    // MARK: - Constants

    static let maxNameLength = 50
    static let minNameLength = 1

    // MARK: - Properties

    private let context: NSManagedObjectContext

    // MARK: - Initialization

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    @MainActor
    convenience init() {
        self.init(context: PersistenceController.shared.viewContext)
    }

    // MARK: - Create

    func create(name: String) throws -> Tag {
        return try create(name: name, color: nil)
    }

    func create(name: String, color: String?) throws -> Tag {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard validateName(trimmedName) else {
            throw TagRepositoryError.invalidName
        }

        if exists(name: trimmedName) {
            throw TagRepositoryError.duplicateTag
        }

        let tag = Tag(context: context)
        tag.id = UUID()
        tag.name = trimmedName
        tag.usageCount = 0
        tag.color = color

        try context.save()
        return tag
    }

    func createIfNotExists(name: String) throws -> Tag {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existingTag = try fetchByName(trimmedName) {
            return existingTag
        }

        return try create(name: trimmedName)
    }

    // MARK: - Read

    func fetchAll() throws -> [Tag] {
        let request = Tag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        return try context.fetch(request)
    }

    func fetchAllSortedByUsage() throws -> [Tag] {
        let request = Tag.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        return try context.fetch(request)
    }

    func fetchById(_ id: UUID) throws -> Tag? {
        let request = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchByName(_ name: String) throws -> Tag? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", trimmedName)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchByBookmark(_ bookmark: ArticleBookmark) throws -> [Tag] {
        guard let tags = bookmark.tags as? Set<Tag> else {
            return []
        }
        return Array(tags).sorted { $0.name ?? "" < $1.name ?? "" }
    }

    func search(query: String) throws -> [Tag] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            return try fetchAllSortedByUsage()
        }

        let request = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", trimmedQuery)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Tag.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \Tag.name, ascending: true)
        ]
        return try context.fetch(request)
    }

    // MARK: - Update

    func update(_ tag: Tag) throws {
        try context.save()
    }

    func updateName(_ tag: Tag, name: String) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard validateName(trimmedName) else {
            throw TagRepositoryError.invalidName
        }

        // Check for duplicate (excluding current tag)
        if let existingTag = try fetchByName(trimmedName), existingTag.id != tag.id {
            throw TagRepositoryError.duplicateTag
        }

        tag.name = trimmedName
        try context.save()
    }

    func updateColor(_ tag: Tag, color: String?) throws {
        tag.color = color
        try context.save()
    }

    func incrementUsageCount(_ tag: Tag) throws {
        tag.usageCount += 1
        try context.save()
    }

    func decrementUsageCount(_ tag: Tag) throws {
        if tag.usageCount > 0 {
            tag.usageCount -= 1
        }
        try context.save()
    }

    // MARK: - Delete

    func delete(_ tag: Tag) throws {
        context.delete(tag)
        try context.save()
    }

    func deleteById(_ id: UUID) throws {
        guard let tag = try fetchById(id) else {
            throw TagRepositoryError.tagNotFound
        }
        try delete(tag)
    }

    // MARK: - Association

    func addToBookmark(_ tag: Tag, bookmark: ArticleBookmark) throws {
        bookmark.addToTags(tag)
        try incrementUsageCount(tag)
    }

    func removeFromBookmark(_ tag: Tag, bookmark: ArticleBookmark) throws {
        bookmark.removeFromTags(tag)
        try decrementUsageCount(tag)
    }

    // MARK: - Utility

    func exists(name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name ==[c] %@", trimmedName)
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }

    func count() -> Int {
        let request = Tag.fetchRequest()
        return (try? context.count(for: request)) ?? 0
    }

    func validateName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= Self.minNameLength && trimmed.count <= Self.maxNameLength
    }
}

// MARK: - TagRepositoryError

enum TagRepositoryError: Error, LocalizedError, Equatable {
    case invalidName
    case duplicateTag
    case tagNotFound
    case saveFailed(String)

    static func == (lhs: TagRepositoryError, rhs: TagRepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidName, .invalidName),
             (.duplicateTag, .duplicateTag),
             (.tagNotFound, .tagNotFound):
            return true
        case (.saveFailed(let lhsMsg), .saveFailed(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "タグ名は1〜\(TagRepository.maxNameLength)文字で入力してください"
        case .duplicateTag:
            return "同じ名前のタグが既に存在します"
        case .tagNotFound:
            return "タグが見つかりません"
        case .saveFailed(let message):
            return "保存に失敗しました: \(message)"
        }
    }
}
