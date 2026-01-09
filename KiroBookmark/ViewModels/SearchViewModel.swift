//
//  SearchViewModel.swift
//  KiroBookmark
//
//  ViewModel for unified search across bookmarks, memos, and tags
//

import Foundation
import CoreData
import Combine

// MARK: - Search Result Types

struct SearchResult: Identifiable {
    let id = UUID()
    let bookmark: ArticleBookmark
    let matchType: SearchMatchType
    let matchedText: String?
}

enum SearchMatchType {
    case title
    case url
    case domain
    case memoContent
    case tag

    var displayName: String {
        switch self {
        case .title: return "タイトル"
        case .url: return "URL"
        case .domain: return "ドメイン"
        case .memoContent: return "メモ"
        case .tag: return "タグ"
        }
    }

    var systemIcon: String {
        switch self {
        case .title: return "doc.text"
        case .url: return "link"
        case .domain: return "globe"
        case .memoContent: return "note.text"
        case .tag: return "tag"
        }
    }
}

// MARK: - SearchViewModel

@MainActor
final class SearchViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var searchText = ""
    @Published var results: [SearchResult] = []
    @Published var isSearching = false
    @Published var recentSearches: [String] = []

    // MARK: - Private Properties

    private let bookmarkRepository: BookmarkRepositoryProtocol
    private let context: NSManagedObjectContext
    private var searchTask: Task<Void, Never>?

    private static let maxRecentSearches = 10
    private static let recentSearchesKey = "recentSearches"

    // MARK: - Initialization

    init(
        bookmarkRepository: BookmarkRepositoryProtocol,
        context: NSManagedObjectContext
    ) {
        self.bookmarkRepository = bookmarkRepository
        self.context = context
        loadRecentSearches()
    }
    
    @MainActor
    convenience init() {
        self.init(
            bookmarkRepository: BookmarkRepository(),
            context: PersistenceController.shared.viewContext
        )
    }

    // MARK: - Search

    func search() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            results = []
            isSearching = false
            return
        }

        // Cancel previous search
        searchTask?.cancel()

        isSearching = true

        searchTask = Task {
            // Small delay for debouncing
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

            guard !Task.isCancelled else { return }

            let searchResults = performSearch(query: query)

            await MainActor.run {
                self.results = searchResults
                self.isSearching = false
            }
        }
    }

    func clearSearch() {
        searchText = ""
        results = []
        isSearching = false
        searchTask?.cancel()
    }

    func addToRecentSearches(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove if already exists
        recentSearches.removeAll { $0 == trimmed }

        // Add to front
        recentSearches.insert(trimmed, at: 0)

        // Limit count
        if recentSearches.count > Self.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Self.maxRecentSearches))
        }

        saveRecentSearches()
    }

    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }

    // MARK: - Private Methods

    private func performSearch(query: String) -> [SearchResult] {
        let lowercasedQuery = query.lowercased()
        var allResults: [SearchResult] = []
        var addedBookmarkIds = Set<UUID>()

        do {
            let bookmarks = try bookmarkRepository.fetchAll()

            for bookmark in bookmarks {
                guard let bookmarkId = bookmark.id else { continue }

                // Search title
                if let title = bookmark.title?.lowercased(), title.contains(lowercasedQuery) {
                    if !addedBookmarkIds.contains(bookmarkId) {
                        allResults.append(SearchResult(
                            bookmark: bookmark,
                            matchType: .title,
                            matchedText: bookmark.title
                        ))
                        addedBookmarkIds.insert(bookmarkId)
                    }
                }

                // Search URL
                if let url = bookmark.url?.lowercased(), url.contains(lowercasedQuery) {
                    if !addedBookmarkIds.contains(bookmarkId) {
                        allResults.append(SearchResult(
                            bookmark: bookmark,
                            matchType: .url,
                            matchedText: bookmark.url
                        ))
                        addedBookmarkIds.insert(bookmarkId)
                    }
                }

                // Search domain
                if let domain = bookmark.domain?.lowercased(), domain.contains(lowercasedQuery) {
                    if !addedBookmarkIds.contains(bookmarkId) {
                        allResults.append(SearchResult(
                            bookmark: bookmark,
                            matchType: .domain,
                            matchedText: bookmark.domain
                        ))
                        addedBookmarkIds.insert(bookmarkId)
                    }
                }

                // Search memos
                if let memos = bookmark.memos as? Set<TweetMemo> {
                    for memo in memos {
                        if let content = memo.content?.lowercased(), content.contains(lowercasedQuery) {
                            if !addedBookmarkIds.contains(bookmarkId) {
                                allResults.append(SearchResult(
                                    bookmark: bookmark,
                                    matchType: .memoContent,
                                    matchedText: memo.content
                                ))
                                addedBookmarkIds.insert(bookmarkId)
                            }
                            break
                        }
                    }
                }

                // Search tags
                if let tags = bookmark.tags as? Set<Tag> {
                    for tag in tags {
                        if let tagName = tag.name?.lowercased(), tagName.contains(lowercasedQuery) {
                            if !addedBookmarkIds.contains(bookmarkId) {
                                allResults.append(SearchResult(
                                    bookmark: bookmark,
                                    matchType: .tag,
                                    matchedText: tag.name
                                ))
                                addedBookmarkIds.insert(bookmarkId)
                            }
                            break
                        }
                    }
                }
            }
        } catch {
            print("Search error: \(error)")
        }

        // Sort by bookmark date (newest first)
        return allResults.sorted {
            ($0.bookmark.bookmarkedDate ?? Date.distantPast) > ($1.bookmark.bookmarkedDate ?? Date.distantPast)
        }
    }

    // MARK: - Persistence

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: Self.recentSearchesKey) ?? []
    }

    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: Self.recentSearchesKey)
    }
}
