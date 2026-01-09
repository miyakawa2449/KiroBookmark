# KiroBookmark

AIエンジニア向けの技術ブログ管理iOSアプリ。2タブ + サイドメニューによる効率的な記事管理を提供します。

## 概要

技術ブログのブックマーク管理、メモ種類別の記事整理、タグ付けをシンプルなUIで実現するネイティブiOSアプリです。

## 機能

### Phase 1A（MVP）- 完了
- **2タブナビゲーション**: New Entry / Bookmark
- **サイドメニュー**: 右スワイプでメモ種類別フィルタ（いいね、アイディア、感想、TODO、その他、未読）
- **ブックマーク管理**: URL追加・カード表示・削除・お気に入り
- **メモ機能**: 記事ごとに種類別メモ（140文字制限）
- **タグ管理**: 記事への複数タグ付け・使用頻度順表示
- **WebView**: アプリ内記事表示・テキスト選択・引用メモ作成
- **動的メニュー**: メモ種類別フィルタリング
- **設定画面**: メニューカスタマイズ

### Phase 1B（実装済み）
- **記事プレビューUI改善**: カードタップでWebView直接表示、ツールバー追加
- **RSS自動検出・監視**: ブックマーク追加時にRSS自動検出、定期更新
- **統合検索機能**: タイトル・URL・ドメイン・メモ・タグの横断検索
- **時間経過表示**: 「3分前」「2時間前」等の相対時間表示
- **記事閲覧状態管理**: 未読バッジ、自動既読マーク
- **New Entry/Bookmark分離**: RSS記事とユーザーブックマークの明確な分離
- **トースト通知**: ブックマーク追加時の視覚的フィードバック

### Phase 1B（予定）
- 通知機能（ブログ更新通知、Push通知）
- ドメイン整理機能
- エクスポート（Markdown/JSON）
- AI要約・タグ推薦
- 写真添付機能

## 技術スタック

| 項目 | 技術 |
|------|------|
| UI | SwiftUI (iOS 17.0+) |
| 言語 | Swift 5.9+ (Swift 6 Concurrency対応済み) |
| 並行処理 | @MainActor, async/await |
| データ | Core Data |
| テスト | SwiftCheck + XCTest |
| アーキテクチャ | MVVM + Repository Pattern |

## プロジェクト構造

```
KiroBookmark/
├── Core/
│   └── PersistenceController.swift    # @MainActor対応済み
├── Helpers/
│   ├── ColorExtensions.swift
│   └── DateExtensions.swift          # 相対時間表示
├── Models/
│   └── Enums.swift                    # MemoType, ReadingStatus, MainTabType, SideMenuItem
├── Repositories/                      # 2段階初期化パターン適用済み
│   ├── BookmarkRepository.swift       # New Entry/Bookmark分離対応
│   ├── FavoriteBlogRepository.swift
│   ├── MemoRepository.swift
│   └── TagRepository.swift
├── Services/                          # 2段階初期化パターン適用済み
│   ├── RSSService.swift               # RSS取得・パース
│   ├── BackgroundRefreshService.swift # バックグラウンド更新
│   ├── NotificationService.swift      # 通知管理
│   └── URLValidationService.swift
├── ViewModels/                        # @MainActor + 2段階初期化適用済み
│   ├── AddBookmarkViewModel.swift
│   ├── AddMemoViewModel.swift
│   ├── ArticleWebViewModel.swift      # トースト通知対応
│   ├── BookmarkListViewModel.swift
│   ├── HomeViewModel.swift
│   ├── MemoListViewModel.swift
│   ├── NewEntryViewModel.swift        # New Entry専用
│   ├── RSSFeedViewModel.swift
│   ├── SearchViewModel.swift          # 統合検索
│   ├── TagListViewModel.swift
│   └── TagSelectionViewModel.swift
├── Views/
│   ├── Components/
│   │   └── ToastView.swift            # トースト通知コンポーネント
│   ├── AddBookmarkView.swift
│   ├── AddMemoSheet.swift
│   ├── ArticleCardView.swift          # ロングプレスメニュー対応
│   ├── ArticleDetailView.swift
│   ├── ArticleWebView.swift           # ツールバー・トースト対応
│   ├── HomeView.swift                 # 2タブ+サイドメニュー
│   ├── MemoCardView.swift
│   ├── MemoListView.swift
│   ├── QuoteMemoSheet.swift
│   ├── SearchView.swift               # 統合検索UI
│   ├── SettingsView.swift
│   ├── SideMenuView.swift
│   ├── TagListView.swift
│   └── TagSelectionView.swift
└── KiroBookmark.xcdatamodeld/

KiroBookmarkTests/                     # @MainActor対応済み
├── PropertyTests.swift                # プロパティベーステスト (20テスト)
└── KiroBookmarkTests.swift            # ユニットテスト (70テスト)
```

## データモデル

### ArticleBookmark
| 属性 | 型 | 説明 |
|------|------|------|
| id | UUID | Primary Key |
| title | String | 記事タイトル |
| url | String | 記事URL |
| domain | String | ドメイン名 |
| bookmarkedDate | Date | ブックマーク日時 |
| publishedDate | Date? | 公開日時 |
| isFavorite | Bool | お気に入り |
| readingStatus | String | 閲覧状態（未読/既読） |
| isUserBookmarked | Bool | ユーザーブックマークフラグ |
| isFromRSS | Bool | RSS由来フラグ |
| viewedDate | Date? | 閲覧日時 |
| viewCount | Int32 | 閲覧回数 |
| summary | String? | 要約 |

### TweetMemo
| 属性 | 型 | 説明 |
|------|------|------|
| id | UUID | Primary Key |
| content | String | メモ内容（140文字） |
| memoType | String | 種類（idea/thought/todo/quote/other） |
| createdDate | Date | 作成日時 |
| updatedDate | Date | 更新日時 |
| isQuote | Bool | 引用メモフラグ |
| selectedText | String? | 選択テキスト |
| sourceURL | String? | 引用元URL |

### Tag
| 属性 | 型 | 説明 |
|------|------|------|
| id | UUID | Primary Key |
| name | String | タグ名 |
| usageCount | Int32 | 使用回数 |
| color | String? | 表示色 |

### FavoriteBlog
| 属性 | 型 | 説明 |
|------|------|------|
| id | UUID | Primary Key |
| domain | String | ブログドメイン |
| name | String | ブログ名 |
| rssURL | String? | RSS URL |
| addedDate | Date | 登録日時 |
| lastFetchedDate | Date? | 最終取得日時 |

### リレーション
- ArticleBookmark ↔ TweetMemo (1:N)
- ArticleBookmark ↔ Tag (N:N)
- ArticleBookmark ↔ FavoriteBlog (N:1)

## 開発状況

### Phase 1A
| Task | Status | 内容 |
|------|--------|------|
| Task 1 | ✅ 完了 | Core Data初期設定 |
| Task 2 | ✅ 完了 | ブックマーク管理機能 |
| Task 3 | ✅ 完了 | メモ種類別管理機能 |
| Task 4 | ✅ 完了 | タグ管理機能 |
| Task 5 | ✅ 完了 | WebView・テキスト選択 |
| Task 6 | ✅ 完了 | 2タブ+サイドメニュー |
| Task 7 | ✅ 完了 | MVP完成・検証 |

### Phase 1B
| 機能 | Status |
|------|--------|
| 記事プレビューUI改善 | ✅ 完了 |
| RSS自動検出・監視 | ✅ 完了 |
| 統合検索機能 | ✅ 完了 |
| 時間経過表示 | ✅ 完了 |
| 記事閲覧状態管理 | ✅ 完了 |
| New Entry/Bookmark分離 | ✅ 完了 |
| トースト通知 | ✅ 完了 |
| 通知機能 | 🔜 予定 |
| エクスポート・AI機能 | 🔜 予定 |

## セットアップ

```bash
git clone https://github.com/miyakawa2449/KiroBookmark.git
cd KiroBookmark
open KiroBookmark.xcodeproj
```

### 必要環境
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

## テスト

```bash
# Xcodeでテスト実行
Cmd + U

# コマンドラインでテスト実行
xcodebuild test -scheme KiroBookmark -destination 'platform=iOS Simulator,name=iPhone 17'
```

### プロパティテスト（SwiftCheck）
- Property 1-6: ブックマーク・URL・重複・お気に入り
- Property 8-15: メモ・タグ管理
- Property 23-28: メモ種類フィルタ・WebView・サイドメニュー

### ユニットテスト（XCTest）
- Repository層: CRUD操作
- ViewModel層: 状態管理
- Service層: URL検証・RSS処理

## 既知の制限事項

### 現在の制限
- データはローカル保存のみ（iCloud同期なし）
- 写真添付なし（テキストメモのみ）
- Push通知未実装

### コード品質
- ✅ Swift 6 Concurrency対応済み（2026-01-09）
  - すべての並行処理警告を解決
  - @MainActor隔離パターンを全面適用
  - テスト成功率: 100%（90/90テスト）

## ドキュメント

| ドキュメント | パス |
|--------------|------|
| 要件定義 | `.kiro/specs/bookmark-manager/requirements.md` |
| 設計書 | `.kiro/specs/bookmark-manager/design.md` |
| タスク | `.kiro/specs/bookmark-manager/tasks.md` |
| ユースケース | `.kiro/specs/bookmark-manager/usecase.md` |
| 画面設計 | `.kiro/specs/bookmark-manager/screen-design.md` |
| Claude Code設定 | `CLAUDE.md` |
| 実装指示書 | `.claude/instructions/*.md` |

## 作者

**宮川 剛**
- GitHub: [@miyakawa2449](https://github.com/miyakawa2449)

## ライセンス

MIT License

Copyright (c) 2024 宮川 剛

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
