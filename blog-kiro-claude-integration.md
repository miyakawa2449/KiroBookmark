# Kiro と Claude Code の併用で実現する最強の開発環境

## はじめに

AI開発アシスタントの世界で、2つの強力なツールが登場しています。**Kiro**（Anthropic製の新しいIDE統合AI）と**Claude Code**（従来のClaude Desktop + MCP）です。

この記事では、実際のSwiftUIプロジェクトで両者を併用し、それぞれの強みを活かした開発フローを構築した経験を共有します。

## なぜ併用するのか？

### Kiro の強み
- **Spec駆動開発**: 要件定義→設計→タスク管理の構造化されたワークフロー
- **プロジェクト全体の俯瞰**: アーキテクチャレベルの意思決定
- **長期的なコンテキスト管理**: セッションをまたいだ進捗管理

### Claude Code の強み
- **即座の実装支援**: コード修正やデバッグの迅速な対応
- **Skills による専門知識**: ビルド、テスト、セキュリティチェックなどの定型作業
- **MCP による外部連携**: GitHub、ファイルシステム、思考プロセスの可視化

### 役割分担の基本方針
```
Kiro     → 「設計者・プロジェクトマネージャー」
Claude   → 「実装者・専門技術者」
```

## ディレクトリ構造と設定ファイルの連携

実際のプロジェクト構造はこのようになっています：

```
your-project/
├── .kiro/                          # Kiro の管理領域
│   └── specs/
│       └── bookmark-manager/
│           ├── requirements.md     # 要件定義（マスター）
│           ├── design.md          # 設計書（マスター）
│           ├── tasks.md           # タスク管理
│           ├── usecase.md         # ユースケース（派生）
│           └── screen-design.md   # 画面設計（派生）
│
├── .claude/                        # Claude Code の管理領域
│   ├── settings.json              # MCP サーバー設定
│   └── skills/                    # 専門スキル定義
│       ├── swift-build/
│       │   └── SKILL.md
│       ├── swiftui-review/
│       │   └── SKILL.md
│       ├── ios-security/
│       │   └── SKILL.md
│       └── appstore-prep/
│           └── SKILL.md
│
├── reports/                        # 進捗レポート（共有）
│   └── 2025-12-25/
│       ├── 1st.md
│       └── 2nd.md
│
├── CLAUDE.md                       # Claude Code のルールブック
└── README.md
```

### 設定ファイルの役割

#### 1. `.kiro/specs/` - プロジェクトの設計図

Kiro が管理する「マスタードキュメント」です：

- **requirements.md**: 何を作るか（要件定義）
- **design.md**: どう作るか（アーキテクチャ設計）
- **tasks.md**: いつ作るか（タスク計画）

派生ドキュメント：
- **usecase.md**: requirements.md から派生
- **screen-design.md**: design.md から派生

#### 2. `.claude/settings.json` - MCP サーバー設定

Claude Code が外部ツールと連携するための設定：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-filesystem", "/path/to/your-project"]
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

**重要なポイント**:
- `filesystem`: プロジェクトのファイル操作
- `github`: Git操作とIssue管理
- `sequential-thinking`: 複雑な問題の思考プロセス可視化

#### 3. `.claude/skills/` - 専門知識のモジュール化

Claude Code が特定のタスクを実行するための「スキル」：

```markdown
---
name: swift-build
description: "SwiftプロジェクトのビルドとテストをXcodeコマンドラインで実行"
---

# Swift ビルド＆テスト

## iOS Simulator
```bash
xcodebuild build -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 16'
xcodebuild test -scheme YourApp -destination 'platform=iOS Simulator,name=iPhone 16'
```
```

**Skills の例**:
- `swift-build`: ビルドとテストの自動化
- `swiftui-review`: コードレビューのチェックリスト
- `ios-security`: セキュリティ監査
- `appstore-prep`: App Store 申請準備

#### 4. `CLAUDE.md` - Claude Code のルールブック

Claude Code の振る舞いを定義する「憲法」：

```markdown
# CLAUDE.md - Project Context & Rules

## 🌐 言語設定
すべての応答は**日本語**で行うこと。

## 📏 Coding Standards
- メソッド行数: 最大20行
- クラス行数: 最大150行
- View行数: 最大100行

## ⛔ 禁止事項
- ユーザーの指示なしに勝手に**Git操作**しない
- 設計書・承認なしに**新機能を実装**しない
- **Phase 1B の機能**を Phase 1A で実装しない

## 📚 参照ドキュメント
- 要件定義: `.kiro/specs/bookmark-manager/requirements.md`
- 設計書: `.kiro/specs/bookmark-manager/design.md`
- タスク計画: `.kiro/specs/bookmark-manager/tasks.md`
```

**重要**: Claude Code は Kiro の設計書を「読み取り専用」で参照します。

## 実際の開発フロー

### Phase 1: 設計フェーズ（Kiro が主導）

1. **要件定義**
   ```
   開発者: 「ブックマーク管理アプリを作りたい」
   Kiro: requirements.md を作成
   ```

2. **設計書作成**
   ```
   開発者: 「MVVM + Repository パターンで設計して」
   Kiro: design.md を作成
   ```

3. **タスク分解**
   ```
   Kiro: tasks.md を作成（1週間MVPのタスクリスト）
   ```

### Phase 2: 実装フェーズ（Claude Code が主導）

1. **セッション開始**
   ```
   Claude Code: CLAUDE.md を読み込み
   Claude Code: .kiro/specs/ を参照
   Claude Code: 「Task 1.1 から開始します」
   ```

2. **コード実装**
   ```
   開発者: 「ブックマーク一覧画面を実装して」
   Claude Code: SwiftUI コードを生成
   Claude Code: swiftui-review スキルで自動レビュー
   ```

3. **ビルド＆テスト**
   ```
   開発者: 「ビルドしてテストして」
   Claude Code: swift-build スキルを実行
   Claude Code: テスト結果をレポート
   ```

### Phase 3: 進捗管理（両者が協力）

1. **タスク完了**
   ```
   Claude Code: Git commit with "[Task 1.1 completed]"
   Kiro: tasks.md を自動更新（✅ マーク追加）
   ```

2. **セッションレポート**
   ```
   Claude Code: reports/2025-12-25/1st.md を生成
   Kiro: 次回セッション時にレポートを読み込み
   ```

3. **次のタスク**
   ```
   Kiro: 「Task 1.2 に進みましょう」
   Claude Code: 「了解、実装を開始します」
   ```

## 連携の仕組み

### 1. ドキュメント参照の流れ

```
Kiro が作成
    ↓
.kiro/specs/requirements.md
.kiro/specs/design.md
.kiro/specs/tasks.md
    ↓
Claude Code が参照（読み取り専用）
    ↓
CLAUDE.md に参照ルールを記載
    ↓
実装時に設計書に従う
```

### 2. 進捗管理の流れ

```
Claude Code が実装
    ↓
Git commit with "[Task X.Y completed]"
    ↓
Kiro が自動検知
    ↓
tasks.md を自動更新
    ↓
reports/ にレポート生成
    ↓
次回セッションで両者が参照
```

### 3. Skills と Specs の連携

```
Kiro: design.md に「SwiftUIのベストプラクティスに従う」と記載
    ↓
Claude Code: swiftui-review スキルを作成
    ↓
実装時に自動的にレビュー実行
    ↓
違反があれば修正案を提示
```

## 実装例：ブックマーク機能の開発

### Kiro の設計書（.kiro/specs/design.md）

```markdown
## アーキテクチャ
- MVVM + Repository Pattern
- SwiftUI + Core Data
- Property-Based Testing

## データモデル
- ArticleBookmark: 記事ブックマーク
- TweetMemo: Twitter風メモ
- Tag: タグ管理
```

### Claude Code のスキル（.claude/skills/swiftui-review/SKILL.md）

```markdown
## パフォーマンス
- [ ] 不要な@Stateの使用がないか
- [ ] @ObservedObjectの過剰な再描画がないか
- [ ] List/ForEachにidが適切に設定されているか

## アーキテクチャ
- [ ] Viewが肥大化していないか（200行以上は分割検討）
- [ ] ビジネスロジックがViewModelに分離されているか
```

### 実装の流れ

1. **開発者**: 「ブックマーク一覧画面を実装して」

2. **Claude Code**:
   - CLAUDE.md を読み込み
   - design.md を参照してMVVMパターンを確認
   - BookmarkListView.swift を生成
   - swiftui-review スキルで自動チェック

3. **Claude Code**: 「実装完了。レビュー結果：
   - ✅ View行数: 85行（基準内）
   - ✅ ViewModelに分離済み
   - ⚠️ List に id が未設定 → 修正しました」

4. **開発者**: 「ビルドしてテストして」

5. **Claude Code**:
   - swift-build スキルを実行
   - `xcodebuild test -scheme KiroBookmark -destination 'platform=iOS Simulator,name=iPhone 16'`
   - テスト結果: ✅ All tests passed

6. **Claude Code**: Git commit with "[Task 1.2 completed] ブックマーク一覧画面実装"

7. **Kiro**: tasks.md を自動更新
   ```markdown
   - [x] Task 1.2: ブックマーク一覧画面 ✅
   ```

## トラブルシューティング

### 問題1: Claude Code が Kiro の設計書を無視する

**原因**: CLAUDE.md に参照ルールが記載されていない

**解決策**:
```markdown
## 📚 参照ドキュメント
- 要件定義: `.kiro/specs/bookmark-manager/requirements.md`
- 設計書: `.kiro/specs/bookmark-manager/design.md`
- タスク計画: `.kiro/specs/bookmark-manager/tasks.md`

### 参照ルール
- **設計方針**: design.md → screen-design.md の順で確認
- **要件確認**: requirements.md → usecase.md の順で確認
- **タスク**: tasks.md に従って実装
```

### 問題2: 進捗が自動更新されない

**原因**: Git commit メッセージに進捗マークがない

**解決策**:
```bash
# ❌ 悪い例
git commit -m "ブックマーク機能実装"

# ✅ 良い例
git commit -m "[Task 1.2 completed] ブックマーク機能実装"
```

### 問題3: Skills が起動しない

**原因**: SKILL.md の frontmatter が不正

**解決策**:
```markdown
---
name: swift-build
description: "Use when: ビルド、テスト、xcodebuild を依頼された時。"
---
```

## ベストプラクティス

### 1. ドキュメントの更新順序

```
1. Kiro でベースドキュメントを更新
   - requirements.md
   - design.md
   - tasks.md

2. 派生ドキュメントに反映
   - usecase.md
   - screen-design.md

3. Claude Code の CLAUDE.md に参照ルールを追加

4. 実装開始
```

### 2. Skills の作成順序

```
1. Claude Code 側で Skills を先に作成
   - .claude/skills/swift-build/SKILL.md
   - .claude/skills/swiftui-review/SKILL.md

2. 動作確認
   - 「ビルドして」で起動するか確認
   - 「レビューして」で起動するか確認

3. 動いた Skills の情報を Kiro の design.md に反映
   - 「SwiftUIレビューは swiftui-review スキルで自動化」

4. CLAUDE.md に Kiro 参照を追加
```

### 3. 進捗管理の自動化

```
通常時: 全て自動化
  ↓
Git commit → 自動検知 → 自動更新
  ↓
緊急時: 手動コマンドで補正
  ↓
`update-progress` コマンド実行
```

## まとめ

Kiro と Claude Code の併用により、以下のメリットが得られます：

### 開発効率の向上
- **設計と実装の分離**: Kiro が設計、Claude が実装
- **自動化**: ビルド、テスト、レビューの自動化
- **進捗管理**: タスク完了の自動検知と更新

### コード品質の向上
- **設計書に基づく実装**: アーキテクチャの一貫性
- **Skills による自動レビュー**: ベストプラクティスの強制
- **Property-Based Testing**: 網羅的なテスト

### 長期的なメンテナンス性
- **ドキュメントの一元管理**: .kiro/specs/ に集約
- **セッションレポート**: 進捗の可視化
- **スキルの再利用**: 他のプロジェクトでも利用可能

## 次のステップ

この環境を構築したい方は、以下の順序で進めてください：

1. **Kiro のインストール**
   - Anthropic の公式サイトから入手

2. **Claude Code のセットアップ**
   - Claude Desktop をインストール
   - MCP サーバーを設定（settings.json）

3. **プロジェクト構造の作成**
   ```bash
   mkdir -p .kiro/specs/your-project
   mkdir -p .claude/skills
   mkdir -p reports
   ```

4. **設定ファイルの作成**
   - CLAUDE.md（ルールブック）
   - .claude/settings.json（MCP設定）
   - .kiro/specs/（設計書）

5. **Skills の作成**
   - 自分のプロジェクトに必要なスキルを定義

6. **開発開始**
   - Kiro で設計
   - Claude Code で実装
   - 両者で進捗管理

Happy Coding! 🚀
