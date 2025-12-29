# New Entry / Bookmark タブ分離機能の実装

## 🎯 目的

New EntryタブとBookmarkタブを明確に分離し、RSS記事の自動管理とユーザーブックマークを区別する機能を実装します。

---

## 📋 実装概要

### 背景

現在、RSS記事とユーザーブックマークが同じテーブルで管理されており、区別がつきません。この実装により：

- **New Entryタブ**: RSSから自動追加された未ブックマーク記事を表示
- **Bookmarkタブ**: ユーザーが明示的にブックマークした記事を表示
- **自動削除**: 20日経過したNew Entry記事を自動削除
- **閲覧管理**: 記事閲覧時に自動的に既読マーク

### 主要な変更点

1. **データモデル拡張**: ArticleBookmarkに5つの新規フィールド追加
2. **BlogManager機能追加**: 5つの新規メソッド追加
3. **UI実装**: ブックマーク追加ボタン（New Entry一覧 + WebView）
4. **自動処理**: 閲覧時の既読マーク、20日経過記事の自動削除
5. **プロパティテスト**: 4つの新規プロパティテスト追加

---

## 🔧 実装内容

### ステップ1: データモデル拡張

**ファイル**: `KiroBookmark/Models/ArticleBookmark.swift` または Core Data モデル

#### 追加フィールド

```swift
@Model
class ArticleBookmark {
    // 既存フィールド
    @Attribute(.unique) var id: UUID
    var url: URL
    var title: String
    var summary: String?
    var content: String?
    var publishedDate: Date?
    var bookmarkedDate: Date
    var readingStatus: ReadingStatus
    var isFavorite: Bool
    var domain: String
    var thumbnailURL: URL?
    
    // ✨ 新規追加フィールド
    var isUserBookmarked: Bool  // ユーザーが明示的にブックマークしたか
    var isFromRSS: Bool          // RSSから自動追加されたか
    var viewedDate: Date?        // 最後に閲覧した日時
    var viewCount: Int           // 閲覧回数
    var rssAddedDate: Date?      // RSS追加日時（自動削除判定用）
    
    // リレーション
    @Relationship(deleteRule: .cascade) var memos: [TweetMemo]
    @Relationship var tags: [Tag]
    @Relationship var feed: RSSFeed?
    
    init(url: URL, title: String, isFromRSS: Bool = false) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.bookmarkedDate = Date()
        self.readingStatus = .unread
        self.isFavorite = false
        self.domain = url.host ?? ""
        self.memos = []
        self.tags = []
        
        // ✨ 新規フィールドの初期化
        self.isUserBookmarked = !isFromRSS
        self.isFromRSS = isFromRSS
        self.viewCount = 0
        self.rssAddedDate = isFromRSS ? Date() : nil
    }
}
```

#### マイグレーション対応

既存データに対して以下のデフォルト値を設定：

```swift
// 既存の全記事を「ユーザーブックマーク」として扱う
isUserBookmarked = true
isFromRSS = false
viewCount = 0
viewedDate = nil
rssAddedDate = nil
```

---

### ステップ2: BlogManager機能追加

**ファイル**: `KiroBookmark/Managers/BlogManager.swift` または `KiroBookmark/Repositories/BookmarkRepository.swift`

#### 新規メソッド

```swift
protocol BlogManagerProtocol {
    // 既存メソッド
    func addBookmark(url: URL) async throws -> ArticleBookmark
    func deleteBookmark(id: UUID) async throws
    func updateBookmark(_ bookmark: ArticleBookmark) async throws
    func getBookmarks(filter: BookmarkFilter?) async -> [ArticleBookmark]
    
    // ✨ 新規メソッド
    
    /// New Entry記事をブックマークに追加
    /// - Parameter articleId: 記事ID
    func addToBookmark(articleId: UUID) async throws
    
    /// New Entry記事一覧を取得（isUserBookmarked == false）
    /// - Returns: 未ブックマーク記事の配列
    func getNewEntryArticles() async -> [ArticleBookmark]
    
    /// ユーザーブックマーク一覧を取得（isUserBookmarked == true）
    /// - Returns: ブックマーク済み記事の配列
    func getUserBookmarks() async -> [ArticleBookmark]
    
    /// 記事を閲覧済みとしてマーク
    /// - Parameter articleId: 記事ID
    func markAsViewed(articleId: UUID) async throws
    
    /// 20日以上経過したNew Entry記事を削除
    func cleanupOldNewEntries() async throws
}
```

#### 実装例

```swift
class BlogManager: BlogManagerProtocol {
    private let context: NSManagedObjectContext
    
    // ✨ New Entry記事をブックマークに追加
    func addToBookmark(articleId: UUID) async throws {
        let fetchRequest = ArticleBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", articleId as CVarArg)
        
        guard let article = try context.fetch(fetchRequest).first else {
            throw BookmarkError.notFound
        }
        
        article.isUserBookmarked = true
        article.bookmarkedDate = Date()
        
        try context.save()
    }
    
    // ✨ New Entry記事一覧を取得
    func getNewEntryArticles() async -> [ArticleBookmark] {
        let fetchRequest = ArticleBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isUserBookmarked == NO")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "publishedDate", ascending: false)
        ]
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    // ✨ ユーザーブックマーク一覧を取得
    func getUserBookmarks() async -> [ArticleBookmark] {
        let fetchRequest = ArticleBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isUserBookmarked == YES")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "bookmarkedDate", ascending: false)
        ]
        
        return (try? context.fetch(fetchRequest)) ?? []
    }
    
    // ✨ 記事を閲覧済みとしてマーク
    func markAsViewed(articleId: UUID) async throws {
        let fetchRequest = ArticleBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", articleId as CVarArg)
        
        guard let article = try context.fetch(fetchRequest).first else {
            throw BookmarkError.notFound
        }
        
        article.viewedDate = Date()
        article.viewCount += 1
        article.readingStatus = .read
        
        try context.save()
    }
    
    // ✨ 20日以上経過したNew Entry記事を削除
    func cleanupOldNewEntries() async throws {
        let twentyDaysAgo = Calendar.current.date(byAdding: .day, value: -20, to: Date())!
        
        let fetchRequest = ArticleBookmark.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "isUserBookmarked == NO AND rssAddedDate < %@",
            twentyDaysAgo as CVarArg
        )
        
        let oldArticles = try context.fetch(fetchRequest)
        
        for article in oldArticles {
            context.delete(article)
        }
        
        if !oldArticles.isEmpty {
            try context.save()
            print("Deleted \(oldArticles.count) old New Entry articles")
        }
    }
}
```

---

### ステップ3: HomeView タブ実装

**ファイル**: `KiroBookmark/Views/HomeView.swift`

#### タブ切り替えロジック

```swift
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var selectedTab: MainTabType = .newEntry
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ✨ New Entryタブ
            NewEntryTabView()
                .tabItem {
                    Label("New Entry", systemImage: "newspaper")
                }
                .tag(MainTabType.newEntry)
            
            // ✨ Bookmarkタブ
            BookmarkTabView()
                .tabItem {
                    Label("Bookmark", systemImage: "bookmark")
                }
                .tag(MainTabType.bookmark)
        }
    }
}
```

---

### ステップ4: New Entry一覧にブックマーク追加ボタン

**ファイル**: `KiroBookmark/Views/NewEntryTabView.swift` または `KiroBookmark/Views/ArticleCardView.swift`

#### カード右上にボタン追加

```swift
struct ArticleCardView: View {
    let bookmark: ArticleBookmark
    let onCardTap: () -> Void
    let onAddBookmark: (() -> Void)?  // ✨ 新規追加
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // タイトル
                Text(bookmark.title ?? "無題")
                    .font(.headline)
                    .lineLimit(2)
                
                Spacer()
                
                // ✨ ブックマーク追加ボタン（New Entryのみ表示）
                if !bookmark.isUserBookmarked, let onAddBookmark = onAddBookmark {
                    Button {
                        onAddBookmark()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 既存のカードコンテンツ
            // ...
        }
        .padding()
        .background(Color.systemBackground)
        .cornerRadius(12)
        .onTapGesture {
            onCardTap()
        }
    }
}
```

#### NewEntryTabViewでの使用例

```swift
struct NewEntryTabView: View {
    @StateObject private var viewModel: NewEntryViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.newEntryArticles) { article in
                    ArticleCardView(
                        bookmark: article,
                        onCardTap: {
                            // ✨ 閲覧記録
                            Task {
                                await viewModel.markAsViewed(article.id)
                            }
                            // WebView表示
                            viewModel.selectedArticle = article
                        },
                        onAddBookmark: {
                            // ✨ ブックマーク追加
                            Task {
                                await viewModel.addToBookmark(article.id)
                            }
                        }
                    )
                }
            }
            .padding()
        }
        .navigationTitle("New Entry")
    }
}
```

---

### ステップ5: WebViewにブックマーク追加ボタン

**ファイル**: `KiroBookmark/Views/ArticleWebView.swift`

#### ツールバーにボタン追加

```swift
struct ArticleWebView: View {
    let bookmark: ArticleBookmark
    @StateObject private var viewModel: ArticleWebViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView
            WebView(url: bookmark.url)
            
            // ツールバー
            toolbarView
        }
        .navigationTitle(bookmark.title ?? "記事")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // ✨ 閲覧記録
            Task {
                await viewModel.markAsViewed(bookmark.id)
            }
        }
    }
    
    private var toolbarView: some View {
        HStack(spacing: 0) {
            // メモボタン
            ToolbarButton(
                icon: "square.and.pencil",
                label: "メモ",
                action: { viewModel.showMemoSheet = true }
            )
            
            Divider().frame(height: 24)
            
            // TODOボタン
            ToolbarButton(
                icon: "checkmark.circle",
                label: "TODO",
                action: { viewModel.addQuickTodo() }
            )
            
            Divider().frame(height: 24)
            
            // ✨ ブックマークボタン（New Entryのみ表示）
            if !bookmark.isUserBookmarked {
                ToolbarButton(
                    icon: "bookmark",
                    label: "保存",
                    action: { 
                        Task {
                            await viewModel.addToBookmark(bookmark.id)
                        }
                    }
                )
                
                Divider().frame(height: 24)
            }
            
            // お気に入りボタン
            ToolbarButton(
                icon: viewModel.isFavorite ? "heart.fill" : "heart",
                label: "お気に入り",
                isActive: viewModel.isFavorite,
                action: { viewModel.toggleFavorite() }
            )
            
            Divider().frame(height: 24)
            
            // 詳細ボタン
            ToolbarButton(
                icon: "info.circle",
                label: "詳細",
                action: { viewModel.showDetailView = true }
            )
        }
        .frame(height: 64)
        .background(Color(.systemBackground))
    }
}
```

---

### ステップ6: 自動削除機能の実装

**ファイル**: `KiroBookmark/KiroBookmarkApp.swift` または `KiroBookmark/Managers/CleanupManager.swift`

#### アプリ起動時に自動削除を実行

```swift
@main
struct KiroBookmarkApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // ✨ 起動時に古い記事を削除
                    Task {
                        await cleanupOldArticles()
                    }
                }
        }
    }
    
    private func cleanupOldArticles() async {
        let blogManager = BlogManager(context: persistenceController.container.viewContext)
        do {
            try await blogManager.cleanupOldNewEntries()
        } catch {
            print("Failed to cleanup old articles: \(error)")
        }
    }
}
```

#### バックグラウンドタスクでの定期実行（オプション）

```swift
import BackgroundTasks

// AppDelegate または SceneDelegate
func scheduleAppRefresh() {
    let request = BGAppRefreshTaskRequest(identifier: "com.kiro.cleanup")
    request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60) // 24時間後
    
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("Could not schedule app refresh: \(error)")
    }
}

func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefresh() // 次回のタスクをスケジュール
    
    Task {
        let blogManager = BlogManager(context: persistenceController.container.viewContext)
        try? await blogManager.cleanupOldNewEntries()
        task.setTaskCompleted(success: true)
    }
}
```

---

### ステップ7: ViewModel実装

**ファイル**: `KiroBookmark/ViewModels/NewEntryViewModel.swift`（新規作成）

```swift
import Foundation
import Combine

@MainActor
class NewEntryViewModel: ObservableObject {
    @Published var newEntryArticles: [ArticleBookmark] = []
    @Published var isLoading = false
    @Published var selectedArticle: ArticleBookmark?
    
    private let blogManager: BlogManagerProtocol
    
    init(blogManager: BlogManagerProtocol = BlogManager.shared) {
        self.blogManager = blogManager
        loadNewEntryArticles()
    }
    
    func loadNewEntryArticles() {
        isLoading = true
        Task {
            newEntryArticles = await blogManager.getNewEntryArticles()
            isLoading = false
        }
    }
    
    func addToBookmark(_ articleId: UUID) async {
        do {
            try await blogManager.addToBookmark(articleId: articleId)
            // リスト更新
            loadNewEntryArticles()
        } catch {
            print("Failed to add bookmark: \(error)")
        }
    }
    
    func markAsViewed(_ articleId: UUID) async {
        do {
            try await blogManager.markAsViewed(articleId: articleId)
        } catch {
            print("Failed to mark as viewed: \(error)")
        }
    }
}
```

**ファイル**: `KiroBookmark/ViewModels/BookmarkViewModel.swift`（既存を更新）

```swift
@MainActor
class BookmarkViewModel: ObservableObject {
    @Published var userBookmarks: [ArticleBookmark] = []
    @Published var isLoading = false
    
    private let blogManager: BlogManagerProtocol
    
    init(blogManager: BlogManagerProtocol = BlogManager.shared) {
        self.blogManager = blogManager
        loadUserBookmarks()
    }
    
    func loadUserBookmarks() {
        isLoading = true
        Task {
            userBookmarks = await blogManager.getUserBookmarks()
            isLoading = false
        }
    }
}
```

---

### ステップ8: プロパティテスト実装

**ファイル**: `KiroBookmarkTests/PropertyTests.swift`

```swift
import XCTest
import SwiftCheck
@testable import KiroBookmark

class NewEntryBookmarkPropertyTests: XCTestCase {
    
    // Property 29: New Entry記事の自動削除
    func testProperty29_OldNewEntriesAutoDelete() {
        property("Articles older than 20 days should be deleted") <- forAll { (url: URL, title: String) in
            let blogManager = BlogManager(context: testContext)
            
            // 21日前の記事を作成
            let oldDate = Calendar.current.date(byAdding: .day, value: -21, to: Date())!
            let article = ArticleBookmark(url: url, title: title, isFromRSS: true)
            article.rssAddedDate = oldDate
            
            try! testContext.save()
            
            // クリーンアップ実行
            try! await blogManager.cleanupOldNewEntries()
            
            // 記事が削除されていることを確認
            let articles = await blogManager.getNewEntryArticles()
            return !articles.contains(where: { $0.id == article.id })
        }
    }
    
    // Property 30: ブックマーク追加の状態更新
    func testProperty30_AddToBookmarkUpdatesState() {
        property("Adding to bookmark should update isUserBookmarked flag") <- forAll { (url: URL, title: String) in
            let blogManager = BlogManager(context: testContext)
            
            // New Entry記事を作成
            let article = ArticleBookmark(url: url, title: title, isFromRSS: true)
            try! testContext.save()
            
            // ブックマークに追加
            try! await blogManager.addToBookmark(articleId: article.id)
            
            // フラグが更新されていることを確認
            let fetchRequest = ArticleBookmark.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", article.id as CVarArg)
            let updated = try! testContext.fetch(fetchRequest).first!
            
            return updated.isUserBookmarked == true
        }
    }
    
    // Property 31: 閲覧時の状態更新
    func testProperty31_ViewingUpdatesState() {
        property("Viewing article should update viewedDate, viewCount, and readingStatus") <- forAll { (url: URL, title: String) in
            let blogManager = BlogManager(context: testContext)
            
            let article = ArticleBookmark(url: url, title: title)
            let initialViewCount = article.viewCount
            try! testContext.save()
            
            // 閲覧記録
            try! await blogManager.markAsViewed(articleId: article.id)
            
            // 状態が更新されていることを確認
            let fetchRequest = ArticleBookmark.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", article.id as CVarArg)
            let updated = try! testContext.fetch(fetchRequest).first!
            
            return updated.viewedDate != nil &&
                   updated.viewCount == initialViewCount + 1 &&
                   updated.readingStatus == .read
        }
    }
    
    // Property 32: タブ表示フィルタリング
    func testProperty32_TabFilteringConsistency() {
        property("Articles should appear in correct tab based on isUserBookmarked") <- forAll { (url: URL, title: String, isBookmarked: Bool) in
            let blogManager = BlogManager(context: testContext)
            
            let article = ArticleBookmark(url: url, title: title, isFromRSS: !isBookmarked)
            try! testContext.save()
            
            let newEntryArticles = await blogManager.getNewEntryArticles()
            let userBookmarks = await blogManager.getUserBookmarks()
            
            if isBookmarked {
                return userBookmarks.contains(where: { $0.id == article.id }) &&
                       !newEntryArticles.contains(where: { $0.id == article.id })
            } else {
                return newEntryArticles.contains(where: { $0.id == article.id }) &&
                       !userBookmarks.contains(where: { $0.id == article.id })
            }
        }
    }
}
```

---

## ✅ テスト手順

### 1. ビルドとクリーン
```bash
Cmd+Shift+K  # クリーン
Cmd+B        # ビルド
```

### 2. 基本動作テスト

#### テストケース1: New Entryタブ表示
1. アプリを起動
2. New Entryタブを選択
3. **RSS記事（isUserBookmarked == false）のみが表示される** ✅

#### テストケース2: ブックマーク追加（一覧から）
1. New Entry一覧でカード右上の「+」ボタンをタップ
2. **記事がBookmarkタブに移動する** ✅
3. **New Entryタブから消える** ✅

#### テストケース3: ブックマーク追加（WebViewから）
1. New Entry記事をタップしてWebView表示
2. ツールバーの「保存」ボタンをタップ
3. **記事がBookmarkタブに移動する** ✅
4. **ボタンが非表示になる** ✅

#### テストケース4: 閲覧記録
1. New Entry記事をタップ
2. **viewedDateが更新される** ✅
3. **viewCountが1増える** ✅
4. **readingStatusがreadになる** ✅

#### テストケース5: 自動削除
1. 21日前のNew Entry記事を作成（テストデータ）
2. アプリを再起動
3. **古い記事が自動削除される** ✅
4. **ブックマーク済み記事は削除されない** ✅

### 3. プロパティテスト実行

```bash
Cmd+U  # 全テスト実行
```

**期待結果**:
- Property 29: 20日経過記事の自動削除 ✅
- Property 30: ブックマーク追加の状態更新 ✅
- Property 31: 閲覧時の状態更新 ✅
- Property 32: タブ表示フィルタリング ✅

---

## 📝 実装時の注意点

### 1. マイグレーション

既存データに対して適切なデフォルト値を設定：

```swift
// 既存の全記事を「ユーザーブックマーク」として扱う
for article in existingArticles {
    article.isUserBookmarked = true
    article.isFromRSS = false
    article.viewCount = 0
}
```

### 2. パフォーマンス

大量のNew Entry記事がある場合、フィルタリングのパフォーマンスに注意：

```swift
// インデックスを追加
fetchRequest.predicate = NSPredicate(format: "isUserBookmarked == NO")
// Core Dataモデルで isUserBookmarked にインデックスを設定
```

### 3. エラーハンドリング

ブックマーク追加失敗時のユーザーフィードバック：

```swift
do {
    try await blogManager.addToBookmark(articleId: articleId)
} catch {
    // ユーザーにエラーを通知
    showError = true
    errorMessage = "ブックマークの追加に失敗しました"
}
```

### 4. UI/UXの考慮

- ブックマーク追加時にアニメーション表示
- 成功時にトースト通知
- ボタンの状態を即座に反映

---

## 🐛 トラブルシューティング

### 問題: 既存記事がNew Entryに表示される
- マイグレーションが正しく実行されているか確認
- `isUserBookmarked` のデフォルト値を確認

### 問題: ブックマーク追加ボタンが表示されない
- `!bookmark.isUserBookmarked` の条件を確認
- ArticleCardViewに `onAddBookmark` が渡されているか確認

### 問題: 自動削除が動作しない
- `rssAddedDate` が正しく設定されているか確認
- `cleanupOldNewEntries()` が呼ばれているか確認
- 日付計算のロジックを確認

### 問題: 閲覧記録が更新されない
- `markAsViewed()` が呼ばれているか確認
- Core Dataの保存処理を確認

---

## ✅ 完了条件

- [ ] データモデル拡張完了（5つの新規フィールド）
- [ ] BlogManager機能追加完了（5つの新規メソッド）
- [ ] New Entryタブ実装完了
- [ ] Bookmarkタブ実装完了
- [ ] ブックマーク追加ボタン実装完了（一覧 + WebView）
- [ ] 閲覧記録機能実装完了
- [ ] 自動削除機能実装完了
- [ ] プロパティテスト実装完了（4つ）
- [ ] クリーンビルドが成功
- [ ] 全テストが通過
- [ ] 既存機能に影響なし

---

## 📊 期待される結果

- ✅ New EntryタブにRSS記事のみが表示される
- ✅ Bookmarkタブにユーザーブックマークのみが表示される
- ✅ ブックマーク追加ボタンが正しく動作する
- ✅ 記事閲覧時に自動的に既読マークされる
- ✅ 20日経過したNew Entry記事が自動削除される
- ✅ ブックマーク済み記事は永続保存される

---

**この実装が完了したら、Phase 1Bの次の機能（記事閲覧状態管理、ドメイン整理）に進んでください。**
