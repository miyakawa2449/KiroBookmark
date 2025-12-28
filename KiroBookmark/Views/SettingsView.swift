//
//  SettingsView.swift
//  KiroBookmark
//
//  Settings view for app configuration
//

import SwiftUI
import Combine

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                menuCustomizationSection
                displaySection
                dataSection
                aboutSection
            }
            .navigationTitle("設定")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    closeButton
                }
                #else
                ToolbarItem(placement: .confirmationAction) {
                    closeButton
                }
                #endif
            }
        }
    }

    // MARK: - Menu Customization Section

    private var menuCustomizationSection: some View {
        Section {
            ForEach(SideMenuItem.allCases, id: \.self) { item in
                menuItemRow(item)
            }
            .onMove { from, to in
                viewModel.moveMenuItem(from: from, to: to)
            }
        } header: {
            Text("サイドメニュー表示")
        } footer: {
            Text("表示するメニュー項目を選択できます")
        }
    }

    private func menuItemRow(_ item: SideMenuItem) -> some View {
        Toggle(isOn: Binding(
            get: { viewModel.isMenuItemVisible(item) },
            set: { viewModel.setMenuItemVisibility(item, isVisible: $0) }
        )) {
            HStack(spacing: 12) {
                Image(systemName: item.systemIcon)
                    .font(.system(size: 16))
                    .foregroundColor(item.color)
                    .frame(width: 24)
                Text(item.displayName)
            }
        }
    }

    // MARK: - Display Section

    private var displaySection: some View {
        Section {
            Picker("カード表示", selection: $viewModel.cardDisplayMode) {
                ForEach(CardDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }

            Picker("ソート順", selection: $viewModel.defaultSortOrder) {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Text(order.displayName).tag(order)
                }
            }
        } header: {
            Text("表示設定")
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        Section {
            NavigationLink {
                RSSFeedListView()
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.orange)
                    Text("フィード管理")
                }
            }

            NavigationLink {
                DataManagementView()
            } label: {
                HStack {
                    Image(systemName: "externaldrive")
                        .foregroundColor(.blue)
                    Text("データ管理")
                }
            }
        } header: {
            Text("データ")
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("バージョン")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("ビルド")
                Spacer()
                Text(viewModel.buildNumber)
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("アプリ情報")
        }
    }

    // MARK: - Toolbar Buttons

    private var closeButton: some View {
        Button("完了") {
            dismiss()
        }
    }
}

// MARK: - DataManagementView

struct DataManagementView: View {
    @State private var showingDeleteConfirmation = false
    @State private var bookmarkCount = 0
    @State private var memoCount = 0
    @State private var tagCount = 0

    var body: some View {
        List {
            Section {
                HStack {
                    Text("ブックマーク数")
                    Spacer()
                    Text("\(bookmarkCount)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("メモ数")
                    Spacer()
                    Text("\(memoCount)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("タグ数")
                    Spacer()
                    Text("\(tagCount)")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("統計")
            }

            Section {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("全データを削除")
                    }
                }
            } header: {
                Text("危険な操作")
            } footer: {
                Text("この操作は取り消せません")
            }
        }
        .navigationTitle("データ管理")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            loadCounts()
        }
        .alert("全データを削除", isPresented: $showingDeleteConfirmation) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("すべてのブックマーク、メモ、タグが削除されます。この操作は取り消せません。")
        }
    }

    private func loadCounts() {
        let bookmarkRepository = BookmarkRepository()
        let memoRepository = MemoRepository()
        let tagRepository = TagRepository()

        bookmarkCount = (try? bookmarkRepository.fetchAll().count) ?? 0
        memoCount = (try? memoRepository.fetchAll().count) ?? 0
        tagCount = (try? tagRepository.fetchAll().count) ?? 0
    }

    private func deleteAllData() {
        let bookmarkRepository = BookmarkRepository()
        let memoRepository = MemoRepository()
        let tagRepository = TagRepository()

        // Delete all memos first (due to relationships)
        if let memos = try? memoRepository.fetchAll() {
            for memo in memos {
                try? memoRepository.delete(memo)
            }
        }

        // Delete all bookmarks
        if let bookmarks = try? bookmarkRepository.fetchAll() {
            for bookmark in bookmarks {
                try? bookmarkRepository.delete(bookmark)
            }
        }

        // Delete all tags
        if let tags = try? tagRepository.fetchAll() {
            for tag in tags {
                try? tagRepository.delete(tag)
            }
        }

        loadCounts()
    }
}

// MARK: - SettingsViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var visibleMenuItems: Set<SideMenuItem>
    @Published var cardDisplayMode: CardDisplayMode
    @Published var defaultSortOrder: SortOrder

    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private enum Keys {
        static let visibleMenuItems = "settings.visibleMenuItems"
        static let cardDisplayMode = "settings.cardDisplayMode"
        static let defaultSortOrder = "settings.defaultSortOrder"
    }

    init() {
        // Load visible menu items
        if let savedItems = userDefaults.array(forKey: Keys.visibleMenuItems) as? [String] {
            visibleMenuItems = Set(savedItems.compactMap { SideMenuItem(rawValue: $0) })
        } else {
            visibleMenuItems = Set(SideMenuItem.allCases)
        }

        // Load card display mode
        if let savedMode = userDefaults.string(forKey: Keys.cardDisplayMode),
           let mode = CardDisplayMode(rawValue: savedMode) {
            cardDisplayMode = mode
        } else {
            cardDisplayMode = .standard
        }

        // Load sort order
        if let savedOrder = userDefaults.string(forKey: Keys.defaultSortOrder),
           let order = SortOrder(rawValue: savedOrder) {
            defaultSortOrder = order
        } else {
            defaultSortOrder = .latestActivity
        }
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    func isMenuItemVisible(_ item: SideMenuItem) -> Bool {
        visibleMenuItems.contains(item)
    }

    func setMenuItemVisibility(_ item: SideMenuItem, isVisible: Bool) {
        if isVisible {
            visibleMenuItems.insert(item)
        } else {
            visibleMenuItems.remove(item)
        }
        saveVisibleMenuItems()
    }

    func moveMenuItem(from source: IndexSet, to destination: Int) {
        // For MVP, just save the current state
        saveVisibleMenuItems()
    }

    private func saveVisibleMenuItems() {
        let items = visibleMenuItems.map { $0.rawValue }
        userDefaults.set(items, forKey: Keys.visibleMenuItems)
    }
}

// MARK: - Supporting Types

enum CardDisplayMode: String, CaseIterable {
    case standard
    case compact

    var displayName: String {
        switch self {
        case .standard:
            return "標準"
        case .compact:
            return "コンパクト"
        }
    }
}

enum SortOrder: String, CaseIterable {
    case latestActivity
    case bookmarkedDate
    case title

    var displayName: String {
        switch self {
        case .latestActivity:
            return "最新アクティビティ順"
        case .bookmarkedDate:
            return "ブックマーク日順"
        case .title:
            return "タイトル順"
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
