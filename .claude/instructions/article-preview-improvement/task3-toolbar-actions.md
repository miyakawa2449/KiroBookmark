# Task 3: ツールバーアクション実装

## 🎯 目的

ツールバーの各ボタンに実際の機能を実装します。メモ追加、引用メモ、TODO追加、お気に入りトグル、詳細画面遷移を動作させます。

---

## 📋 実装するアクション

| ボタン | アクション | 実装難易度 | 優先度 |
|--------|-----------|-----------|--------|
| 📝 メモ | メモ追加モーダル表示 | 低 | 高 |
| 💭 引用 | テキスト選択モード | 中 | 高 |
| ✅ TODO | TODO追加シート表示 | 低 | 中 |
| ⭐ お気に入り | トグル | 低 | 中 |
| 📋 詳細 | 記事詳細画面へ遷移 | 低 | 低 |

---

## 🔧 実装内容

### アクション1: メモ追加モーダル（📝）

#### 実装方法

**ファイル**: `KiroBookmark/Views/ArticleWebView.swift`

既にTask 2で基本実装済みですが、AddMemoSheetが存在しない場合は作成します。

```swift
// ArticleWebView.swift内
.sheet(isPresented: $showMemoSheet) {
    AddMemoSheet(bookmark: bookmark)
}
```

#### AddMemoSheet.swiftの作成（存在しない場合）

**ファイル**: `KiroBookmark/Views/AddMemoSheet.swift`（新規作成）

```swift
import SwiftUI

struct AddMemoSheet: View {
    let bookmark: ArticleBookmark
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddMemoViewModel
    
    @State private var memoContent = ""
    @State private var selectedMemoType: MemoType = .idea
    
    init(bookmark: ArticleBookmark) {
        self.bookmark = bookmark
        _viewModel = StateObject(wrappedValue: AddMemoViewModel(bookmark: bookmark))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // メモ種類選択
                memoTypeSelector
                
                // メモ入力
                TextEditor(text: $memoContent)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                // 文字数カウンター
                HStack {
                    Spacer()
                    Text("\(memoContent.count)/300")
                        .font(.caption)
                        .foregroundColor(memoContent.count > 300 ? .red : .secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("メモを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addMemo()
                    }
                    .disabled(memoContent.isEmpty || memoContent.count > 300)
                }
            }
        }
    }
    
    private var memoTypeSelector: some View {
        HStack(spacing: 12) {
            ForEach(MemoType.allCases, id: \.self) { type in
                MemoTypeButton(
                    type: type,
                    isSelected: selectedMemoType == type,
                    action: { selectedMemoType = type }
                )
            }
        }
    }
    
    private func addMemo() {
        Task {
            do {
                try await viewModel.addMemo(
                    content: memoContent,
                    type: selectedMemoType
                )
                dismiss()
            } catch {
                // エラーハンドリング
                print("Failed to add memo: \(error)")
            }
        }
    }
}

struct MemoTypeButton: View {
    let type: MemoType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type.displayName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? type.color : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// ViewModel
@MainActor
class AddMemoViewModel: ObservableObject {
    private let bookmark: ArticleBookmark
    private let memoRepository: MemoRepository
    
    init(
        bookmark: ArticleBookmark,
        memoRepository: MemoRepository = MemoRepository.shared
    ) {
        self.bookmark = bookmark
        self.memoRepository = memoRepository
    }
    
    func addMemo(content: String, type: MemoType) async throws {
        try await memoRepository.addMemo(
            to: bookmark.id,
            content: content,
            type: type
        )
    }
}
```

#### テスト手順
1. メモボタンをタップ
2. **モーダルが表示される** ✅
3. メモ種類を選択
4. メモを入力
5. 「追加」ボタンをタップ
6. **メモが保存される** ✅
7. **モーダルが閉じる** ✅

---

### アクション2: 引用メモ（💭）

#### 実装方法

**ファイル**: `KiroBookmark/ViewModels/ArticleWebViewModel.swift`

```swift
// ArticleWebViewModel.swift内
@Published var isTextSelectionEnabled: Bool = false
@Published var selectedText: String = ""

func enableTextSelection() {
    isTextSelectionEnabled = true
    // WebViewにテキスト選択モードを通知
    NotificationCenter.default.post(
        name: .enableTextSelection,
        object: nil
    )
}

func createQuoteMemo(selectedText: String) async throws {
    guard !selectedText.isEmpty else { return }
    
    try await memoRepository.addMemo(
        to: bookmark.id,
        content: selectedText,
        type: .quote,
        sourceURL: bookmark.url
    )
}
```

#### WebViewの拡張

**ファイル**: `KiroBookmark/Views/ArticleWebView.swift`

```swift
// WebViewコンポーネントを拡張
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isTextSelectionEnabled: Bool
    var onTextSelected: ((String) -> Void)?
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        
        // テキスト選択を有効化
        webView.configuration.preferences.javaScriptEnabled = true
        
        // 長押しジェスチャーでテキスト選択
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        webView.addGestureRecognizer(longPress)
        
        webView.load(URLRequest(url: url))
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.isTextSelectionEnabled = isTextSelectionEnabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: WebView
        var isTextSelectionEnabled: Bool = false
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard isTextSelectionEnabled else { return }
            
            if gesture.state == .began {
                // テキスト選択処理
                // JavaScriptでテキスト取得
                if let webView = gesture.view as? WKWebView {
                    webView.evaluateJavaScript("window.getSelection().toString()") { result, error in
                        if let text = result as? String, !text.isEmpty {
                            self.parent.onTextSelected?(text)
                        }
                    }
                }
            }
        }
    }
}
```

#### ArticleWebView.swiftの更新

```swift
struct ArticleWebView: View {
    // ... 既存のコード
    
    @State private var showQuoteMemoSheet = false
    @State private var selectedQuoteText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView
            WebView(
                url: bookmark.url,
                isTextSelectionEnabled: $viewModel.isTextSelectionEnabled,
                onTextSelected: { text in
                    selectedQuoteText = text
                    showQuoteMemoSheet = true
                }
            )
            
            // ツールバー
            toolbarView
        }
        // ... 既存のコード
        .sheet(isPresented: $showQuoteMemoSheet) {
            QuoteMemoSheet(
                bookmark: bookmark,
                selectedText: selectedQuoteText
            )
        }
    }
}
```

#### テスト手順
1. 引用ボタンをタップ
2. **テキスト選択モードが有効になる** ✅
3. 記事内のテキストを長押し
4. **テキストが選択される** ✅
5. **引用メモシートが表示される** ✅
6. メモを追加
7. **引用メモが保存される** ✅

---

### アクション3: TODO追加（✅）

#### 実装方法

TODOボタンをタップすると、メモ追加シートが**TODOタイプが事前選択された状態**で表示されます。

**ファイル**: `KiroBookmark/ViewModels/ArticleWebViewModel.swift`

```swift
// ArticleWebViewModel.swift内
@Published var preselectedMemoType: MemoType? = nil

func addQuickTodo() {
    // メモ追加シートをTODOモードで表示
    preselectedMemoType = .todo
    showMemoSheet = true
}
```

#### AddMemoSheet.swiftの拡張

**ファイル**: `KiroBookmark/Views/AddMemoSheet.swift`

AddMemoSheetに事前選択機能を追加します：

```swift
struct AddMemoSheet: View {
    let bookmark: ArticleBookmark
    let preselectedType: MemoType?  // 事前選択されたメモタイプ
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddMemoViewModel
    
    @State private var memoContent = ""
    @State private var selectedMemoType: MemoType
    
    init(bookmark: ArticleBookmark, preselectedType: MemoType? = nil) {
        self.bookmark = bookmark
        self.preselectedType = preselectedType
        _viewModel = StateObject(wrappedValue: AddMemoViewModel(bookmark: bookmark))
        
        // 事前選択がある場合はそれを使用、なければ.idea
        _selectedMemoType = State(initialValue: preselectedType ?? .idea)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // メモ種類選択
                memoTypeSelector
                
                // メモ入力
                TextEditor(text: $memoContent)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                
                // 文字数カウンター
                HStack {
                    Spacer()
                    Text("\(memoContent.count)/300")
                        .font(.caption)
                        .foregroundColor(memoContent.count > 300 ? .red : .secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle(preselectedType == .todo ? "TODOを追加" : "メモを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addMemo()
                    }
                    .disabled(memoContent.isEmpty || memoContent.count > 300)
                }
            }
        }
    }
    
    private var memoTypeSelector: some View {
        HStack(spacing: 12) {
            ForEach(MemoType.allCases, id: \.self) { type in
                MemoTypeButton(
                    type: type,
                    isSelected: selectedMemoType == type,
                    action: { selectedMemoType = type }
                )
            }
        }
    }
    
    private func addMemo() {
        Task {
            do {
                try await viewModel.addMemo(
                    content: memoContent,
                    type: selectedMemoType
                )
                dismiss()
            } catch {
                // エラーハンドリング
                print("Failed to add memo: \(error)")
            }
        }
    }
}
```

#### ArticleWebView.swiftの更新

```swift
struct ArticleWebView: View {
    // ... 既存のコード
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView
            WebView(url: bookmark.url)
            
            // ツールバー
            toolbarView
        }
        // メモ追加シート（事前選択対応）
        .sheet(isPresented: $viewModel.showMemoSheet) {
            AddMemoSheet(
                bookmark: bookmark,
                preselectedType: viewModel.preselectedMemoType
            )
        }
        // ... 既存のコード
    }
}
```

#### ツールバーボタンの実装

```swift
// TODOボタン
ToolbarButton(
    icon: "checkmark.square",
    label: "TODO",
    action: { viewModel.addQuickTodo() }
)
```

#### テスト手順
1. TODOボタンをタップ
2. **メモ追加シートが表示される** ✅
3. **メモタイプが「TODO」に事前選択されている** ✅
4. **ナビゲーションタイトルが「TODOを追加」になっている** ✅
5. TODO内容を入力
6. 「追加」ボタンをタップ
7. **TODOメモが保存される** ✅
8. **シートが閉じる** ✅
9. 記事詳細画面でTODOメモが追加されていることを確認 ✅

---

### アクション4: お気に入りトグル（⭐）

#### 実装方法

Task 2で既に基本実装済みです。追加で視覚的フィードバックを強化します。

**ファイル**: `KiroBookmark/ViewModels/ArticleWebViewModel.swift`

```swift
// ArticleWebViewModel.swift内
func toggleFavorite() {
    // アニメーション付きでトグル
    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
        isFavorite.toggle()
    }
    
    Task {
        do {
            try await bookmarkRepository.updateFavorite(
                bookmarkId: bookmark.id,
                isFavorite: isFavorite
            )
            
            // ハプティックフィードバック
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        } catch {
            print("Failed to toggle favorite: \(error)")
            // エラー時は元に戻す
            withAnimation {
                isFavorite.toggle()
            }
        }
    }
}
```

#### テスト手順
1. お気に入りボタンをタップ
2. **アイコンが塗りつぶしに変わる** ✅
3. **ハプティックフィードバックがある** ✅
4. もう一度タップ
5. **アイコンが元に戻る** ✅
6. 一覧画面でお気に入り状態が反映されている ✅

---

### アクション5: 詳細画面遷移（📋）

#### 実装方法

Task 2で既に基本実装済みです。

**ファイル**: `KiroBookmark/Views/ArticleWebView.swift`

```swift
// ArticleWebView.swift内
@State private var showDetailView = false

// ツールバー内
ToolbarButton(
    icon: "info.circle",
    label: "詳細",
    action: { showDetailView = true }
)

// body内
.navigationDestination(isPresented: $showDetailView) {
    ArticleDetailView(bookmark: bookmark)
}
```

#### テスト手順
1. 詳細ボタンをタップ
2. **記事詳細画面に遷移する** ✅
3. 記事詳細画面でメモ・タグが表示される ✅
4. 戻るボタンでWebView画面に戻る ✅

---

## ✅ 統合テスト

### 全アクションの動作確認

1. **メモ追加**
   - [ ] モーダルが表示される
   - [ ] メモが保存される
   - [ ] 詳細画面で確認できる

2. **引用メモ**
   - [ ] テキスト選択モードが有効になる
   - [ ] テキストが選択できる
   - [ ] 引用メモが保存される

3. **TODO追加**
   - [ ] メモ追加シートが表示される
   - [ ] TODOタイプが事前選択されている
   - [ ] TODOメモが追加される

4. **お気に入り**
   - [ ] トグルが動作する
   - [ ] ハプティックフィードバックがある
   - [ ] 一覧に反映される

5. **詳細画面**
   - [ ] 遷移できる
   - [ ] 戻れる

---

## 📝 実装時の注意点

### 1. エラーハンドリング

全てのアクションで適切なエラーハンドリングを実装：

```swift
do {
    try await someAction()
} catch {
    // ユーザーにエラーを通知
    showError = true
    errorMessage = error.localizedDescription
}
```

### 2. ローディング状態

時間がかかる処理にはローディングインジケーターを表示：

```swift
@Published var isLoading = false

func someAction() async {
    isLoading = true
    defer { isLoading = false }
    
    // 処理
}
```

### 3. ハプティックフィードバック

重要なアクションにはハプティックフィードバックを追加：

```swift
let generator = UIImpactFeedbackGenerator(style: .medium)
generator.impactOccurred()
```

---

## 🐛 トラブルシューティング

### 問題: メモが保存されない
- MemoRepositoryが正しく初期化されているか確認
- Core Dataのコンテキストが正しいか確認

### 問題: テキスト選択ができない
- JavaScriptが有効になっているか確認
- ジェスチャーが正しく設定されているか確認

### 問題: お気に入りが反映されない
- BookmarkRepositoryの更新処理を確認
- Core Dataの保存処理を確認

---

## ✅ 完了条件

- [ ] 全5つのアクション実装完了
- [ ] クリーンビルドが成功
- [ ] 統合テストが全て通過
- [ ] エラーハンドリング実装完了
- [ ] ハプティックフィードバック実装完了
- [ ] 既存機能に影響なし

---

## 📊 期待される結果

- ✅ 全てのツールバーボタンが動作する
- ✅ メモ追加がスムーズ
- ✅ 引用メモが作成できる
- ✅ TODOが素早く追加できる（メモシート経由）
- ✅ お気に入りがトグルできる
- ✅ 詳細画面に遷移できる

---

**この修正が完了したら、Task 4（ロングプレスメニュー）またはTask 5（記事詳細画面の調整）に進んでください。**
