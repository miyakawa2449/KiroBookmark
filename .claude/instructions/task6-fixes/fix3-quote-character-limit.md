# Task6 修正3: 引用メモの文字数制限を300文字に緩和

## 🎯 修正の目的

引用メモの文字数制限を140文字から300文字に緩和します。より長い引用を可能にすることで、ユーザーの利便性を向上させます。

---

## 🔍 事前調査

引用メモ機能を実装しているファイルを特定してください。

### 調査対象ファイル
1. `KiroBookmark/Views/ArticleDetailView.swift`（WebView + テキスト選択機能）
2. `KiroBookmark/ViewModels/ArticleDetailViewModel.swift`
3. `KiroBookmark/Managers/MemoManager.swift`
4. `KiroBookmark/Repositories/MemoRepository.swift`

### 検索キーワード
- `140`
- `maxQuoteLength`
- `characterLimit`
- `quoteMemo`
- `selectedText`

---

## 🔧 修正内容

### ステップ1: 定数の変更

引用メモの文字数制限定数を探して変更します。

#### パターンA: 定数として定義されている場合

**変更前**:
```swift
private let maxQuoteLength = 140
```

**変更後**:
```swift
private let maxQuoteLength = 300
```

---

#### パターンB: 直接数値で記述されている場合

**変更前**:
```swift
if selectedText.count > 140 {
    // エラー処理
}
```

**変更後**:
```swift
if selectedText.count > 300 {
    // エラー処理
}
```

**推奨**: 定数として定義し直す
```swift
private let maxQuoteLength = 300

// 使用箇所
if selectedText.count > maxQuoteLength {
    // エラー処理
}
```

---

### ステップ2: バリデーションロジックの更新

引用メモ作成時のバリデーション処理を確認し、300文字制限が正しく適用されていることを確認します。

**確認例**:
```swift
func validateQuoteMemo(_ text: String) -> Bool {
    return text.count <= 300  // 140 から 300 に変更されていることを確認
}
```

または

```swift
func createQuoteMemo(selectedText: String, sourceURL: String) throws {
    guard selectedText.count <= 300 else {
        throw MemoError.quoteTooLong
    }
    // メモ作成処理
}
```

---

### ステップ3: UIメッセージの更新

ユーザーに表示されるエラーメッセージやヒントテキストを更新します。

#### エラーメッセージの更新

**変更前**:
```swift
case quoteTooLong:
    return "引用は140文字以内で入力してください"
```

**変更後**:
```swift
case quoteTooLong:
    return "引用は300文字以内で入力してください"
```

---

#### ヒントテキストの更新

**変更前**:
```swift
Text("引用は140文字まで")
    .font(.caption)
    .foregroundColor(.secondary)
```

**変更後**:
```swift
Text("引用は300文字まで")
    .font(.caption)
    .foregroundColor(.secondary)
```

---

#### 文字数カウンター表示の更新（存在する場合）

**変更前**:
```swift
Text("\(selectedText.count)/140")
    .foregroundColor(selectedText.count > 140 ? .red : .secondary)
```

**変更後**:
```swift
Text("\(selectedText.count)/300")
    .foregroundColor(selectedText.count > 300 ? .red : .secondary)
```

---

### ステップ4: テストコードの更新（存在する場合）

プロパティテストやユニットテストで140文字を使用している箇所を更新します。

**ファイル**: `KiroBookmarkTests/PropertyTests.swift` または類似のテストファイル

**変更前**:
```swift
// Property 25: 引用メモの完全性
func testQuoteMemoCompleteness() {
    property("Quote memo should include text and URL") <- forAll { (text: String) in
        let limitedText = String(text.prefix(140))
        // テストロジック
    }
}
```

**変更後**:
```swift
// Property 25: 引用メモの完全性
func testQuoteMemoCompleteness() {
    property("Quote memo should include text and URL") <- forAll { (text: String) in
        let limitedText = String(text.prefix(300))
        // テストロジック
    }
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

### 2. 基本動作テスト
1. アプリを起動してブックマーク詳細画面を開く
2. WebView内でテキストを選択
3. 引用メモ作成機能を起動

### 3. 文字数制限テスト

#### テストケース1: 300文字以内の引用
1. 200文字程度のテキストを選択
2. 引用メモを作成
3. **正常に作成できることを確認** ✅

#### テストケース2: ちょうど300文字の引用
1. 300文字のテキストを選択
2. 引用メモを作成
3. **正常に作成できることを確認** ✅

#### テストケース3: 301文字以上の引用
1. 350文字のテキストを選択
2. 引用メモを作成しようとする
3. **エラーメッセージが表示されることを確認** ✅
4. **エラーメッセージが「300文字以内」と表示されることを確認** ✅

#### テストケース4: 文字数カウンター（存在する場合）
1. テキストを選択
2. 文字数カウンターが表示される
3. **「X/300」の形式で表示されることを確認** ✅
4. **300文字を超えると赤色で表示されることを確認** ✅

### 4. 既存機能への影響確認
- 通常のメモ作成が正常に動作する ✅
- 引用メモの保存・読み込みが正常に動作する ✅
- メモ一覧表示が正常に動作する ✅

### 5. 既存テストの実行
```bash
# ユニットテストとプロパティテストを実行
Cmd+U
```

全テストが通過することを確認してください。

---

## 📝 実装時の注意点

1. **全ての箇所を更新**: 140が出現する全ての箇所を300に変更
2. **定数化を推奨**: マジックナンバーを避け、定数として定義
3. **コメント追加**: 変更理由をコメントで残す
   ```swift
   // Task6 User Test Fix: 引用メモの文字数制限を140文字から300文字に緩和
   private let maxQuoteLength = 300
   ```
4. **英語メッセージも更新**: 英語のエラーメッセージがある場合も更新

---

## 🐛 トラブルシューティング

### 問題: 140が見つからない
- コード内で直接数値比較していない可能性
- バリデーションロジックが別の方法で実装されている可能性
- 検索範囲を広げて再確認

### 問題: テストが失敗する
- テストコード内の140も300に更新されているか確認
- プロパティテストのテストデータ生成ロジックを確認

### 問題: エラーメッセージが更新されない
- ローカライズファイル（Localizable.strings）に定義されている可能性
- エラーメッセージの定義場所を再確認

---

## 🔍 変更箇所チェックリスト

- [ ] 定数定義の変更（140 → 300）
- [ ] バリデーションロジックの変更
- [ ] エラーメッセージの変更（日本語）
- [ ] エラーメッセージの変更（英語、存在する場合）
- [ ] ヒントテキストの変更
- [ ] 文字数カウンター表示の変更（存在する場合）
- [ ] テストコードの変更（存在する場合）
- [ ] コメントの追加

---

## ✅ 完了条件

- [ ] 全ての140を300に変更完了
- [ ] クリーンビルドが成功
- [ ] 基本動作テストが全て通過
- [ ] 文字数制限テストが全て通過
- [ ] エラーメッセージが正しく表示される
- [ ] 既存機能への影響なし
- [ ] 既存テストが全て通過

---

## 📊 期待される結果

- ✅ 300文字までの引用が可能になる
- ✅ 301文字以上の引用がエラーになる
- ✅ エラーメッセージが「300文字以内」と表示される
- ✅ 既存機能に影響がない
- ✅ 全テストが通過する

---

**この修正が完了したら、次の修正（Fix4: URL安全性バリデーション）に進んでください。**
