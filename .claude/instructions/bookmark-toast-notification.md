# ブックマーク登録時のトースト通知機能

## 🎯 目的

New Entryで+アイコンをクリックしてブックマークに追加した際、ユーザーに視覚的なフィードバックを提供するトースト通知を実装します。

---

## 📋 背景

現在、+アイコンをクリックしてブックマークに追加しても、画面上に変化がなく、ユーザーは操作が成功したかどうかわかりません。特にWebView画面では何も変化がないため、混乱を招く可能性があります。

### 現在の動作

1. **一覧画面（ArticleCardView）**
   - +アイコンをタップ
   - 記事がリストから消える（視覚的フィードバックあり）
   - しかし、成功メッセージはなし

2. **WebView画面（ArticleWebView）**
   - 「保存」ボタンをタップ
   - データは更新されるが、画面上の変化なし
   - ボタンも残ったまま（視覚的フィードバックなし）

---

## 🎨 要件

### 機能要件

1. **トースト通知の表示**
   - メッセージ: 「ブックマークに登録しました」
   - 表示位置: 画面上部（SafeAreaを考慮）
   - 表示時間: 3秒後に自動で消える
   - 手動で閉じる: ×ボタンまたはタップで即座に閉じられる

2. **表示タイミング**
   - ブックマーク追加処理が成功した直後
   - エラー時は「ブックマークの追加に失敗しました」を表示

3. **アニメーション**
   - 表示: 上からスライドイン
   - 非表示: 上にスライドアウト
   - スムーズなアニメーション（0.3秒程度）

### UI/UX要件

1. **デザイン**
   - 背景色: 成功時は緑系、エラー時は赤系
   - アイコン: 成功時はチェックマーク、エラー時は警告マーク
   - 角丸: 12pt
   - シャドウ: 軽いドロップシャドウ
   - 幅: 画面幅の80%程度（最大320pt）

2. **アクセシビリティ**
   - VoiceOverでメッセージを読み上げ
   - Dynamic Typeに対応
   - ダークモード対応

---

## 🔧 実装内容

### ステップ1: 共通Toastコンポーネントの作成

**新規ファイル**: `KiroBookmark/Views/Components/ToastView.swift`

#### ToastViewの実装

```swift
import SwiftUI

/// Toast notification view
struct ToastView: View {
    let message: String
    let type: ToastType
    let onDismiss: () -> Void
    
    enum ToastType {
        case success
        case error
        case info
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .success: return Color.green
            case .error: return Color.red
            case .info: return Color.blue
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(type.backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

/// Toast modifier for easy integration
struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let type: ToastView.ToastType
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isPresented {
                VStack {
                    ToastView(
                        message: message,
                        type: type,
                        onDismiss: { isPresented = false }
                    )
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Auto dismiss after duration
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
                    .onTapGesture {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    
                    Spacer()
                }
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

extension View {
    /// Show toast notification
    /// - Parameters:
    ///   - isPresented: Binding to control visibility
    ///   - message: Message to display
    ///   - type: Toast type (success, error, info)
    ///   - duration: Auto-dismiss duration (default: 3 seconds)
    func toast(
        isPresented: Binding<Bool>,
        message: String,
        type: ToastView.ToastType = .success,
        duration: TimeInterval = 3.0
    ) -> some View {
        modifier(ToastModifier(
            isPresented: isPresented,
            message: message,
            type: type,
            duration: duration
        ))
    }
}
```

---

### ステップ2: NewEntryViewModelの更新

**ファイル**: `KiroBookmark/ViewModels/NewEntryViewModel.swift`

#### 追加プロパティ

```swift
@MainActor
final class NewEntryViewModel: ObservableObject {
    // 既存のプロパティ...
    
    // ✨ 新規追加
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastView.ToastType = .success
    
    // 既存のコード...
}
```

#### addToBookmarkメソッドの更新

```swift
/// Add article to user bookmarks
func addToBookmark(_ article: ArticleBookmark) {
    do {
        try bookmarkRepository.addToBookmark(article)
        // Remove from current list
        articles.removeAll { $0.id == article.id }
        
        // ✨ 成功トーストを表示
        toastMessage = "ブックマークに登録しました"
        toastType = .success
        showToast = true
        
    } catch {
        errorMessage = "ブックマークの追加に失敗しました"
        
        // ✨ エラートーストを表示
        toastMessage = "ブックマークの追加に失敗しました"
        toastType = .error
        showToast = true
    }
}
```

---

### ステップ3: ArticleWebViewModelの更新

**ファイル**: `KiroBookmark/ViewModels/ArticleWebViewModel.swift`

#### 追加プロパティ

```swift
@MainActor
final class ArticleWebViewModel: ObservableObject {
    // 既存のプロパティ...
    
    // ✨ 新規追加
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastView.ToastType = .success
    
    // 既存のコード...
}
```

#### addToBookmarkメソッドの更新

```swift
/// Add New Entry article to user bookmarks (New Entry/Bookmark separation)
func addToBookmark() throws {
    guard let bookmark = bookmark, !isUserBookmarked else { return }
    
    do {
        try bookmarkRepository.addToBookmark(bookmark)
        
        // Update state
        isUserBookmarked = true
        
        // ✨ 成功トーストを表示
        toastMessage = "ブックマークに登録しました"
        toastType = .success
        showToast = true
        
    } catch {
        // ✨ エラートーストを表示
        toastMessage = "ブックマークの追加に失敗しました"
        toastType = .error
        showToast = true
        
        throw error
    }
}
```

---

### ステップ4: HomeView（New Entryタブ）の更新

**ファイル**: `KiroBookmark/Views/HomeView.swift`

#### New Entryタブビューにtoast modifierを追加

```swift
// New Entryタブの実装部分
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(viewModel.articles) { article in
            ArticleCardView(
                bookmark: article,
                onFavoriteTap: { /* ... */ },
                onCardTap: { /* ... */ },
                onAddBookmark: {
                    viewModel.addToBookmark(article)
                }
            )
        }
    }
    .padding()
}
// ✨ Toast modifierを追加
.toast(
    isPresented: $viewModel.showToast,
    message: viewModel.toastMessage,
    type: viewModel.toastType
)
```

---

### ステップ5: ArticleWebViewの更新

**ファイル**: `KiroBookmark/Views/ArticleWebView.swift`

#### bodyにtoast modifierを追加

```swift
var body: some View {
    VStack(spacing: 0) {
        // WebView with overlays
        ZStack {
            webViewContent
            overlayContent
        }

        #if os(iOS)
        actionToolbar
        #endif
    }
    .navigationTitle(viewModel.pageTitle ?? "記事")
    #if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
    #endif
    .toolbar {
        toolbarContent
    }
    // ✨ Toast modifierを追加
    .toast(
        isPresented: $viewModel.showToast,
        message: viewModel.toastMessage,
        type: viewModel.toastType
    )
    .onAppear {
        // 既存のコード...
    }
    // 既存のsheet modifiers...
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

#### テストケース1: 一覧画面でのブックマーク追加
1. New Entryタブを開く
2. 記事カードの+アイコンをタップ
3. **「ブックマークに登録しました」トーストが画面上部に表示される** ✅
4. **3秒後に自動で消える** ✅
5. **記事がリストから消える** ✅

#### テストケース2: トーストの手動クローズ
1. +アイコンをタップしてトーストを表示
2. トーストの×ボタンをタップ
3. **即座にトーストが消える** ✅

#### テストケース3: トーストをタップして閉じる
1. +アイコンをタップしてトーストを表示
2. トースト全体をタップ
3. **即座にトーストが消える** ✅

#### テストケース4: WebViewでのブックマーク追加
1. New Entry記事をタップしてWebViewを開く
2. ツールバーの「保存」ボタンをタップ
3. **「ブックマークに登録しました」トーストが表示される** ✅
4. **3秒後に自動で消える** ✅
5. **「保存」ボタンが消える（または無効化される）** ✅

#### テストケース5: エラー時のトースト
1. ネットワークエラーやデータベースエラーを発生させる（テスト用）
2. +アイコンをタップ
3. **「ブックマークの追加に失敗しました」が赤色で表示される** ✅
4. **エラーアイコンが表示される** ✅

### 3. UI/UXテスト

#### テストケース6: アニメーション
1. +アイコンをタップ
2. **トーストが上からスムーズにスライドイン** ✅
3. 3秒待つ
4. **トーストが上にスムーズにスライドアウト** ✅

#### テストケース7: 複数回の連続タップ
1. +アイコンを連続で複数回タップ（複数の記事）
2. **トーストが適切に表示される** ✅
3. **前のトーストが消えてから次のトーストが表示される** ✅

#### テストケース8: ダークモード
1. デバイスをダークモードに切り替え
2. +アイコンをタップ
3. **トーストが適切に表示される** ✅
4. **テキストとアイコンが見やすい** ✅

#### テストケース9: Dynamic Type
1. 設定でテキストサイズを変更
2. +アイコンをタップ
3. **トーストのテキストサイズが適切に調整される** ✅
4. **レイアウトが崩れない** ✅

#### テストケース10: VoiceOver
1. VoiceOverを有効化
2. +アイコンをタップ
3. **トーストメッセージが読み上げられる** ✅

---

## 📝 実装時の注意点

### 1. アニメーション

- `.spring()` アニメーションを使用してスムーズな動きを実現
- `response: 0.3, dampingFraction: 0.8` で自然な動きに
- `zIndex(999)` でトーストが最前面に表示されるようにする

### 2. タイミング

- `DispatchQueue.main.asyncAfter` で3秒後の自動クローズを実装
- ユーザーが手動で閉じた場合は、タイマーをキャンセルする必要はない（既に非表示なので）

### 3. 状態管理

- `@Published var showToast` でトーストの表示状態を管理
- `toastMessage` と `toastType` で内容とスタイルを制御
- 複数のトーストを同時に表示しない（1つずつ）

### 4. SafeArea

- `.padding(.top, 8)` でSafeAreaの上部に少し余白を追加
- ノッチやステータスバーと重ならないようにする

### 5. パフォーマンス

- トーストは軽量なコンポーネントなので、パフォーマンスへの影響は最小限
- アニメーションは60fpsを維持

---

## 🎨 デザイン仕様

### カラー

- **成功**: `Color.green` (システムグリーン)
- **エラー**: `Color.red` (システムレッド)
- **情報**: `Color.blue` (システムブルー)
- **テキスト**: `.white` (常に白)

### タイポグラフィ

- **メッセージ**: `.subheadline` + `.fontWeight(.medium)`
- **アイコン**: `.system(size: 20)`
- **閉じるボタン**: `.system(size: 14, weight: .semibold)`

### スペーシング

- **内部パディング**: 水平16pt、垂直12pt
- **外部パディング**: 水平20pt、上部8pt
- **要素間スペース**: 12pt

### シャドウ

- **色**: `.black.opacity(0.2)`
- **半径**: 8pt
- **オフセット**: x: 0, y: 4

---

## 🐛 トラブルシューティング

### 問題: トーストが表示されない
- `showToast` が正しく `true` に設定されているか確認
- `toastMessage` が空でないか確認
- `.toast()` modifierが正しく適用されているか確認

### 問題: トーストが自動で消えない
- `DispatchQueue.main.asyncAfter` が正しく実行されているか確認
- `duration` パラメータが正しく渡されているか確認

### 問題: アニメーションがカクつく
- `.animation()` modifierが正しく適用されているか確認
- `zIndex` が設定されているか確認
- デバイスのパフォーマンスを確認

### 問題: 複数のトーストが重なる
- 前のトーストが消える前に新しいトーストを表示しないようにする
- または、キューシステムを実装する（オプション）

---

## ✅ 完了条件

- [ ] ToastViewコンポーネント実装完了
- [ ] ToastModifierとView extensionの実装完了
- [ ] NewEntryViewModelにトースト機能追加完了
- [ ] ArticleWebViewModelにトースト機能追加完了
- [ ] HomeView（New Entryタブ）にtoast modifier追加完了
- [ ] ArticleWebViewにtoast modifier追加完了
- [ ] クリーンビルドが成功
- [ ] 全テストケースが通過
- [ ] アニメーションがスムーズ
- [ ] ダークモード対応確認
- [ ] VoiceOver対応確認

---

## 📊 期待される結果

- ✅ +アイコンクリック時に「ブックマークに登録しました」が表示される
- ✅ トーストが3秒後に自動で消える
- ✅ ×ボタンまたはタップで手動で閉じられる
- ✅ エラー時は赤色のトーストが表示される
- ✅ アニメーションがスムーズで自然
- ✅ ダークモードで適切に表示される
- ✅ VoiceOverで読み上げられる

---

## 🚀 今後の拡張案（オプション）

### 1. トーストキューシステム
複数のトーストを順番に表示するキューシステムを実装

### 2. カスタムアクション
トーストにアクションボタンを追加（例: 「元に戻す」）

### 3. 位置のカスタマイズ
トーストの表示位置を上部/下部/中央から選択可能に

### 4. プログレスバー
自動クローズまでの残り時間を視覚化

### 5. ハプティックフィードバック
トースト表示時に軽い振動フィードバック

---

**この実装が完了したら、ユーザーはブックマーク追加操作に対する明確なフィードバックを得られるようになります。**
