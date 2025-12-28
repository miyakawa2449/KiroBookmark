# Task6 修正4: URL安全性の基本バリデーション追加

## 🎯 修正の目的

ブックマーク追加時にURLの基本的な安全性チェックを追加します。無効なURLや安全でないURLの登録を防ぎます。

---

## 🔧 修正内容

### ステップ1: URLバリデーションメソッドの追加

**ファイル**: `KiroBookmark/Repositories/BookmarkRepository.swift`

BookmarkRepository内に以下のメソッドを追加します。

```swift
/// URLの基本的な安全性チェック
/// - Parameter urlString: 検証するURL文字列
/// - Returns: 有効なURLの場合true、無効な場合false
private func validateURL(_ urlString: String) -> Bool {
    // 空文字チェック
    guard !urlString.trimmingCharacters(in: .whitespaces).isEmpty else {
        return false
    }
    
    // URL形式チェック
    guard let url = URL(string: urlString) else {
        return false
    }
    
    // HTTPSスキームチェック（セキュリティ強化）
    guard url.scheme == "https" else {
        return false
    }
    
    // ホスト存在チェック
    guard let host = url.host, !host.isEmpty else {
        return false
    }
    
    return true
}
```

**追加位置**: BookmarkRepositoryクラス内の適切な場所（privateメソッドセクション）

---

### ステップ2: エラー型の定義

BookmarkRepository内にエラー型を追加します（存在しない場合）。

```swift
enum BookmarkError: LocalizedError {
    case invalidURL
    case duplicateURL
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです。https://で始まる正しいURLを入力してください。"
        case .duplicateURL:
            return "このURLは既にブックマークされています。"
        case .saveFailed:
            return "ブックマークの保存に失敗しました。"
        }
    }
}
```

**追加位置**: BookmarkRepositoryファイル内（クラス定義の外側または内側）

**注意**: 既にエラー型が存在する場合は、`invalidURL` ケースのみ追加してください。

---

### ステップ3: ブックマーク追加メソッドでのバリデーション適用

既存の `addBookmark` メソッド（または類似のメソッド）を修正します。

#### 事前調査
BookmarkRepository内で以下のようなメソッドを探してください：
- `addBookmark`
- `createBookmark`
- `saveBookmark`

#### 修正例

**変更前**:
```swift
func addBookmark(url: String, title: String?) throws -> ArticleBookmark {
    let bookmark = ArticleBookmark(context: context)
    bookmark.url = url
    bookmark.title = title
    bookmark.createdAt = Date()
    
    try context.save()
    return bookmark
}
```

**変更後**:
```swift
func addBookmark(url: String, title: String?) throws -> ArticleBookmark {
    // URLバリデーション
    guard validateURL(url) else {
        throw BookmarkError.invalidURL
    }
    
    let bookmark = ArticleBookmark(context: context)
    bookmark.url = url
    bookmark.title = title
    bookmark.createdAt = Date()
    
    try context.save()
    return bookmark
}
```

**追加箇所**: メソッドの最初、データ作成前にバリデーションを実行

---

### ステップ4: UI側でのエラーハンドリング

**ファイル**: `KiroBookmark/Views/AddBookmarkView.swift`（または類似のビュー）

ブックマーク追加処理でエラーを適切にハンドリングします。

#### 事前調査
AddBookmarkView内で以下のようなコードを探してください：
- ブックマーク追加ボタンのアクション
- `viewModel.addBookmark` の呼び出し

#### 修正例

**変更前**:
```swift
Button("追加") {
    viewModel.addBookmark(url: urlString, title: titleString)
    dismiss()
}
```

**変更後**:
```swift
Button("追加") {
    do {
        try viewModel.addBookmark(url: urlString, title: titleString)
        dismiss()
    } catch BookmarkError.invalidURL {
        errorMessage = "無効なURLです。https://で始まる正しいURLを入力してください。"
        showError = true
    } catch BookmarkError.duplicateURL {
        errorMessage = "このURLは既にブックマークされています。"
        showError = true
    } catch {
        errorMessage = "ブックマークの保存に失敗しました。"
        showError = true
    }
}
```

#### エラー表示用のStateプロパティ追加（存在しない場合）

```swift
@State private var showError = false
@State private var errorMessage = ""
```

#### アラート表示の追加

```swift
.alert("エラー", isPresented: $showError) {
    Button("OK", role: .cancel) { }
} message: {
    Text(errorMessage)
}
```

---

### ステップ5: ViewModelの更新（必要な場合）

**ファイル**: `KiroBookmark/ViewModels/AddBookmarkViewModel.swift`（または類似のViewModel）

ViewModelの `addBookmark` メソッドがエラーをスローするように変更します。

**変更前**:
```swift
func addBookmark(url: String, title: String?) {
    repository.addBookmark(url: url, title: title)
}
```

**変更後**:
```swift
func addBookmark(url: String, title: String?) throws {
    try repository.addBookmark(url: url, title: title)
}
```

---

## ✅ テスト手順

### 1. ビルドとクリーン
```bash
# クリーンビルド
Cmd+Shift+K
Cmd+B
```

### 2. 無効なURLのテスト

#### テストケース1: 空文字
1. ブックマーク追加画面を開く
2. URL欄を空のまま追加ボタンをタップ
3. **エラーメッセージが表示されることを確認** ✅

#### テストケース2: httpスキーム
1. URL欄に `http://example.com` を入力
2. 追加ボタンをタップ
3. **エラーメッセージが表示されることを確認** ✅
4. **「https://で始まる」というメッセージが含まれることを確認** ✅

#### テストケース3: スキームなし
1. URL欄に `example.com` を入力
2. 追加ボタンをタップ
3. **エラーメッセージが表示されることを確認** ✅

#### テストケース4: 無効な形式
1. URL欄に `not a url` を入力
2. 追加ボタンをタップ
3. **エラーメッセージが表示されることを確認** ✅

#### テストケース5: ホストなし
1. URL欄に `https://` を入力
2. 追加ボタンをタップ
3. **エラーメッセージが表示されることを確認** ✅

### 3. 有効なURLのテスト

#### テストケース6: 正常なURL
1. URL欄に `https://example.com` を入力
2. 追加ボタンをタップ
3. **正常にブックマークが追加されることを確認** ✅
4. **エラーメッセージが表示されないことを確認** ✅

#### テストケース7: パス付きURL
1. URL欄に `https://example.com/path/to/article` を入力
2. 追加ボタンをタップ
3. **正常にブックマークが追加されることを確認** ✅

#### テストケース8: クエリパラメータ付きURL
1. URL欄に `https://example.com/article?id=123` を入力
2. 追加ボタンをタップ
3. **正常にブックマークが追加されることを確認** ✅

### 4. 既存機能への影響確認
- 既存のブックマークが正常に表示される ✅
- ブックマークの削除が正常に動作する ✅
- ブックマークの編集が正常に動作する ✅

### 5. 既存テストの実行
```bash
# ユニットテストとプロパティテストを実行
Cmd+U
```

全テストが通過することを確認してください。

---

## 📝 実装時の注意点

1. **段階的実装**: 
   - まずバリデーションメソッドを追加
   - 次にエラー型を定義
   - その後、既存メソッドに適用
   - 最後にUI側のエラーハンドリング

2. **既存コードの確認**:
   - 既にエラー型が存在する場合は、ケースのみ追加
   - 既にバリデーションが存在する場合は、強化のみ実施

3. **コメント追加**:
   ```swift
   // Task6 User Test Fix: URL安全性の基本バリデーション追加
   private func validateURL(_ urlString: String) -> Bool {
       // ...
   }
   ```

4. **テストコードの追加（推奨）**:
   ```swift
   func testURLValidation() {
       // 有効なURL
       XCTAssertTrue(repository.validateURL("https://example.com"))
       
       // 無効なURL
       XCTAssertFalse(repository.validateURL("http://example.com"))
       XCTAssertFalse(repository.validateURL(""))
       XCTAssertFalse(repository.validateURL("not a url"))
   }
   ```

---

## 🐛 トラブルシューティング

### 問題: ビルドエラー「BookmarkError not found」
- BookmarkErrorの定義場所を確認
- importステートメントが必要な場合は追加

### 問題: 既存のブックマークが追加できない
- バリデーションロジックが厳しすぎる可能性
- httpスキームも許可する場合は条件を緩和

### 問題: エラーメッセージが表示されない
- UI側のエラーハンドリングが正しく実装されているか確認
- showErrorとerrorMessageのStateプロパティが存在するか確認

---

## 🔍 変更箇所チェックリスト

- [ ] validateURLメソッドの追加
- [ ] BookmarkErrorエラー型の定義
- [ ] addBookmarkメソッドへのバリデーション適用
- [ ] ViewModelのエラースロー対応
- [ ] UI側のエラーハンドリング実装
- [ ] エラー表示用Stateプロパティの追加
- [ ] アラート表示の追加
- [ ] テストコードの追加（推奨）

---

## ✅ 完了条件

- [ ] 全てのコード変更が完了
- [ ] クリーンビルドが成功
- [ ] 無効なURLのテストが全て通過
- [ ] 有効なURLのテストが全て通過
- [ ] エラーメッセージが正しく表示される
- [ ] 既存機能への影響なし
- [ ] 既存テストが全て通過

---

## 📊 期待される結果

- ✅ 無効なURLの登録が防止される
- ✅ httpスキームのURLが拒否される
- ✅ 適切なエラーメッセージが表示される
- ✅ httpsスキームのURLのみ登録可能
- ✅ 既存機能に影響がない
- ✅ 全テストが通過する

---

## 🎉 全修正完了後

4つの修正が全て完了したら、以下を実行してください：

1. **最終動作確認**: 全機能を通しでテスト
2. **全テスト実行**: `Cmd+U` で全テスト実行
3. **ビルド確認**: エラー・警告がゼロであることを確認
4. **ユーザーテスト**: 実際に使用して改善を体感

---

**お疲れ様でした！これで Task6 のユーザテスト結果に基づく修正が完了です。**
