# Task6 修正1: サイドメニューのスワイプ感度改善

## 🎯 修正の目的

ホームで右スワイプしてもサイドバーが表示されにくい問題を解決します。反応エリアと閾値を緩和して、ユーザーがより自然にスワイプできるようにします。

---

## 🔧 修正内容

**ファイル**: `KiroBookmark/Views/HomeView.swift`  
**対象**: `swipeGesture` 計算プロパティ内の条件式

### 変更箇所

**変更前**:
```swift
// Open menu: swipe right from left edge or with strong velocity
if !viewModel.isSideMenuOpen {
    // Must start near left edge (within 80pt) AND swipe right significantly
    if startX < 80 && (translation > 100 || velocity > 300) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.openSideMenu()
        }
    }
}
```

**変更後**:
```swift
// Open menu: swipe right from left edge or with strong velocity
if !viewModel.isSideMenuOpen {
    // Must start near left edge (within 120pt) AND swipe right significantly
    if startX < 120 && (translation > 80 || velocity > 200) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            viewModel.openSideMenu()
        }
    }
}
```

### 変更点の詳細

| パラメータ | 変更前 | 変更後 | 変更率 |
|----------|--------|--------|--------|
| 反応エリア（startX） | 80pt | 120pt | +50% |
| スワイプ距離（translation） | 100pt | 80pt | -20% |
| 速度閾値（velocity） | 300 | 200 | -33% |

---

## ✅ テスト手順

### 1. ビルドとクリーン
```bash
# クリーンビルド
Cmd+Shift+K
Cmd+B
```

### 2. 基本動作テスト
1. アプリを起動してホーム画面を表示
2. 画面左端（左から120pt以内）から右にスワイプ
3. サイドメニューがスムーズに開くことを確認
4. 左にスワイプまたはメニュー外をタップして閉じる

### 3. エッジケーステスト
- **左端からのスワイプ**: 画面の一番左端から開始 → メニューが開く ✅
- **120pt付近からのスワイプ**: 左から約120pt地点から開始 → メニューが開く ✅
- **中央からのスワイプ**: 画面中央から開始 → メニューが開かない ✅
- **短いスワイプ**: 左端から50ptだけスワイプ → メニューが開かない ✅
- **速いスワイプ**: 左端から速くスワイプ（velocity > 200） → メニューが開く ✅

### 4. 既存機能への影響確認
- ブックマークリストの縦スクロールが正常に動作する ✅
- カードタップで詳細画面に遷移できる ✅
- お気に入りボタンが正常に動作する ✅

### 5. 既存テストの実行
```bash
# ユニットテストとプロパティテストを実行
Cmd+U
```

全テストが通過することを確認してください。

---

## 📝 実装時の注意点

1. **コメントの更新**: 変更箇所のコメントも更新（80pt → 120pt）
2. **他の条件は変更しない**: メニューを閉じる条件（translation < -50）は変更しない
3. **アニメーション設定は維持**: `spring(response: 0.3, dampingFraction: 0.8)` はそのまま

---

## 🐛 トラブルシューティング

### 問題: メニューが開きすぎる
- 反応エリアを110ptに調整してみる

### 問題: まだ開きにくい
- 速度閾値を150に下げてみる

### 問題: 縦スクロールと干渉する
- `coordinateSpace: .global` が正しく設定されているか確認

---

## ✅ 完了条件

- [ ] コードの変更が完了
- [ ] クリーンビルドが成功
- [ ] 基本動作テストが全て通過
- [ ] エッジケーステストが全て通過
- [ ] 既存機能への影響なし
- [ ] 既存テストが全て通過

---

## 📊 期待される結果

- ✅ サイドメニューのスワイプ操作が快適になる
- ✅ 左端からのスワイプが認識されやすくなる
- ✅ 既存機能に影響がない
- ✅ 全テストが通過する

---

**この修正が完了したら、次の修正（Fix2: ブックマークボタン削除）に進んでください。**
