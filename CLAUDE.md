# CLAUDE.md - Project Context & Rules

## Memory Bank & Guidelines
このファイルは、Bookmark Manager プロジェクトにおけるAI（Claude Code）の振る舞い、ルール、文脈を定義するものである。
セッション開始時、および判断に迷った際は必ずこのファイルを参照すること。

---

## 言語設定
すべての応答は**日本語**で行うこと。
- ユーザーとの会話・説明は日本語
- コード内のコメントは英語（Swift標準に従う）
- ドキュメントは日本語

---

## ユーザープロファイル
- **名前**: 剛（つよし）
- **専門**: SE/PM、開発上流工程（設計・要求定義）のエキスパート
- **スキルレベル**: 開発初心者（コーディング経験は少ない）
- **学習目標**: SwiftUI/Swift などの最新技術を用いた iOS/Mac アプリ開発

### 対応方針
- 技術的な概念は**分かりやすく解説**すること
- 開発スキルを**教育・育成**する姿勢で対応
- 最新技術については**Web検索やMCPサーバー**で最新ドキュメントを参照すること

---

## プロジェクト概要
- **プロジェクト名**: Bookmark Manager
- **技術スタック**: Swift / SwiftUI / Core Data / iOS
- **目的**: AIエンジニア向けの技術ブログ管理ツール（iPhone MVP）
- **Phase 1A**: 1週間MVP（ブックマーク・メモ・タグの基本機能のみ）
- **Phase 1B**: 拡張機能（RSS、検索、エクスポート等）
- **リポジトリ**: ローカル開発

---

## Custom Commands (Workflow)

> **基本方針**: 完全自動化を基本とし、手動コマンドは緊急時・例外時のみ使用
> **実装方法**: 下記コマンドは `.claude/commands/` ディレクトリに
> Markdownファイルとして配置すること。
> 例: `.claude/commands/session-start.md`

### 自動実行コマンド（通常フロー）

### `session-start`
- **実行**: 自動（セッション開始時）
- **目的**: セッション開始時のコンテキスト復帰
- **動作**:
  1. `.kiro/specs/bookmark-manager/tasks.md` を読み込み、現在のフェーズと進捗を確認する。
  2. `reports/` の直近1日分のレポートを読み込む。
  3. 「準備完了。現在のフェーズは Phase 1A（1週間MVP）です。指示を待機します。」と応答する。

### 緊急時手動コマンド（例外対応）

### `add-report`
- **実行**: 手動（緊急時のみ）
- **用途**: 自動レポート生成が失敗した場合、特別なレポートが必要な場合
- **目的**: セッション終了時の進捗記録
- **動作**:
  1. 今回のセッションでの変更点（ファイル数、主な実装内容）を要約する。
  2. 次回のセッションでやるべき「Next Action」を列挙する。
  3. `reports/YYYY-MM-DD/` フォルダに連番でレポートを作成する。
- **出力形式**:
  ```
  reports/
  ├── 2025-01-15/
  │   ├── 1st.md
  │   ├── 2nd.md
  │   └── 3rd.md
  └── 2025-01-16/
      └── 1st.md
  ```

### `check-quality`
- **実行**: 自動（コード変更時）+ 手動（必要時）
- **目的**: コード品質の自動チェック
- **動作**:
  1. 直近で変更されたSwiftファイルをスキャンする。
  2. 下記の「Coding Standards」に違反していないかチェックする。
  3. 違反がある場合、修正案を提示する。

---

## 進捗管理（Progress Tracking）

### 自動進捗管理（基本フロー）

#### 自動進捗検知
- **Git連携**: Commit メッセージから自動的にタスク完了を検知
- **検知パターン**:
  - `[Task 1.1 completed]` → Task 1.1 を完了としてマーク
  - `[Task 1.2 in-progress]` → Task 1.2 を進行中としてマーク
  - `[Task 1.3 blocked]` → Task 1.3 をブロック中としてマーク

#### tasks.md 自動更新ルール
- タスク完了時: `- [ ] Task 1.1` → `- [x] Task 1.1`
- 進行中: `- [ ] Task 1.2` → `- [ ] Task 1.2` (進行中)
- ブロック中: `- [ ] Task 1.3` → `- [ ] Task 1.3` (ブロック中)

#### 自動レポート生成
- **日次レポート**: `reports/YYYY-MM-DD/standup.md`（毎日自動生成）
- **セッションレポート**: `reports/YYYY-MM-DD/Nth.md`（セッション終了時）
- **週次サマリー**: `reports/weekly/YYYY-WXX.md`（毎週金曜日）

### 緊急時手動コマンド（例外対応）

#### `update-progress`
- **実行**: 手動（緊急時のみ）
- **用途**: Git commitを忘れた場合、自動検知が失敗した場合
- **目的**: タスク完了時の進捗手動更新
- **動作**:
  1. 完了したタスクの内容を確認する。
  2. `.kiro/specs/bookmark-manager/tasks.md` の該当タスクにマークを追加する。
  3. Git commit メッセージに `[Task X.Y completed]` を含める。
  4. 次のタスクを提示する。
- **使用タイミング**: 自動検知が失敗した場合のみ

#### `daily-standup`
- **実行**: 手動（緊急時のみ）
- **用途**: 自動レポート生成が失敗した場合、特別なサマリーが必要な場合
- **目的**: 日次進捗サマリーの手動生成
- **動作**:
  1. 当日の Git commit ログを解析する。
  2. 完了したタスク、進行中のタスク、ブロッカーを抽出する。
  3. `reports/YYYY-MM-DD/standup.md` に下記形式で出力する:
     - **完了**: 今日完了したタスク
     - **進行中**: 現在作業中のタスク
     - **次回**: 明日やるべきタスク
     - **ブロッカー**: 問題・課題
- **使用タイミング**: 自動生成が失敗した場合のみ

### 基本方針
- **通常時**: 全て自動化（Git commit → 自動検知 → 自動更新）
- **緊急時**: 手動コマンドで補正
- **例外時**: デモ前、週次レビュー等で特別なレポートが必要な場合

---

## Coding Standards (Quality Control)

### General
- **DRY原則**: 同じロジックを2回書かない。共通化できないか常に検討せよ。
- **KISS原則**: 複雑な実装より、単純で読みやすい実装を優先せよ。
- **Swift標準**: Swift API Design Guidelines に従う。

### Constraints (Strict)

| 項目 | 制約 | 超過時の対応 |
|------|------|--------------|
| メソッド行数 | 最大20行 | プライベートメソッドに切り出し |
| クラス行数 | 最大150行 | 責務分割（Extension/Protocol） |
| View行数 | 最大100行 | ViewComponent に分割 |

### 命名規則
- **変数名**: キャメルケース（`bookmarkId`）
- **クラス名**: パスカルケース（`BookmarkManager`）
- **プロトコル名**: `Protocol` サフィックス（`BookmarkManagerProtocol`）
- **禁止**: 意味のない名前（`temp`, `data`, `a`）

### SwiftUI Best Practices
- **@State**: View内の一時的な状態のみ
- **@StateObject**: ViewModelの初期化時のみ
- **@ObservedObject**: 親から渡されるViewModelに使用
- **プレビュー**: 全てのViewに `#Preview` を追加

### Refactoring Policy
- Phase 1A（1週間MVP）では、冗長性を許容する。
- ただし、実装後に必ず `// TODO: Refactor later (Date: YYYY-MM-DD)` コメントを残すこと。

---

## Architecture & Context
- **Architecture**: MVVM + Repository Pattern
- **UI Framework**: SwiftUI
- **Data Layer**: Core Data + Repository Pattern
- **Testing**: SwiftCheck (Property-Based Testing) + XCTest
- **Key Philosophy**: 「実装」はAIが、「設計」は人間が行う。

### Core Data Models
- **ArticleBookmark**: 記事ブックマーク
- **TweetMemo**: Twitter風メモ
- **Tag**: タグ管理

### Key Services
- **BookmarkManager**: ブックマーク管理
- **MemoManager**: メモ管理
- **TagManager**: タグ管理

---

## 禁止事項
- ユーザーの指示なしに勝手に**Git操作**しない
- 設計書・承認なしに**新機能を実装**しない
- 既存の**アーキテクチャを無断で変更**しない
- **Phase 1B の機能**を Phase 1A で実装しない
- **機密情報**（APIキー等）をコードに埋め込まない
- **Core Data モデル**を無断で変更しない

---

## Claude Code運用ルール

### コンテキスト保存（記憶喪失対策）
- 会話が長引くと**スレッドが圧縮要約**され、重要な情報が失われる可能性がある
- 自動圧縮がかかる前に、**定期的に重要な点をマークダウンで保存・更新**すること
- 保存先: プロジェクトディレクトリ内（例: `reports/` や `docs/`）

### 機密情報の取り扱い
- 開発中に生成するドキュメントに**APIキーなどの機密情報**を記載する場合:
  - 必ず該当ファイルを **`.gitignore` に追加**すること
  - 機密情報を含むファイルは `secrets/` や `private/` ディレクトリに配置を推奨

### コミットメッセージ
- **1行の日本語でシンプル**に記述
- 例: `ブックマーク追加機能を実装`、`タグ管理のバグを修正`

### 通知設定（Hooks）
- 処理完了・中断時の音声通知は **`.claude/settings.local.json`** で設定済み
- 設定変更は `/hooks` コマンドで対話的に編集可能
- 利用可能なイベント:
  - `Stop`: メイン処理完了時
  - `Notification`: 通知送信時
  - `SubagentStop`: サブエージェント完了時

---

## 参照ドキュメント

### ベース仕様（Kiro管理）
| 用途 | ファイルパス |
|------|-------------|
| 要件定義 | `.kiro/specs/bookmark-manager/requirements.md` |
| 設計書 | `.kiro/specs/bookmark-manager/design.md` |
| タスク計画 | `.kiro/specs/bookmark-manager/tasks.md` |

### 詳細仕様（ベースから派生）
| 用途 | ファイルパス | 元となるドキュメント |
|------|-------------|---------------------|
| ユースケース | `.kiro/specs/bookmark-manager/usecase.md` | requirements.md |
| 画面設計 | `.kiro/specs/bookmark-manager/screen-design.md` | design.md |

### 運用ドキュメント
| 用途 | ファイルパス |
|------|-------------|
| セッションレポート | `reports/YYYY-MM-DD/*.md` |

### 参照ルール
- **設計方針**: design.md → screen-design.md の順で確認
- **要件確認**: requirements.md → usecase.md の順で確認
- **タスク**: tasks.md に従って実装
- **仕様変更時**: ベースドキュメントを先に更新し、派生ドキュメントに反映

---

## Skills
`~/.claude/skills/` および `.claude/skills/` を自動参照

### Skills（ファイル構成）
```
~/.claude/skills/              # 個人用（全プロジェクト共通）
├── swift-build/
│   └── SKILL.md
└── ios-security/
    └── SKILL.md

your-project/.claude/skills/   # プロジェクト固有
├── swiftui-review/
│   └── SKILL.md
├── appstore-prep/
│   └── SKILL.md
├── macos-security/
│   └── SKILL.md
└── mac-appstore-prep/
    └── SKILL.md
```

---

## 作業順序のおすすめ
```
1. Claude Code側のSkillsを先に作成
   ↓
2. 動作確認（「セキュリティチェックして」等で起動するか）
   ↓
3. 動いたSkillの情報をKiroのdesign.mdに反映
   ↓
4. CLAUDE.mdにKiro参照を追加
```

---

## Phase 1A (1週間MVP) 制約
- **実装対象**: ブックマーク・メモ・タグの基本機能のみ
- **除外機能**: RSS、検索、エクスポート、関連記事提案、ドメイン整理、読書進捗管理
- **UI**: シンプルなリスト表示（サムネイル表示なし）
- **メモ**: テキストのみ（写真添付なし）
- **データ**: Core Data ローカル保存のみ

---

## 開発フロー

### 実装順序（Phase 1A）
1. **Task 1**: プロジェクト初期設定とCore Dataセットアップ
2. **Task 2**: ブックマーク管理機能（CRUD + UI）
3. **Task 3**: Twitter風メモ機能（テキストのみ）
4. **Task 4**: タグ管理機能（基本機能のみ）
5. **Task 5**: メイン画面とナビゲーション
6. **Task 6**: 1週間MVP完成確認

### Git Workflow
- **ブランチ戦略**: `main` ブランチで直接開発（MVP期間中）
- **コミットメッセージ**: 1行の日本語でシンプルに（例: `ブックマーク追加機能を実装`）
- **進捗マーク**: `[Task X.Y completed]` で自動進捗更新（必要時のみ末尾に追加）
- **テスト**: 各タスク完了時に必ずテスト実行

### 基本フロー
1. **Task確認**: `tasks.md` で現在のタスクを確認
2. **実装**: Swift/SwiftUI でコード実装
3. **テスト**: プロパティベーステスト + ユニットテスト
4. **確認**: 動作確認後、次のタスクへ

---

*このファイルは Bookmark Manager プロジェクトの開発効率化のためのものです。*
