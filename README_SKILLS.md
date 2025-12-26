# Claude Code Skills

このディレクトリには、Claude Code で使用する専門スキルが含まれています。

## 📁 ディレクトリ構造

```
.claude/
├── settings.json.example      # MCP設定のテンプレート（公開）
├── settings.json              # 実際の設定（.gitignoreで除外）
└── skills/                    # 専門スキル（公開）
    ├── swift-build/           # Swift ビルド＆テスト
    ├── swiftui-review/        # SwiftUI コードレビュー
    ├── ios-security/          # iOS セキュリティ監査
    ├── appstore-prep/         # App Store 申請準備
    ├── macos-security/        # macOS セキュリティ監査
    └── mac-appstore-prep/     # Mac App Store 申請準備
```

## 🚀 使い方

### 1. 設定ファイルの作成

`settings.json.example` をコピーして `settings.json` を作成：

```bash
cp .claude/settings.json.example .claude/settings.json
```

### 2. GitHubトークンの設定

`settings.json` を編集して、あなたのGitHubトークンを設定：

```json
{
  "mcpServers": {
    "github": {
      "env": {
        "GITHUB_TOKEN": "your_actual_token_here"
      }
    }
  }
}
```

**重要**: `settings.json` は `.gitignore` で除外されているので、コミットされません。

### 3. Skills の使用

Claude Code で以下のように依頼すると、自動的に該当するスキルが起動します：

| 依頼内容 | 起動するスキル |
|---------|--------------|
| 「ビルドしてテストして」 | `swift-build` |
| 「SwiftUIのコードをレビューして」 | `swiftui-review` |
| 「セキュリティチェックして」 | `ios-security` または `macos-security` |
| 「App Store申請の準備をして」 | `appstore-prep` または `mac-appstore-prep` |

## 📚 各スキルの詳細

### swift-build
- **目的**: Swift プロジェクトのビルドとテストを自動化
- **対応**: iOS Simulator、macOS、Mac Catalyst
- **機能**: ビルド、テスト、アーカイブ、Universal Binary作成

### swiftui-review
- **目的**: SwiftUI のベストプラクティスに基づくコードレビュー
- **チェック項目**:
  - パフォーマンス（@State、@ObservedObject の使用）
  - アクセシビリティ（Dynamic Type、VoiceOver対応）
  - アーキテクチャ（View の肥大化、MVVM分離）

### ios-security
- **目的**: iOS アプリのセキュリティ監査
- **基準**: OWASP Mobile Top 10
- **チェック項目**:
  - Keychain の適切な使用
  - App Transport Security (ATS)
  - ハードコードされた機密情報の検出

### appstore-prep
- **目的**: App Store 申請前のチェックリスト
- **チェック項目**:
  - Info.plist の権限説明
  - プライバシーポリシー
  - アイコンとスクリーンショット
  - ビルド設定

### macos-security
- **目的**: macOS アプリのセキュリティ監査
- **チェック項目**:
  - Notarization（公証）
  - Hardened Runtime
  - Sandbox
  - コード署名

### mac-appstore-prep
- **目的**: Mac App Store 申請前のチェックリスト
- **チェック項目**:
  - Sandbox 必須設定
  - macOS 固有の権限説明
  - スクリーンショット要件
  - Universal Binary

## 🔧 カスタマイズ

各スキルは Markdown ファイルで定義されているので、自由にカスタマイズできます：

```markdown
---
name: your-skill-name
description: "スキルの説明。Use when: キーワード を依頼された時。"
---

# スキルの内容

ここにチェックリストやコマンドを記載
```

## 🌐 グローバル vs プロジェクト固有

### グローバルスキル（全プロジェクト共通）
```
~/.claude/skills/
├── swift-build/
└── ios-security/
```

### プロジェクト固有スキル
```
your-project/.claude/skills/
├── swiftui-review/
└── appstore-prep/
```

プロジェクト固有のスキルは、そのプロジェクトでのみ有効です。

## 📖 参考

詳細は [blog-kiro-claude-integration.md](../blog-kiro-claude-integration.md) を参照してください。

## 🤝 コントリビューション

このスキルは公開されているので、改善提案や新しいスキルの追加は大歓迎です！

1. Fork してください
2. 新しいスキルを `.claude/skills/your-skill/SKILL.md` に作成
3. Pull Request を送ってください

## ⚠️ セキュリティ注意事項

- `settings.json` には機密情報（GitHubトークン）が含まれるため、絶対にコミットしないでください
- `.gitignore` で除外されていますが、念のため確認してください
- トークンは定期的に更新することを推奨します

## 📝 ライセンス

このスキル集は MIT ライセンスで公開されています。自由に使用・改変してください。
