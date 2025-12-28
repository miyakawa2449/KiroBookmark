# Task 5: 記事詳細画面の調整

## 🎯 目的

ArticleDetailViewを新しい動線に合わせて調整します。「記事を読む」ボタンを削除し、WebViewからの遷移を想定したUIに変更します。

---

## 🔍 現状の確認

### 現在の動線（変更前）
```
カード一覧
  ↓
記事詳細画面（メモ・タグ表示）
  ↓ 「記事を読む」ボタン
WebView記事表示
```

### 新しい動線（変更後）
```
カード一覧
  ↓
WebView記事表示
  ↓ ツールバーの「詳細」ボタン
記事詳細画面（メモ・タグ表示）
```

**変更点**: 記事詳細画面は「記事を読んだ後」にアクセスする画面になる

---

## 🔧 修正内容

### ステップ1: 「記事を読む」ボタンの削除

**ファイル**: `KiroBookmark/Views/ArticleDetailView.swift`

#### 事前調査

以下のようなコードを探してください：

```swift
// パターン1: Buttonコンポーネント
Button("記事を読む") {
    // WebView表示処理
}

// パターン2: NavigationLink
NavigationLink("記事を読む", destination: ArticleWebView(bookmark: bookmark))

// パターン3: ツールバーアイテム
.toolbar {
    ToolbarItem {
        Button("記事を読む") {
            // 処理
        }
    }
}
```

#### 削除方法

**変更前**:
```swift
struct ArticleDetailView: View {
    let bookmark: ArticleBookmark
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 記事情報
                articleInfoSection
                
                // 「記事を読む」ボタン
                Button(action: {
                    showWebView = true
                }) {
                    HStack {
                        Image(systemName: "safari")
                        Text("記事を読む")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // メモセクション
                memoSection
                
                // タグセクション
                tagSection
            }
        }
        .navigationTitle(bookmark.title ?? "記事詳細")
    }
}
```

**変更後**:
```swift
struct ArticleDetailView: View {
    let bookmark: ArticleBookmark
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 記事情報
                articleInfoSection
                
                // 「記事を読む」ボタンを削除
                
                // メモセクション
                memoSection
                
                // タグセクション
                tagSection
            }
        }
        .navigationTitle(bookmark.title ?? "記事詳細")
    }
}
```

---

### ステップ2: 記事情報セクションの強化（オプション）

「記事を読む」ボタンを削除した代わりに、記事情報を充実させます。

#### 追加する情報

```swift
private var articleInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        // タイトル
        Text(bookmark.title ?? "タイトルなし")
            .font(.title2)
            .fontWeight(.bold)
        
        // URL
        HStack {
            Image(systemName: "link")
                .foregroundColor(.secondary)
            Text(bookmark.url.absoluteString)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        
        // 公開日時
        if let publishedDate = bookmark.publishedDate {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(publishedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        // ブックマーク日時
        HStack {
            Image(systemName: "bookmark")
                .foregroundColor(.secondary)
            Text("ブックマーク: \(bookmark.bookmarkedDate, style: .date)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        // お気に入り状態
        if bookmark.isFavorite {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("お気に入り")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        
        Divider()
    }
    .padding()
}
```

---

### ステップ3: ナビゲーションタイトルの調整

記事詳細画面が「記事を読んだ後」にアクセスする画面になったことを明確にします。

**変更前**:
```swift
.navigationTitle(bookmark.title ?? "記事詳細")
```

**変更後**:
```swift
.navigationTitle("記事詳細")
.navigationBarTitleDisplayMode(.inline)
```

理由: タイトルが長い場合に見やすくするため

---

### ステップ4: WebViewへの遷移を削除

もしArticleDetailViewからWebViewへの遷移が残っている場合は削除します。

#### 削除対象

```swift
// 削除: WebView表示用のState
@State private var showWebView = false

// 削除: navigationDestination
.navigationDestination(isPresented: $showWebView) {
    ArticleWebView(bookmark: bookmark)
}

// 削除: sheet
.sheet(isPresented: $showWebView) {
    ArticleWebView(bookmark: bookmark)
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

#### テストケース1: 新しい動線の確認
1. カード一覧から記事をタップ
2. **WebView記事表示画面が開く** ✅
3. ツールバーの「詳細」ボタンをタップ
4. **記事詳細画面が開く** ✅
5. **「記事を読む」ボタンが存在しない** ✅

#### テストケース2: 記事情報の表示
1. 記事詳細画面を開く
2. **タイトルが表示される** ✅
3. **URLが表示される** ✅
4. **日時情報が表示される** ✅
5. **お気に入り状態が表示される**（該当する場合）✅

#### テストケース3: メモ・タグ機能
1. 記事詳細画面でメモを追加
2. **メモが正常に追加される** ✅
3. タグを追加
4. **タグが正常に追加される** ✅
5. メモを編集
6. **メモが正常に編集される** ✅

### 3. ナビゲーション確認

#### テストケース4: 戻る動作
1. WebView → 詳細画面 → 戻る
2. **WebView画面に戻る** ✅
3. WebView → 戻る
4. **カード一覧に戻る** ✅

#### テストケース5: 深い階層からの戻り
1. カード一覧 → WebView → 詳細 → メモ編集
2. 各画面で戻るボタンが正常に動作する ✅
3. 最終的にカード一覧に戻れる ✅

---

## 📝 実装時の注意点

### 1. 既存のメモ・タグ機能を維持

「記事を読む」ボタンを削除しても、以下の機能は維持してください：
- メモの追加・編集・削除
- タグの追加・削除
- お気に入りのトグル
- 記事情報の表示

### 2. レイアウトの調整

ボタンを削除した後、空白が目立つ場合はレイアウトを調整：

```swift
VStack(spacing: 16) {
    articleInfoSection
    
    // 空白を詰める
    memoSection
        .padding(.top, 8)  // 適切な余白を追加
    
    tagSection
}
```

### 3. コメント追加

変更箇所にコメントを追加：

```swift
// Article Preview UI Improvement: 「記事を読む」ボタンを削除
// 理由: カードタップで直接WebView表示するため、このボタンは不要
```

### 4. 既存のViewModelロジック

もしArticleDetailViewModelに「記事を読む」ボタン関連のロジックがある場合は削除：

```swift
// 削除対象
@Published var showWebView = false

func openWebView() {
    showWebView = true
}
```

---

## 🐛 トラブルシューティング

### 問題: ビルドエラー「showWebView not found」
- ArticleDetailView内でshowWebViewを使用している箇所を全て削除
- ViewModelにも残っていないか確認

### 問題: レイアウトが崩れる
- VStackのspacingを調整
- padding値を見直す

### 問題: ナビゲーションが正しく動作しない
- NavigationStackの階層を確認
- navigationDestinationが重複していないか確認

---

## 🎨 UI改善提案（オプション）

### 提案1: 記事へのクイックアクセス

詳細画面から記事に戻りたい場合のために、ツールバーに「記事を見る」ボタンを追加：

```swift
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: {
            // WebView画面に戻る
            dismiss()
        }) {
            Image(systemName: "doc.text")
            Text("記事")
        }
    }
}
```

### 提案2: 記事情報カード

記事情報をカード形式で表示：

```swift
private var articleInfoSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        // 記事情報
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .padding(.horizontal)
}
```

---

## ✅ 完了条件

- [ ] 「記事を読む」ボタン削除完了
- [ ] WebViewへの遷移削除完了
- [ ] 記事情報セクション強化完了（オプション）
- [ ] クリーンビルドが成功
- [ ] 全テストケースが通過
- [ ] ナビゲーションが正常に動作
- [ ] 既存のメモ・タグ機能が正常に動作

---

## 📊 期待される結果

- ✅ 「記事を読む」ボタンが削除される
- ✅ 記事詳細画面が「記事を読んだ後」の画面として機能
- ✅ メモ・タグ機能が正常に動作
- ✅ ナビゲーションがスムーズ
- ✅ UIがシンプルで分かりやすい

---

## 🎉 全タスク完了後

Task 1〜5が全て完了したら、以下を実行してください：

### 最終確認
1. **全体の動線確認**: カード一覧 → WebView → 詳細画面
2. **全機能テスト**: メモ、タグ、お気に入り、引用
3. **パフォーマンス確認**: スムーズに動作するか
4. **ユーザーテスト**: 実際に使ってみて使いやすいか

### ドキュメント更新
- README.mdに新しい動線を記載
- 変更履歴を記録

### フィードバック収集
- ユーザーからのフィードバックを収集
- 改善点を洗い出し

---

**お疲れ様でした！記事プレビューUI改善が完了です。**
