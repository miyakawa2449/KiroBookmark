//
//  TagListViewModel.swift
//  KiroBookmark
//
//  ViewModel for tag list management
//

import Foundation
import Combine
import CoreData

@MainActor
final class TagListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var tags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchQuery = ""

    // MARK: - Computed Properties

    var filteredTags: [Tag] {
        if searchQuery.isEmpty {
            return tags
        }
        return tags.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(searchQuery)
        }
    }

    var hasTags: Bool {
        return !tags.isEmpty
    }

    var tagCount: Int {
        return tags.count
    }

    // MARK: - Dependencies

    private let tagRepository: TagRepositoryProtocol

    // MARK: - Initialization

    init(tagRepository: TagRepositoryProtocol) {
        self.tagRepository = tagRepository
    }
    
    @MainActor
    convenience init() {
        self.init(tagRepository: TagRepository())
    }

    // MARK: - Load Methods

    func loadTags() {
        isLoading = true
        errorMessage = nil

        do {
            tags = try tagRepository.fetchAllSortedByUsage()
        } catch {
            errorMessage = "タグの読み込みに失敗しました"
        }

        isLoading = false
    }

    func loadTagsAlphabetically() {
        isLoading = true
        errorMessage = nil

        do {
            tags = try tagRepository.fetchAll()
        } catch {
            errorMessage = "タグの読み込みに失敗しました"
        }

        isLoading = false
    }

    func search(_ query: String) {
        searchQuery = query

        if query.isEmpty {
            loadTags()
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            tags = try tagRepository.search(query: query)
        } catch {
            errorMessage = "検索に失敗しました"
        }

        isLoading = false
    }

    // MARK: - CRUD Methods

    func createTag(name: String, color: String? = nil) -> Tag? {
        do {
            let tag = try tagRepository.create(name: name, color: color)
            loadTags()
            return tag
        } catch let error as TagRepositoryError {
            errorMessage = error.localizedDescription
            return nil
        } catch {
            errorMessage = "タグの作成に失敗しました"
            return nil
        }
    }

    func updateTagName(_ tag: Tag, name: String) {
        do {
            try tagRepository.updateName(tag, name: name)
            loadTags()
        } catch let error as TagRepositoryError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "タグ名の更新に失敗しました"
        }
    }

    func updateTagColor(_ tag: Tag, color: String?) {
        do {
            try tagRepository.updateColor(tag, color: color)
            loadTags()
        } catch {
            errorMessage = "タグ色の更新に失敗しました"
        }
    }

    func deleteTag(_ tag: Tag) {
        do {
            try tagRepository.delete(tag)
            loadTags()
        } catch {
            errorMessage = "タグの削除に失敗しました"
        }
    }

    func deleteTags(at offsets: IndexSet) {
        let tagsToDelete = offsets.map { filteredTags[$0] }
        for tag in tagsToDelete {
            do {
                try tagRepository.delete(tag)
            } catch {
                errorMessage = "タグの削除に失敗しました"
            }
        }
        loadTags()
    }

    // MARK: - Validation

    func isValidTagName(_ name: String) -> Bool {
        return tagRepository.validateName(name)
    }

    func tagExists(name: String) -> Bool {
        return tagRepository.exists(name: name)
    }
}
