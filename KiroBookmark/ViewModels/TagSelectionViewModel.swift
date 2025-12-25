//
//  TagSelectionViewModel.swift
//  KiroBookmark
//
//  ViewModel for tag selection with search and create functionality
//

import Foundation
import Combine
import CoreData

@MainActor
final class TagSelectionViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var allTags: [Tag] = []
    @Published var selectedTags: Set<UUID> = []
    @Published var searchQuery = ""
    @Published var newTagName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var filteredTags: [Tag] {
        if searchQuery.isEmpty {
            return allTags
        }
        return allTags.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var frequentTags: [Tag] {
        return Array(allTags.prefix(5))
    }

    var canCreateNewTag: Bool {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        return tagRepository.validateName(trimmed) && !tagRepository.exists(name: trimmed)
    }

    var selectedTagObjects: [Tag] {
        return allTags.filter { selectedTags.contains($0.id ?? UUID()) }
    }

    // MARK: - Dependencies

    private let tagRepository: TagRepositoryProtocol
    private var bookmark: ArticleBookmark?

    // MARK: - Initialization

    init(tagRepository: TagRepositoryProtocol = TagRepository()) {
        self.tagRepository = tagRepository
    }

    // MARK: - Configuration

    func configure(bookmark: ArticleBookmark) {
        self.bookmark = bookmark
        loadTags()
        loadSelectedTags(for: bookmark)
    }

    // MARK: - Load Methods

    func loadTags() {
        isLoading = true
        errorMessage = nil

        do {
            allTags = try tagRepository.fetchAllSortedByUsage()
        } catch {
            errorMessage = "タグの読み込みに失敗しました"
        }

        isLoading = false
    }

    private func loadSelectedTags(for bookmark: ArticleBookmark) {
        guard let tags = bookmark.tags as? Set<Tag> else {
            selectedTags = []
            return
        }

        selectedTags = Set(tags.compactMap { $0.id })
    }

    // MARK: - Selection Methods

    func isSelected(_ tag: Tag) -> Bool {
        guard let id = tag.id else { return false }
        return selectedTags.contains(id)
    }

    func toggleSelection(_ tag: Tag) {
        guard let id = tag.id else { return }

        if selectedTags.contains(id) {
            selectedTags.remove(id)
        } else {
            selectedTags.insert(id)
        }
    }

    func selectTag(_ tag: Tag) {
        guard let id = tag.id else { return }
        selectedTags.insert(id)
    }

    func deselectTag(_ tag: Tag) {
        guard let id = tag.id else { return }
        selectedTags.remove(id)
    }

    func clearSelection() {
        selectedTags.removeAll()
    }

    // MARK: - Create Methods

    func createAndSelectTag() {
        guard canCreateNewTag else { return }

        do {
            let tag = try tagRepository.create(name: newTagName)
            loadTags()
            if let id = tag.id {
                selectedTags.insert(id)
            }
            newTagName = ""
        } catch let error as TagRepositoryError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "タグの作成に失敗しました"
        }
    }

    func createTagIfNeeded(name: String) -> Tag? {
        do {
            let tag = try tagRepository.createIfNotExists(name: name)
            loadTags()
            return tag
        } catch {
            errorMessage = "タグの作成に失敗しました"
            return nil
        }
    }

    // MARK: - Save Methods

    func saveSelectionToBookmark() {
        guard let bookmark = bookmark else {
            errorMessage = "ブックマークが指定されていません"
            return
        }

        do {
            // Get current tags
            let currentTags = (bookmark.tags as? Set<Tag>) ?? []
            let currentTagIds = Set(currentTags.compactMap { $0.id })

            // Tags to add
            let tagsToAdd = selectedTags.subtracting(currentTagIds)
            for tagId in tagsToAdd {
                if let tag = try tagRepository.fetchById(tagId) {
                    try tagRepository.addToBookmark(tag, bookmark: bookmark)
                }
            }

            // Tags to remove
            let tagsToRemove = currentTagIds.subtracting(selectedTags)
            for tagId in tagsToRemove {
                if let tag = try tagRepository.fetchById(tagId) {
                    try tagRepository.removeFromBookmark(tag, bookmark: bookmark)
                }
            }

            loadTags()
        } catch {
            errorMessage = "タグの保存に失敗しました"
        }
    }

    // MARK: - Search Methods

    func search(_ query: String) {
        searchQuery = query
    }

    func clearSearch() {
        searchQuery = ""
    }
}
