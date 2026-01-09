//
//  BackgroundRefreshService.swift
//  KiroBookmark
//
//  Service for managing background RSS refresh tasks
//

import Foundation
import BackgroundTasks
import CoreData

// MARK: - BackgroundRefreshServiceProtocol

protocol BackgroundRefreshServiceProtocol {
    func registerBackgroundTask()
    func scheduleAppRefresh()
    func handleBackgroundRefresh() async
}

// MARK: - BackgroundRefreshService

final class BackgroundRefreshService: BackgroundRefreshServiceProtocol {

    // MARK: - Constants

    static let taskIdentifier = "com.kiro.bookmark.refresh"
    private static let minimumInterval: TimeInterval = 15 * 60 // 15 minutes

    // MARK: - Dependencies

    private let rssService: RSSServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private let favoriteBlogRepository: FavoriteBlogRepositoryProtocol
    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let userDefaults: UserDefaults

    // MARK: - Keys

    private enum Keys {
        static let lastRefreshDate = "background.lastRefreshDate"
        static let notificationEnabled = "notification.enabled"
    }

    // MARK: - Initialization

    init(
        rssService: RSSServiceProtocol,
        notificationService: NotificationServiceProtocol,
        favoriteBlogRepository: FavoriteBlogRepositoryProtocol,
        bookmarkRepository: BookmarkRepositoryProtocol,
        userDefaults: UserDefaults
    ) {
        self.rssService = rssService
        self.notificationService = notificationService
        self.favoriteBlogRepository = favoriteBlogRepository
        self.bookmarkRepository = bookmarkRepository
        self.userDefaults = userDefaults
    }
    
    @MainActor
    convenience init() {
        self.init(
            rssService: RSSService(),
            notificationService: NotificationService(),
            favoriteBlogRepository: FavoriteBlogRepository(),
            bookmarkRepository: BookmarkRepository(),
            userDefaults: .standard
        )
    }

    // MARK: - Task Registration

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.taskIdentifier,
            using: nil
        ) { [weak self] task in
            guard let task = task as? BGAppRefreshTask else { return }
            self?.handleAppRefreshTask(task)
        }
    }

    // MARK: - Schedule Refresh

    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Self.minimumInterval)

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background refresh: \(error)")
        }
    }

    // MARK: - Handle Background Refresh

    private func handleAppRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()

        // Create a task to perform the refresh
        let refreshTask = Task {
            await handleBackgroundRefresh()
        }

        // Set expiration handler
        task.expirationHandler = {
            refreshTask.cancel()
        }

        // Complete the task when refresh is done
        Task {
            await refreshTask.value
            task.setTaskCompleted(success: true)
        }
    }

    func handleBackgroundRefresh() async {
        guard isNotificationEnabled else { return }

        do {
            let blogs = try await fetchBlogsWithRSS()
            guard !blogs.isEmpty else { return }

            let newArticles = try await fetchNewArticles(from: blogs)

            if !newArticles.isEmpty {
                await saveNewArticles(newArticles)
                sendNotification(for: newArticles)
            }

            updateLastRefreshDate()
        } catch {
            print("Background refresh error: \(error)")
        }
    }

    // MARK: - Private Helpers

    private func fetchBlogsWithRSS() async throws -> [(domain: String, name: String, rssURL: URL)] {
        let blogs = try favoriteBlogRepository.fetchWithRSSURL()
        return blogs.compactMap { blog -> (String, String, URL)? in
            guard let domain = blog.domain,
                  let name = blog.name,
                  let rssURLString = blog.rssURL,
                  let rssURL = URL(string: rssURLString) else {
                return nil
            }
            return (domain, name, rssURL)
        }
    }

    private func fetchNewArticles(
        from blogs: [(domain: String, name: String, rssURL: URL)]
    ) async throws -> [RSSArticle] {
        let allArticles = try await rssService.refreshAllFeeds(blogs: blogs)

        // Filter to only new articles (not already in database)
        return allArticles.filter { article in
            !bookmarkRepository.exists(url: article.url.absoluteString)
        }
    }

    private func saveNewArticles(_ articles: [RSSArticle]) async {
        let context = await MainActor.run {
            PersistenceController.shared.newBackgroundContext()
        }

        await context.perform {
            let repository = BookmarkRepository(context: context)

            for article in articles {
                do {
                    _ = try repository.createFromRSS(
                        url: article.url.absoluteString,
                        title: article.title,
                        domain: article.blogDomain,
                        summary: article.summary,
                        publishedDate: article.publishedDate
                    )
                } catch {
                    continue
                }
            }
        }
    }

    private func sendNotification(for articles: [RSSArticle]) {
        // Group by blog name
        let grouped = Dictionary(grouping: articles) { $0.blogName }

        for (blogName, blogArticles) in grouped {
            notificationService.scheduleNewArticleNotification(
                count: blogArticles.count,
                blogName: blogName
            )
        }

        // Update badge with total count
        Task {
            await notificationService.updateBadgeCount(articles.count)
        }
    }

    private func updateLastRefreshDate() {
        userDefaults.set(Date(), forKey: Keys.lastRefreshDate)
    }

    private var isNotificationEnabled: Bool {
        userDefaults.bool(forKey: Keys.notificationEnabled)
    }
}
