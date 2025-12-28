# Task 1: カードタップアクションの変更

## 🎯 目的

ArticleCardViewのタップアクションを変更し、記事詳細画面ではなくWebView記事表示に直接遷移するようにします。

---

## 🔍 事前調査

以下のファイルを確認してください：

1. **KiroBookmark/Views/ArticleCardView.swift**
   - 現在のタップアクション実装を確認
   - `onCardTap` クロージャーの使用箇所を確認

2. **KiroBookmark/Views/HomeView.swift**
   - NavigationStackの遷移ロジックを確認
   - ArticleRouteの定義を確認

---

## 🔧 修正内容

### ステップ1: HomeView.swiftの遷移先変更

**ファイル**: `KiroBookmark/Views/HomeView.swift`

#### 現在の実装を確認

以下のようなコードを探してください：

```swift
.navigationDestination(for: ArticleBookmark.self) { bookmark in
    ArticleDetailView(bookmark: bookmark)
}
```

または

```swift
NavigationLink(destination: ArticleDetailView(bookmark: bookmark)) {
    ArticleCardView(bookmark: bookmark)
}
```

#### 修正方法

**パターンA: navigationDestinationを使用している場合**

**変更前**:
```swift
.navigationDestination(for: ArticleBookmark.self) { bookmark in
    ArticleDetailView(bookmark: bookmark)
}
```

**変更後**:
```swift
.navigationDestination(for: ArticleBookmark.self) { bookmark in
    ArticleWebView(bookmark: bookmark)
}
```

---

**パターンB: NavigationLinkを使用している場合**

**変更前**:
```swift
NavigationLink(destination: ArticleDetailView(bookmark: bookmark)) {
    ArticleCardView(bookmark: bookmark)
}
```

**変更後**:
```swift
NavigationLink(destination: ArticleWebView(bookmark: bookmark)) {
    ArticleCardView(bookmark: bookmark)
}
```

---

**パターンC: カスタムルーティングを使用している場合**

もしArticleRouteのようなenumを使用している場合：

```swift
enum ArticleRoute: Hashable {
    case detail(ArticleBookmark)
    case webView(ArticleBookmark)
}
```

**変更前**:
```swift
.navigationDestination(for: ArticleRoute.self) { route in
    switch route {
    case .detail(let bookmark):
        ArticleDetailView(bookmark: bookmark)
    case .webView(let bookmark):
        ArticleWebView(bookmark: bookmark)
    }
}

// カードタップ時
navigationPath.append(ArticleRoute.detail(bookmark))
```

**変更後**:
```swift
.navigationDestination(for: ArticleRoute.self) { route in
    switch route {
    case .detail(let bookmark):
        ArticleDetailView(bookmark: bookmark)
    case .webView(let bookmark):
        ArticleWebView(bookmark: bookmark)
    }
}

// カードタップ時
navigationPath.append(ArticleRoute.webView(bookmark))  // ← 変更
```

---

### ステップ2: ArticleCardView.swiftの確認

**ファイル**: `KiroBookmark/Views/ArticleCardView.swift`

#### 確認ポイント

ArticleCardView内のタップアクションが正しく動作するか確認：

```swift
.onTapGesture {
    onCardTap()  // このクロージャーが呼ばれているか確認
}
```

もし直接NavigationLinkを使用している場合は、HomeView側の変更だけで完了です。

---

## ✅ テスト手順

### 1. ビルドとクリーン
```bash
Cmd+Shift+K  # クリーン
Cmd+B        # ビルド
```

### 2. 基本動作テスト

#### テストケース1: Bookmarkタブからの遷移
1. アプリを起動
2. Bookmarkタブを表示
3. 任意のカードをタップ
4. **WebView記事表示画面が表示されることを確認** ✅
5. **記事詳細画面ではないことを確認** ✅

#### テストケース2: New Entryタブからの遷移
1. New Entryタブを表示
2. 任意のカードをタップ
3. **WebView記事表示画面が表示されることを確認** ✅

#### テストケース3: サイドメニューからの遷移
1. サイドメニューを開く
2. 任意のメニュー項目（アイディア、感想など）を選択
3. カードをタップ
4. **WebView記事表示画面が表示されることを確認** ✅

### 3. 戻るボタンの動作確認
1. WebView記事表示画面で左上の「戻る」ボタンをタップ
2. **カード一覧に戻ることを確認** ✅
3. **正しいタブ・メニュー状態が保持されていることを確認** ✅

### 4. 既存機能への影響確認
- [ ] お気に入りボタンが正常に動作する
- [ ] カードの表示が正常
- [ ] スクロールが正常に動作する
- [ ] サイドメニューが正常に動作する

---

## 📝 実装時の注意点

### 1. ArticleWebViewの存在確認

もしArticleWebViewが存在しない場合は、まず基本的なWebViewを作成してください：

```swift
import SwiftUI
import WebKit

struct ArticleWebView: View {
    let bookmark: ArticleBookmark
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WebView(url: bookmark.url)
            .navigationTitle(bookmark.title ?? "記事")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        // 更新処理
    }
}
```

### 2. コメント追加

変更箇所にコメントを追加：

```swift
// Article Preview UI Improvement: カードタップで直接WebView表示
.navigationDestination(for: ArticleBookmark.self) { bookmark in
    ArticleWebView(bookmark: bookmark)
}
```

### 3. 既存のArticleDetailViewへのアクセス

記事詳細画面は削除せず、Task 2で追加するツールバーの「詳細」ボタンからアクセスできるようにします。

---

## 🐛 トラブルシューティング

### 問題: ビルドエラー「ArticleWebView not found」
- ArticleWebViewが存在しない場合は、上記の基本実装を追加
- importステートメントを確認

### 問題: タップしても画面遷移しない
- NavigationStackが正しく設定されているか確認
- onCardTapクロージャーが呼ばれているか確認（print文でデバッグ）

### 問題: 戻るボタンで戻れない
- NavigationStackの階層を確認
- dismissまたはnavigationPath.removeLastが正しく動作しているか確認

---

## ✅ 完了条件

- [ ] HomeView.swiftの遷移先を変更完了
- [ ] クリーンビルドが成功
- [ ] 全テストケースが通過
- [ ] 既存機能に影響なし
- [ ] コメントを追加

---

## 📊 期待される結果

- ✅ カードタップでWebView記事表示に直接遷移
- ✅ 記事詳細画面を経由しない
- ✅ New Entry、Bookmark、サイドメニュー全てで動作
- ✅ 戻るボタンで正しく一覧に戻る

---

**この修正が完了したら、Task 2（ツールバーUI追加）に進んでください。**
