# GitHub公開前のセキュリティチェックリスト

## ✅ 完了した対策

- [x] `.gitignore` に `.claude/` を追加済み
- [x] `.gitignore` に `.env` ファイルを追加済み
- [x] ブログ記事のトークン例を安全なプレースホルダーに変更済み

## 🚨 公開前に必ず実施すること

### 1. GitHubトークンの無効化（最優先）

**現在のトークンを無効化**:
1. GitHub にログイン
2. Settings → Developer settings → Personal access tokens → Tokens (classic)
3. 該当トークンを探して「Delete」または「Revoke」
4. 新しいトークンを生成（必要な場合）

**トークンの場所**:
- ❌ `.claude/settings.json` （.gitignoreで除外済みだが、念のため確認）

### 2. 個人情報の確認

**Xcodeが自動生成したコメント**:
以下のファイルに `Created by Tsuyoshi Miyakawa` が含まれています：
- `KiroBookmark/ContentView.swift`
- `KiroBookmark/KiroBookmarkApp.swift`
- `KiroBookmarkTests/KiroBookmarkTests.swift`

**対応**: これは一般的なXcodeの自動生成コメントなので、問題ありません。
ただし、気になる場合は削除または匿名化してください。

### 3. 最終確認コマンド

```bash
# 1. .claude/ が追跡されていないことを確認
git ls-files .claude/
# → 何も表示されなければOK

# 2. 機密情報が含まれていないか検索
git grep -i "token\|password\|secret\|api_key" -- ':!.gitignore' ':!SECURITY_CHECKLIST.md'
# → 何も表示されなければOK

# 3. 個人情報が含まれていないか検索
git grep -i "tsuyoshi\|/Users/" -- ':!SECURITY_CHECKLIST.md'
# → Xcodeの自動生成コメントのみならOK

# 4. ステージングされているファイルを確認
git status
git diff --cached

# 5. コミット履歴に機密情報が含まれていないか確認
git log --all --full-history --source -- .claude/
# → 何も表示されなければOK
```

### 4. .gitignore の最終確認

現在の `.gitignore` に以下が含まれていることを確認：

```gitignore
# Claude Code settings (contains sensitive tokens)
.claude/

# Environment files
.env
.env.local
*.env
```

## 📋 公開後の推奨事項

### 1. README.md にセキュリティ注意事項を追加

```markdown
## セットアップ

### MCP設定（Claude Code）

`.claude/settings.json` を作成してください（このファイルは.gitignoreで除外されています）：

\`\`\`json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "your_github_token_here"
      }
    }
  }
}
\`\`\`

**重要**: GitHubトークンは絶対にコミットしないでください！
```

### 2. .claude/settings.json.example を作成

機密情報を除いたテンプレートファイルを作成：

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
        "GITHUB_TOKEN": "your_github_token_here"
      }
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    }
  }
}
```

### 3. GitHub Secretsの活用（CI/CD使用時）

GitHub Actionsを使う場合：
- Repository Settings → Secrets and variables → Actions
- `GITHUB_TOKEN` を追加

## 🔍 定期的なセキュリティチェック

### 月次チェック

```bash
# 機密情報の漏洩チェック
git log -p | grep -i "token\|password\|secret"

# .gitignoreの有効性確認
git check-ignore -v .claude/settings.json
```

### ツールの活用

```bash
# git-secretsのインストール（推奨）
brew install git-secrets

# 設定
git secrets --install
git secrets --register-aws
git secrets --add 'github_pat_[0-9A-Za-z_]+'
git secrets --add 'ghp_[0-9A-Za-z]+'

# スキャン
git secrets --scan
```

## ⚠️ 万が一トークンを公開してしまった場合

1. **即座にトークンを無効化**
   - GitHub → Settings → Developer settings → Personal access tokens
   - 該当トークンを削除

2. **コミット履歴から削除**
   ```bash
   # BFG Repo-Cleanerを使用（推奨）
   brew install bfg
   bfg --replace-text passwords.txt
   git reflog expire --expire=now --all
   git gc --prune=now --aggressive
   
   # 強制プッシュ（注意！）
   git push --force
   ```

3. **GitHubに報告**
   - GitHub Security Advisories で報告

4. **影響範囲の確認**
   - トークンを使用したアクセスログを確認
   - 不正アクセスがないか監視

## 📚 参考リンク

- [GitHub: Removing sensitive data from a repository](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [git-secrets](https://github.com/awslabs/git-secrets)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

---

**最終確認日**: 2025-12-26
**確認者**: [宮川剛]
**ステータス**: ✅ 公開準備完了 / ⚠️ 要対応 / ❌ 公開不可
