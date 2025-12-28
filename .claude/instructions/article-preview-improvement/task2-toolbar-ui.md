# Task 2: ツールバーUI追加

## 🎯 目的

ArticleWebViewに記事操作用のツールバーを追加します。メモ追加、引用、TODO、お気に入り、詳細画面への遷移をツールバーから実行できるようにします。

---

## 🎨 UI設計

### ツールバーレイアウト

```
┌─────────────────────────────────┐
│                                 │
│     記事コンテンツ              │
│     （WebView）                 │
│                                 │
├─────────────────────────────────┤
│  📝   💭   ✅   ⭐   📋        │ ← ツールバー
│ メモ 引用 TODO お気に 詳細      │
└─────────────────────────────────┘
```

### ツールバーボタン仕様

| アイコン | ラベル | アクション | 優先度 |
|---------|--------|-----------|--------|
| 📝 | メモ | メモ追加モーダル表示 | 高 |
| 💭 | 引用 | テキスト選択モード | 高 |
| ✅ | TODO | TODOメモ追加 | 中 |
| ⭐ | お気に入り | トグル | 中 |
| 📋 | 詳細 | 記事詳細画面へ遷移 | 低 |

---

## 🔧 実装内容

### ステップ1: ArticleWebView.swiftの拡張

**ファイル**: `KiroBookmark/Views/ArticleWebView.swift`

#### 基本構造

```swift
import SwiftUI
import WebKit

struct ArticleWebView: View {
    let bookmark: ArticleBookmark
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ArticleWebViewModel
    
    // モーダル表示用
    @State private var showMemoSheet = false
    @State private var showDetailView = false
    
    init(bookmark: ArticleBookmark) {
        self.bookmark = bookmark
        _viewModel = StateObject(wrappedValue: ArticleWebViewModel(bookmark: bookmark))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView
            WebView(url: bookmark.url)
            
            // ツールバー
            toolbarView
        }
        .navigationTitle(bookmark.title ?? "記事")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMemoSheet) {
            AddMemoSheet(bookmark: bookmark)
        }
        .navigationDestination(isPresented: $showDetailView) {
            ArticleDetailView(bookmark: bookmark)
        }
    }
    
    // ツールバーUI
    private var toolbarView: some View {
        HStack(spacing: 0) {
            // メモボタン
            ToolbarButton(
                icon: "square.and.pencil",
                label: "メモ",
                action: { showMemoSheet = true }
            )
            
            Divider()
                .frame(height: 24)
            
            // 引用ボタン
            ToolbarButton(
                icon: "quote.bubble",
                label: "引用",
                action: { viewModel.enableTextSelection() }
            )
            
            Divider()
                .frame(height: 24)
            
            // TODOボタン
            ToolbarButton(
                icon: "checkmark.circle",
                label: "TODO",
                action: { viewModel.addQuickTodo() }
            )
            
            Divider()
                .frame(height: 24)
            
            // お気に入りボタン
            ToolbarButton(
                icon: viewModel.isFavorite ? "heart.fill" : "heart",
                label: "お気に入り",
                isActive: viewModel.isFavorite,
                action: { viewModel.toggleFavorite() }
            )
            
            Divider()
                .frame(height: 24)
            
            // 詳細ボタン
            ToolbarButton(
                icon: "info.circle",
                label: "詳細",
                action: { showDetailView = true }
            )
        }
        .frame(height: 64)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

// ツールバーボタンコンポーネント
struct ToolbarButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? .blue : .primary)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isActive ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// WebViewコンポーネント（既存のものを使用、なければ作成）
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 更新処理
    }
}

#Preview {
    NavigationStack {
        ArticleWebView(
            bookmark: ArticleBookmark(
                url: URL(string: "https://example.com")!,
                title: "サンプル記事"
            )
        )
    }
}
```

---

### ステップ2: ArticleWebViewModel.swiftの作成

**ファイル**: `KiroBookmark/ViewModels/ArticleWebViewModel.swift`（新規作成）

```swift
import Foundation
import Combine

@MainActor
class ArticleWebViewModel: ObservableObject {
    @Published var isFavorite: Bool = false
    @Published var isTextSelectionEnabled: Bool = false
    
    private let bookmark: ArticleBookmark
    private let bookmarkRepository: BookmarkRepository
    private let memoRepository: MemoRepository
    
    init(
        bookmark: ArticleBookmark,
        bookmarkRepository: BookmarkRepository = BookmarkRepository.shared,
        memoRepository: MemoRepository = MemoRepository.shared
    ) {
        self.bookmark = bookmark
        self.bookmarkRepository = bookmarkRepository
        self.memoRepository = memoRepository
        self.isFavorite = bookmark.isFavorite
    }
    
    // お気に入りトグル
    func toggleFavorite() {
        isFavorite.toggle()
        Task {
            do {
                try await bookmarkRepository.updateFavorite(
                    bookmarkId: bookmark.id,
                    isFavorite: isFavorite
                )
            } catch {
                // エラーハンドリング
                print("Failed to toggle favorite: \(error)")
                isFavorite.toggle() // 元に戻す
            }
        }
    }
    
    // テキスト選択モード有効化
    func enableTextSelection() {
        isTextSelectionEnabled = true
        // Task 3で実装
    }
    
    // クイックTODO追加
    func addQuickTodo() {
        Task {
            do {
                // 空のTODOメモを作成
                try await memoRepository.addMemo(
                    to: bookmark.id,
                    content: "",
                    type: .todo
                )
                // 成功通知（オプション）
            } catch {
                print("Failed to add TODO: \(error)")
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

### 2. UI表示テスト

#### テストケース1: ツールバーの表示
1. カード一覧から記事をタップ
2. WebView記事表示画面が開く
3. **画面下部にツールバーが表示されることを確認** ✅
4. **5つのボタンが表示されることを確認** ✅

#### テストケース2: ツールバーのレイアウト
1. ツールバーの高さが適切（64pt）✅
2. ボタンが均等に配置されている ✅
3. アイコンとラベルが表示されている ✅
4. ボタン間に区切り線がある ✅

#### テストケース3: ボタンのタップ反応
1. 各ボタンをタップ
2. **タップ時に視覚的なフィードバックがある** ✅
3. **現時点ではアクションは未実装でOK** ✅

### 3. レスポンシブ確認

#### 異なる画面サイズでテスト
- iPhone SE（小）
- iPhone 15 Pro（中）
- iPhone 15 Pro Max（大）

各サイズで：
- [ ] ツールバーが正しく表示される
- [ ] ボタンが均等に配置される
- [ ] テキストが切れない

### 4. ダークモード確認
1. ダークモードに切り替え
2. **ツールバーの背景色が適切** ✅
3. **アイコンとテキストが見やすい** ✅
4. **区切り線が見える** ✅

---

## 📝 実装時の注意点

### 1. 既存のWebViewコンポーネントを確認

プロジェクト内に既にWebViewコンポーネントが存在する場合は、それを使用してください。

検索方法：
```bash
# プロジェクト内でWebViewを検索
grep -r "struct WebView" KiroBookmark/
```

### 2. Safe Areaの考慮

ツールバーがホームインジケーターと重ならないように：

```swift
.safeAreaInset(edge: .bottom) {
    toolbarView
}
```

または

```swift
toolbarView
    .padding(.bottom, geometry.safeAreaInsets.bottom)
```

### 3. アクセシビリティ

各ボタンにアクセシビリティラベルを追加：

```swift
.accessibilityLabel(label)
.accessibilityHint("タップして\(label)を実行")
```

### 4. パフォーマンス

ツールバーの再描画を最小限に：

```swift
private var toolbarView: some View {
    // @ViewBuilder を使用して効率的に
}
```

---

## 🐛 トラブルシューティング

### 問題: ツールバーが表示されない
- VStackのspacingが0になっているか確認
- toolbarViewが正しく呼ばれているか確認

### 問題: ボタンがタップできない
- buttonStyle(.plain)が設定されているか確認
- contentShape(Rectangle())が設定されているか確認

### 問題: レイアウトが崩れる
- HStackのspacingを0に設定
- frame(maxWidth: .infinity)が各ボタンに設定されているか確認

### 問題: ダークモードで見づらい
- Color(.systemBackground)を使用
- Color.primaryとColor.secondaryを使用

---

## ✅ 完了条件

- [ ] ArticleWebView.swiftにツールバーUI追加完了
- [ ] ArticleWebViewModel.swift作成完了
- [ ] クリーンビルドが成功
- [ ] UI表示テストが全て通過
- [ ] レスポンシブ確認完了
- [ ] ダークモード確認完了
- [ ] アクセシビリティ対応完了

---

## 📊 期待される結果

- ✅ WebView記事表示画面にツールバーが表示される
- ✅ 5つのボタンが均等に配置される
- ✅ ボタンがタップ可能（アクションは次のタスクで実装）
- ✅ ライトモード・ダークモード両方で見やすい
- ✅ 全画面サイズで正しく表示される

---

**この修正が完了したら、Task 3（ツールバーアクション実装）に進んでください。**
