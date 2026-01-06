//
//  FavoriteBlogRepository.swift
//  KiroBookmark
//
//  Repository for FavoriteBlog CRUD operations
//

import Foundation
import CoreData

// MARK: - FavoriteBlogRepositoryProtocol

protocol FavoriteBlogRepositoryProtocol {
    func create(domain: String, name: String, rssURL: String?) throws -> FavoriteBlog
    func fetchAll() throws -> [FavoriteBlog]
    func fetchById(_ id: UUID) throws -> FavoriteBlog?
    func fetchByDomain(_ domain: String) throws -> FavoriteBlog?
    func update(_ blog: FavoriteBlog) throws
    func delete(_ blog: FavoriteBlog) throws
    func deleteByDomain(_ domain: String) throws
    func exists(domain: String) -> Bool
    func associateArticle(_ article: ArticleBookmark, with blog: FavoriteBlog) throws
    func getArticles(for blog: FavoriteBlog) -> [ArticleBookmark]

    // RSS-related methods
    func updateRSSURL(_ blog: FavoriteBlog, rssURL: String?) throws
    func fetchWithRSSURL() throws -> [FavoriteBlog]
    func clearRSSURL(_ blog: FavoriteBlog) throws

    // Domain organization methods
    func getOrCreate(domain: String) throws -> FavoriteBlog
    func updateName(_ blog: FavoriteBlog, name: String) throws
    func getDisplayName(for domain: String) -> String
}

// MARK: - FavoriteBlogRepository

final class FavoriteBlogRepository: FavoriteBlogRepositoryProtocol {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.context = context
    }

    // MARK: - Create

    func create(domain: String, name: String, rssURL: String? = nil) throws -> FavoriteBlog {
        let blog = FavoriteBlog(context: context)
        blog.id = UUID()
        blog.domain = domain
        blog.name = name.isEmpty ? domain : name
        blog.rssURL = rssURL
        blog.addedDate = Date()

        try context.save()
        return blog
    }

    // MARK: - Read

    func fetchAll() throws -> [FavoriteBlog] {
        let request = FavoriteBlog.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteBlog.addedDate, ascending: false)]
        return try context.fetch(request)
    }

    func fetchById(_ id: UUID) throws -> FavoriteBlog? {
        let request = FavoriteBlog.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func fetchByDomain(_ domain: String) throws -> FavoriteBlog? {
        let request = FavoriteBlog.fetchRequest()
        request.predicate = NSPredicate(format: "domain == %@", domain)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    // MARK: - Update

    func update(_ blog: FavoriteBlog) throws {
        try context.save()
    }

    // MARK: - Delete

    func delete(_ blog: FavoriteBlog) throws {
        context.delete(blog)
        try context.save()
    }

    func deleteByDomain(_ domain: String) throws {
        guard let blog = try fetchByDomain(domain) else { return }
        try delete(blog)
    }

    // MARK: - Utility

    func exists(domain: String) -> Bool {
        let request = FavoriteBlog.fetchRequest()
        request.predicate = NSPredicate(format: "domain == %@", domain)
        request.fetchLimit = 1
        return (try? context.count(for: request)) ?? 0 > 0
    }

    func associateArticle(_ article: ArticleBookmark, with blog: FavoriteBlog) throws {
        article.favoriteBlog = blog
        try context.save()
    }

    func getArticles(for blog: FavoriteBlog) -> [ArticleBookmark] {
        let articles = blog.articles as? Set<ArticleBookmark> ?? []
        return articles.sorted { ($0.publishedDate ?? $0.bookmarkedDate!) > ($1.publishedDate ?? $1.bookmarkedDate!) }
    }

    // MARK: - RSS Methods

    func updateRSSURL(_ blog: FavoriteBlog, rssURL: String?) throws {
        blog.rssURL = rssURL
        try context.save()
    }

    func fetchWithRSSURL() throws -> [FavoriteBlog] {
        let request = FavoriteBlog.fetchRequest()
        request.predicate = NSPredicate(format: "rssURL != nil AND rssURL != ''")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FavoriteBlog.addedDate, ascending: false)]
        return try context.fetch(request)
    }

    func clearRSSURL(_ blog: FavoriteBlog) throws {
        blog.rssURL = nil
        try context.save()
    }

    // MARK: - Domain Organization

    func getOrCreate(domain: String) throws -> FavoriteBlog {
        if let existing = try fetchByDomain(domain) {
            return existing
        }
        return try create(domain: domain, name: domain, rssURL: nil)
    }

    func updateName(_ blog: FavoriteBlog, name: String) throws {
        blog.name = name.isEmpty ? blog.domain : name
        try context.save()
    }

    func getDisplayName(for domain: String) -> String {
        guard let blog = try? fetchByDomain(domain) else {
            return domain
        }
        return blog.name ?? domain
    }
}

// MARK: - FavoriteBlogRepositoryError

enum FavoriteBlogRepositoryError: Error, LocalizedError {
    case duplicateBlog
    case blogNotFound
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .duplicateBlog:
            return "このブログは既にお気に入りに登録されています"
        case .blogNotFound:
            return "ブログが見つかりません"
        case .saveFailed(let error):
            return "保存に失敗しました: \(error.localizedDescription)"
        }
    }
}
