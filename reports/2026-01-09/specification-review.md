# 仕様書類の見直し提案

**日付**: 2026年1月9日  
**作業**: Swift並行処理警告修正後の仕様書レビュー

---

## 見直しが必要な項目

### 1. README.md - 既知の制限事項セクション ✅ 更新推奨

**現在の記載**:
```markdown
### 既知の警告
- Swift 6 Concurrency警告（動作には影響なし）
  - MainActor isolated initializer warnings
```

**推奨される更新**:
```markdown
### 既知の警告
- ~~Swift 6 Concurrency警告（動作には影響なし）~~ ✅ 解決済み（2026-01-09）
  - ~~MainActor isolated initializer warnings~~
  - すべての並行処理警告を解決し、Swift 6への移行準備が完了
```

**理由**: 警告がすべて解消されたため、この記載は不正確になっています。

---

### 2. README.md - 技術スタック ✅ 更新推奨

**現在の記載**:
```markdown
| 項目 | 技術 |
|------|------|
| UI | SwiftUI (iOS 17.0+) |
| 言語 | Swift 5.9+ |
```

**推奨される更新**:
```markdown
| 項目 | 技術 |
|------|------|
| UI | SwiftUI (iOS 17.0+) |
| 言語 | Swift 5.9+ (Swift 6 Concurrency対応済み) |
| 並行処理 | @MainActor, async/await |
```

**理由**: Swift 6の並行処理機能に対応したことを明記すべきです。

---

### 3. CLAUDE.md - Coding Standards ✅ 追加推奨

**現在の記載**: 並行処理に関する規約がない

**推奨される追加**:
```markdown
### Swift Concurrency Best Practices
- **@MainActor**: UIに関連するクラス・プロパティに必須
- **Repository/Service初期化**: 2段階初期化パターンを使用
  ```swift
  // テスト用: 依存性注入可能
  init(dependency: DependencyProtocol) { }
  
  // 本番用: デフォルト実装
  @MainActor
  convenience init() {
      self.init(dependency: DefaultDependency())
  }
  ```
- **Timerクロージャ**: `guard let self`を使用
  ```swift
  Timer.scheduledTimer(...) { [weak self] _ in
      guard let self = self else { return }
      Task { @MainActor in
          self.method()
      }
  }
  ```
- **テストメソッド**: Core Dataを使用する場合は`@MainActor`を追加
```

**理由**: 今後の開発で同じパターンを維持するため、規約として明文化すべきです。

---

### 4. .claude/instructions/README.md ✅ 追加推奨

**推奨される追加**: 新しいタスクフォルダの作成

```markdown
## 📂 ディレクトリ構造

```
.claude/instructions/
├── README.md
├── concurrency-fixes/         # 🆕 Swift並行処理警告修正
│   └── index.md
├── task6-fixes/
│   └── ...
└── archived/
    └── ...
```
```

**新規ファイル**: `.claude/instructions/concurrency-fixes/index.md`

```markdown
# Swift並行処理警告修正

## 概要
Swift 6の並行処理機能に対応するため、31件の警告を解決しました。

## 実施内容
1. PersistenceControllerの@MainActor隔離
2. Repository/Serviceの2段階初期化パターン
3. ViewModelの初期化修正
4. 未使用変数の削除
5. Selfキャプチャの修正
6. テストコードの@MainActor対応

## 成果
- ✅ 警告: 31件 → 0件
- ✅ テスト: 90個すべて成功
- ✅ Swift 6への移行準備完了

## 詳細レポート
- `reports/2026-01-09/concurrency-warnings-fix.md`
- `reports/2026-01-09/fix-work-report.md`

## 適用パターン
今後の開発では、以下のパターンを使用してください：

### Repository/Service初期化
\`\`\`swift
final class BookmarkRepository: BookmarkRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    @MainActor
    convenience init() {
        self.init(context: PersistenceController.shared.viewContext)
    }
}
\`\`\`

### ViewModel初期化
\`\`\`swift
@MainActor
final class AddBookmarkViewModel: ObservableObject {
    init(
        bookmarkRepository: BookmarkRepositoryProtocol,
        // ... 他の依存関係
    ) {
        // 初期化処理
    }
    
    @MainActor
    convenience init() {
        self.init(
            bookmarkRepository: BookmarkRepository(),
            // ... デフォルト実装
        )
    }
}
\`\`\`

### Timerクロージャ
\`\`\`swift
Timer.scheduledTimer(...) { [weak self] _ in
    guard let self = self else { return }
    Task { @MainActor in
        self.method()
    }
}
\`\`\`

## 完了日
2026年1月9日
```

**理由**: 今回の修正内容を実装指示書として記録し、今後の参照資料とすべきです。

---

### 5. README.md - プロジェクト構造 ⚠️ 更新検討

**現在の記載**: ファイル構造の説明にコメントなし

**推奨される更新**: 各ファイルに並行処理対応の注記を追加

```markdown
├── Core/
│   └── PersistenceController.swift    # @MainActor対応済み
├── Repositories/
│   ├── BookmarkRepository.swift       # 2段階初期化パターン
│   ├── FavoriteBlogRepository.swift   # 2段階初期化パターン
│   ├── MemoRepository.swift           # 2段階初期化パターン
│   └── TagRepository.swift            # 2段階初期化パターン
├── Services/
│   ├── RSSService.swift               # 2段階初期化パターン
│   ├── NotificationService.swift      # 2段階初期化パターン
│   └── BackgroundRefreshService.swift # 2段階初期化パターン
```

**理由**: 新しい開発者が参加した際に、どのファイルが並行処理対応済みかわかりやすくなります。

---

### 6. CLAUDE.md - 禁止事項 ✅ 追加推奨

**推奨される追加**:
```markdown
## 禁止事項
- ユーザーの指示なしに勝手に**Git操作**しない
- 設計書・承認なしに**新機能を実装**しない
- 既存の**アーキテクチャを無断で変更**しない
- **Phase 1B の機能**を Phase 1A で実装しない
- **機密情報**（APIキー等）をコードに埋め込まない
- **Core Data モデル**を無断で変更しない
- **並行処理パターン**を無視した実装をしない  # 🆕 追加
```

**理由**: 今後の開発で並行処理のベストプラクティスを維持するため。

---

## 更新の優先度

### 🔴 高優先度（すぐに更新すべき）

1. **README.md - 既知の制限事項**: 不正確な情報を修正
2. **CLAUDE.md - Coding Standards**: 並行処理の規約を追加

### 🟡 中優先度（近日中に更新）

3. **README.md - 技術スタック**: Swift 6対応を明記
4. **.claude/instructions/**: 修正内容を実装指示書として記録

### 🟢 低優先度（余裕があれば更新）

5. **README.md - プロジェクト構造**: 並行処理対応の注記
6. **CLAUDE.md - 禁止事項**: 並行処理パターンの遵守を追加

---

## 更新不要な項目

以下の項目は今回の修正の影響を受けないため、更新不要です：

- ✅ **データモデル**: 変更なし
- ✅ **機能一覧**: 変更なし
- ✅ **開発状況**: 変更なし
- ✅ **セットアップ手順**: 変更なし
- ✅ **テスト手順**: 変更なし（テスト数は維持）
- ✅ **ライセンス**: 変更なし

---

## 推奨される更新手順

### ステップ1: 高優先度の更新（今すぐ）

```bash
# README.mdの既知の制限事項を更新
# CLAUDE.mdのCoding Standardsに並行処理の規約を追加
```

### ステップ2: 中優先度の更新（今週中）

```bash
# README.mdの技術スタックを更新
# .claude/instructions/concurrency-fixes/を作成
```

### ステップ3: 低優先度の更新（余裕があれば）

```bash
# README.mdのプロジェクト構造に注記を追加
# CLAUDE.mdの禁止事項を更新
```

---

## まとめ

今回の並行処理警告修正により、以下の仕様書類の更新が推奨されます：

| ドキュメント | セクション | 優先度 | 理由 |
|-------------|-----------|--------|------|
| README.md | 既知の制限事項 | 🔴 高 | 不正確な情報の修正 |
| CLAUDE.md | Coding Standards | 🔴 高 | 規約の明文化 |
| README.md | 技術スタック | 🟡 中 | Swift 6対応の明記 |
| .claude/instructions/ | 新規フォルダ | 🟡 中 | 修正内容の記録 |
| README.md | プロジェクト構造 | 🟢 低 | 可読性の向上 |
| CLAUDE.md | 禁止事項 | 🟢 低 | パターン遵守の強制 |

**推奨アクション**: 高優先度の2項目を今すぐ更新し、中優先度の2項目を今週中に更新することをお勧めします。

---

**レポート作成日**: 2026年1月9日  
**作成者**: Kiro AI Assistant
