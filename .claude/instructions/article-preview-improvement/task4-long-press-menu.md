# Task 4: ロングプレスメニュー実装

## 🎯 目的

カードをロングプレス（長押し）した際にクイックアクションメニューを表示し、パワーユーザー向けの効率的な操作を提供します。

---

## 🎨 UI設計

### ロングプレスメニュー

```
カードをロングプレス
         ↓
┌─────────────────────────┐
│ 📖 記事を読む           │
│ 📝 メモを追加           │
│ 🏷️ タグを編集           │
│ ⭐ お気に入り           │
│ 📋 詳細を見る           │
│ 🗑️ 削除                │
└─────────────────────────┘
```

### メニュー項目

| アイコン | ラベル | アクション | 優先度 |
|---------|--------|-----------|--------|
| 📖 | 記事を読む | WebView表示 | 高 |
| 📝 | メモを追加 | メモ追加モーダル | 高 |
| 🏷️ | タグを編集 | タグ編集モーダル | 中 |
| ⭐ | お気に入り | お気に入りトグル | 中 |
| 📋 | 詳細を見る | 記事詳細画面 | 低 |
| 🗑️ | 削除 | 削除確認ダイアログ | 低 |

---

## 🔧 実装内容

### ステップ1: ArticleCardView.swiftにロングプレスジェスチャー追加

**ファイル**: `KiroBookmark/Views/ArticleCardView.swift`

#### 基本実装

```swift
import SwiftUI

struct ArticleCardView: View {
    let bookmark: ArticleBookmark
    let onCardTap: () -> Void
    
    @State private var showQuickActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 既存のカードコンテンツ
            cardContent
        }
        .padding(16)
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            // ハプティックフィードバック
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // メニュー表示
            showQuickActions = true
        }
        .confirmationDialog("クイックアクション", isPresented: $showQuickActions) {
            quickActionsMenu
        }
    }
    
    private var cardContent: some View {
        // 既存のカードコンテンツ
        VStack(alignment: .leading, spacing: 8) {
            Text(bookmark.title ?? "タイトルなし")
                .font(.headline)
                .lineLimit(2)
            
            if let publishedDate = bookmark.publishedDate {
                Text(publishedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var quickActionsMenu: some View {
        // 記事を読む
        Button(action: {
            onCardTap()
        }) {
            Label("記事を読む", systemImage: "doc.text")
        }
        
        // メモを追加
        Button(action: {
            // メモ追加処理
        }) {
            Label("メモを追加", systemImage: "square.and.pencil")
        }
        
        // タグを編集
        Button(action: {
            // タグ編集処理
        }) {
            Label("タグを編集", systemImage: "tag")
        }
        
        // お気に入り
        Button(action: {
            // お気に入りトグル処理
        }) {
            Label(
                bookmark.isFavorite ? "お気に入りを解除" : "お気に入りに追加",
                systemImage: bookmark.isFavorite ? "heart.fill" : "heart"
            )
        }
        
        // 詳細を見る
        Button(action: {
            // 詳細画面表示処理
        }) {
            Label("詳細を見る", systemImage: "info.circle")
        }
        
        Divider()
        
        // 削除
        Button(role: .destructive, action: {
            // 削除処理
        }) {
            Label("削除", systemImage: "trash")
        }
    }
}
```

---

### ステップ2: クイックアクションの実装

#### HomeView.swiftの更新

**ファイル**: `KiroBookmark/Views/HomeView.swift`

クイックアクションからの遷移を処理するため、HomeViewを更新します。

```swift
struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    
    // クイックアクション用のState
    @State private var selectedBookmarkForMemo: ArticleBookmark?
    @State private var selectedBookmarkForTag: ArticleBookmark?
    @State private var selectedBookmarkForDetail: ArticleBookmark?
    @State private var bookmarkToDelete: ArticleBookmark?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            // 既存のコンテンツ
            content
        }
        // メモ追加シート
        .sheet(item: $selectedBookmarkForMemo) { bookmark in
            AddMemoSheet(bookmark: bookmark)
        }
        // タグ編集シート
        .sheet(item: $selectedBookmarkForTag) { bookmark in
            EditTagsSheet(bookmark: bookmark)
        }
        // 詳細画面への遷移
        .sheet(item: $selectedBookmarkForDetail) { bookmark in
            NavigationStack {
                ArticleDetailView(bookmark: bookmark)
            }
        }
        // 削除確認ダイアログ
        .alert("ブックマークを削除", isPresented: $showDeleteConfirmation) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                if let bookmark = bookmarkToDelete {
                    deleteBookmark(bookmark)
                }
            }
        } message: {
            Text("このブックマークを削除してもよろしいですか？")
        }
    }
    
    private func deleteBookmark(_ bookmark: ArticleBookmark) {
        Task {
            do {
                try await viewModel.deleteBookmark(bookmark)
            } catch {
                print("Failed to delete bookmark: \(error)")
            }
        }
    }
}
```

---

### ステップ3: ArticleCardViewの更新（クイックアクション連携）

**ファイル**: `KiroBookmark/Views/ArticleCardView.swift`

クイックアクションのコールバックを追加します。

```swift
struct ArticleCardView: View {
    let bookmark: ArticleBookmark
    let onCardTap: () -> Void
    let onAddMemo: (() -> Void)?
    let onEditTags: (() -> Void)?
    let onToggleFavorite: (() -> Void)?
    let onShowDetail: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showQuickActions = false
    
    init(
        bookmark: ArticleBookmark,
        onCardTap: @escaping () -> Void,
        onAddMemo: (() -> Void)? = nil,
        onEditTags: (() -> Void)? = nil,
        onToggleFavorite: (() -> Void)? = nil,
        onShowDetail: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.bookmark = bookmark
        self.onCardTap = onCardTap
        self.onAddMemo = onAddMemo
        self.onEditTags = onEditTags
        self.onToggleFavorite = onToggleFavorite
        self.onShowDetail = onShowDetail
        self.onDelete = onDelete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardContent
        }
        .padding(16)
        .background(Color.systemBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onCardTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            showQuickActions = true
        }
        .confirmationDialog("クイックアクション", isPresented: $showQuickActions) {
            quickActionsMenu
        }
    }
    
    @ViewBuilder
    private var quickActionsMenu: some View {
        // 記事を読む
        Button(action: {
            onCardTap()
        }) {
            Label("記事を読む", systemImage: "doc.text")
        }
        
        // メモを追加
        if let onAddMemo = onAddMemo {
            Button(action: onAddMemo) {
                Label("メモを追加", systemImage: "square.and.pencil")
            }
        }
        
        // タグを編集
        if let onEditTags = onEditTags {
            Button(action: onEditTags) {
                Label("タグを編集", systemImage: "tag")
            }
        }
        
        // お気に入り
        if let onToggleFavorite = onToggleFavorite {
            Button(action: onToggleFavorite) {
                Label(
                    bookmark.isFavorite ? "お気に入りを解除" : "お気に入りに追加",
                    systemImage: bookmark.isFavorite ? "heart.fill" : "heart"
                )
            }
        }
        
        // 詳細を見る
        if let onShowDetail = onShowDetail {
            Button(action: onShowDetail) {
                Label("詳細を見る", systemImage: "info.circle")
            }
        }
        
        Divider()
        
        // 削除
        if let onDelete = onDelete {
            Button(role: .destructive, action: onDelete) {
                Label("削除", systemImage: "trash")
            }
        }
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bookmark.title ?? "タイトルなし")
                .font(.headline)
                .lineLimit(2)
            
            if let publishedDate = bookmark.publishedDate {
                Text(publishedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

---

### ステップ4: HomeViewでのArticleCardView使用例

```swift
// HomeView.swift内
ForEach(viewModel.bookmarks) { bookmark in
    ArticleCardView(
        bookmark: bookmark,
        onCardTap: {
            // WebView表示
            navigationPath.append(bookmark)
        },
        onAddMemo: {
            selectedBookmarkForMemo = bookmark
        },
        onEditTags: {
            selectedBookmarkForTag = bookmark
        },
        onToggleFavorite: {
            Task {
                await viewModel.toggleFavorite(bookmark)
            }
        },
        onShowDetail: {
            selectedBookmarkForDetail = bookmark
        },
        onDelete: {
            bookmarkToDelete = bookmark
            showDeleteConfirmation = true
        }
    )
}
```

---

## ✅ テスト手順

### 1. ビルドとクリーン
```bash
Cmd+Shift+K  # クリーン
Cmd+B        # ビルド
```

### 2. ロングプレス動作テスト

#### テストケース1: メニュー表示
1. カード一覧を表示
2. 任意のカードを0.5秒以上長押し
3. **ハプティックフィードバックがある** ✅
4. **クイックアクションメニューが表示される** ✅
5. **6つのメニュー項目が表示される** ✅

#### テストケース2: 記事を読む
1. カードをロングプレス
2. 「記事を読む」をタップ
3. **WebView記事表示画面が開く** ✅

#### テストケース3: メモを追加
1. カードをロングプレス
2. 「メモを追加」をタップ
3. **メモ追加モーダルが表示される** ✅
4. メモを入力して追加
5. **メモが保存される** ✅

#### テストケース4: タグを編集
1. カードをロングプレス
2. 「タグを編集」をタップ
3. **タグ編集モーダルが表示される** ✅
4. タグを追加
5. **タグが保存される** ✅

#### テストケース5: お気に入り
1. カードをロングプレス
2. 「お気に入りに追加」をタップ
3. **お気に入り状態がトグルされる** ✅
4. カード一覧でお気に入りアイコンが表示される ✅

#### テストケース6: 詳細を見る
1. カードをロングプレス
2. 「詳細を見る」をタップ
3. **記事詳細画面が表示される** ✅

#### テストケース7: 削除
1. カードをロングプレス
2. 「削除」をタップ
3. **削除確認ダイアログが表示される** ✅
4. 「削除」をタップ
5. **ブックマークが削除される** ✅
6. カード一覧から消える ✅

### 3. 通常タップとの共存確認

#### テストケース8: 通常タップ
1. カードを短くタップ（0.5秒未満）
2. **WebView記事表示画面が開く** ✅
3. **クイックアクションメニューは表示されない** ✅

#### テストケース9: タップとロングプレスの切り替え
1. カードをロングプレス → メニュー表示
2. キャンセル
3. カードを通常タップ → WebView表示
4. **両方が正常に動作する** ✅

---

## 📝 実装時の注意点

### 1. ロングプレスの時間調整

ユーザーテストの結果に応じて調整：

```swift
.onLongPressGesture(minimumDuration: 0.5) {  // 0.3〜0.7秒で調整
    // 処理
}
```

### 2. ハプティックフィードバック

ロングプレス開始時に必ずフィードバックを提供：

```swift
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

### 3. メニュー項目の順序

使用頻度の高い項目を上に配置：
1. 記事を読む（最頻）
2. メモを追加
3. タグを編集
4. お気に入り
5. 詳細を見る
6. 削除（破壊的アクション）

### 4. アクセシビリティ

VoiceOver使用時にもメニューにアクセスできるように：

```swift
.accessibilityAction(named: "クイックアクション") {
    showQuickActions = true
}
```

### 5. iPad対応

iPadではcontextMenuを使用することも検討：

```swift
#if os(iOS)
if UIDevice.current.userInterfaceIdiom == .pad {
    .contextMenu {
        quickActionsMenu
    }
} else {
    .onLongPressGesture {
        // iPhone用
    }
}
#endif
```

---

## 🐛 トラブルシューティング

### 問題: ロングプレスが反応しない
- minimumDurationが長すぎないか確認（0.5秒推奨）
- onTapGestureとの競合を確認
- contentShape(Rectangle())が設定されているか確認

### 問題: 通常タップが反応しない
- ロングプレスのminimumDurationを短くしすぎていないか確認
- ジェスチャーの順序を確認（onTapGestureを先に記述）

### 問題: メニューが表示されない
- confirmationDialogのisPresented bindingを確認
- showQuickActionsのState変数が正しく更新されているか確認

### 問題: ハプティックフィードバックがない
- 実機でテスト（シミュレータでは動作しない）
- UIImpactFeedbackGeneratorが正しく初期化されているか確認

---

## 🎨 UI改善提案（オプション）

### 提案1: カスタムメニューUI

confirmationDialogの代わりにカスタムメニューを実装：

```swift
.overlay {
    if showQuickActions {
        CustomQuickActionsMenu(
            bookmark: bookmark,
            onDismiss: { showQuickActions = false },
            actions: quickActions
        )
    }
}
```

### 提案2: メニュープレビュー

ロングプレス中にカードを拡大表示：

```swift
.scaleEffect(showQuickActions ? 1.05 : 1.0)
.animation(.spring(response: 0.3), value: showQuickActions)
```

---

## ✅ 完了条件

- [ ] ロングプレスジェスチャー実装完了
- [ ] クイックアクションメニュー実装完了
- [ ] 全6つのアクション実装完了
- [ ] ハプティックフィードバック実装完了
- [ ] クリーンビルドが成功
- [ ] 全テストケースが通過
- [ ] 通常タップとの共存確認完了
- [ ] アクセシビリティ対応完了

---

## 📊 期待される結果

- ✅ カードをロングプレスでメニュー表示
- ✅ 6つのクイックアクションが動作
- ✅ ハプティックフィードバックがある
- ✅ 通常タップと共存できる
- ✅ パワーユーザーの効率が向上

---

## 🎯 ユーザー体験の向上

### 通常ユーザー
- カードタップで記事を読む（シンプル）

### パワーユーザー
- ロングプレスで素早く操作（効率的）
- メモ・タグ・お気に入りを一覧から直接操作

---

**この修正が完了したら、Task 5（記事詳細画面の調整）に進んでください。**
