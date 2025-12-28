# Claude Code 実装指示書ディレクトリ

このディレクトリには、Claude Code に渡す実装指示書を整理して保管しています。

## 📂 ディレクトリ構造

```
.claude/instructions/
├── README.md              # このファイル
├── task6-fixes/           # Task6 ユーザテスト結果に基づく修正
│   ├── index.md           # 全体ガイド（最初に読むファイル）
│   ├── fix1-swipe-sensitivity.md
│   ├── fix2-remove-bookmark-button.md
│   ├── fix3-quote-character-limit.md
│   ├── fix4-url-validation.md
│   └── all-fixes-combined.md
└── archived/              # 完了した指示書
    ├── initial-project-setup.md
    └── swipe-and-tap-gesture-fixes.md
```

## 📋 命名規則

### タスク別フォルダ
- `taskN-[brief-description]/` - 各タスクの修正指示をまとめる
- 例: `task6-fixes/`, `task7-rss-integration/`

### ファイル名
- `index.md` - タスクの全体ガイド（必須）
- `fixN-[description].md` - 個別の修正指示
- `all-fixes-combined.md` - 全修正を1つにまとめたもの（オプション）

### アーカイブ
- 完了した指示書は `archived/` に移動
- ファイル名は内容がわかるように変更

## 🔄 ワークフロー

### 1. 新しい指示書の作成
```bash
# タスク別フォルダを作成
mkdir -p .claude/instructions/task7-rss/

# 指示書を作成
# .claude/instructions/task7-rss/index.md
# .claude/instructions/task7-rss/fix1-rss-parser.md
```

### 2. Claude Code への指示
```
Claude Code に以下のファイルを渡してください：
.claude/instructions/task6-fixes/index.md
```

### 3. 完了後のアーカイブ
```bash
# タスク完了後、フォルダごと archived に移動
mv .claude/instructions/task6-fixes .claude/instructions/archived/
```

## 📝 使用例

### 段階的な修正の場合
```
.claude/instructions/task6-fixes/
├── index.md              # 全体像を説明
├── fix1-*.md             # 修正1の詳細
├── fix2-*.md             # 修正2の詳細
└── fix3-*.md             # 修正3の詳細
```

Claude Code には：
1. まず `index.md` を渡して全体を把握させる
2. 次に `fix1-*.md` を渡して実装させる
3. テスト完了後、`fix2-*.md` を渡す
4. 以降、順次実装

### 一括修正の場合
```
.claude/instructions/task7-feature/
└── implementation.md     # 全ての実装指示を1つに
```

Claude Code には `implementation.md` を渡すだけ

## 🗂️ アーカイブの管理

### いつアーカイブするか
- タスクが完了し、修正が本番環境にデプロイされた後
- 指示書の内容が古くなり、参照価値がなくなった時

### アーカイブの活用
- 過去の実装パターンの参照
- 類似タスクの指示書作成時のテンプレート
- プロジェクトの歴史記録

## 💡 ベストプラクティス

1. **index.md は必須**: 各タスクフォルダには必ず全体ガイドを作成
2. **段階的実装を推奨**: 大きな変更は複数の小さな修正に分割
3. **テスト手順を明記**: 各指示書に具体的なテスト手順を記載
4. **完了条件を明確に**: チェックリスト形式で完了条件を記載
5. **定期的にアーカイブ**: 完了したタスクは速やかにアーカイブ

## 🔗 関連ドキュメント

- `.kiro/specs/bookmark-manager/` - Kiro 管理の仕様書
- `.claude/skills/` - Claude Code の自動実行スキル
- `reports/` - 日次レポート

---

**Note**: このディレクトリは Claude Code への実装指示専用です。仕様書や設計書は `.kiro/specs/` に保管してください。
