# KiroBookmark

AIエンジニア向けの技術ブログ管理iOSアプリ。2タブ + サイドメニューによる効率的な記事管理を提供します。

## 概要

技術ブログのブックマーク管理、メモ種類別の記事整理、タグ付けをシンプルなUIで実現するネイティブiOSアプリです。

## 機能

### Phase 1A（MVP）- 完了
- **2タブナビゲーション**: New Entry / Bookmark
- **サイドメニュー**: 右スワイプでメモ種類別フィルタ（いいね、アイディア、感想、TODO、その他）
- **ブックマーク管理**: URL追加・カード表示・削除・お気に入り
- **メモ機能**: 記事ごとに種類別メモ（140文字制限）
- **タグ管理**: 記事への複数タグ付け・使用頻度順表示
- **WebView**: アプリ内記事表示・テキスト選択・引用メモ作成
- **動的メニュー**: メモ種類別フィルタリング
- **設定画面**: メニューカスタマイズ

### Phase 1B（予定）
- RSS自動更新・通知
- 全文検索
- エクスポート（Markdown/JSON）
- AI要約・タグ推薦

## 技術スタック

| 項目 | 技術 |
|------|------|
| UI | SwiftUI (iOS 17.0+) |
| 言語 | Swift 5.9+ |
| データ | Core Data |
| テスト | SwiftCheck + XCTest |
| アーキテクチャ | MVVM + Repository Pattern |

## プロジェクト構造

```
KiroBookmark/
├── Core/
│   └── PersistenceController.swift
├── Helpers/
│   └── ColorExtensions.swift
├── Models/
│   └── Enums.swift                    # MemoType, ReadingStatus, MainTabType, SideMenuItem
├── Repositories/
│   ├── BookmarkRepository.swift
│   ├── FavoriteBlogRepository.swift
│   ├── MemoRepository.swift
│   └── TagRepository.swift
├── Services/
│   └── URLValidationService.swift
├── ViewModels/
│   ├── AddBookmarkViewModel.swift
│   ├── AddMemoViewModel.swift
│   ├── ArticleWebViewModel.swift
│   ├── BookmarkListViewModel.swift
│   ├── HomeViewModel.swift
│   ├── MemoListViewModel.swift
│   ├── TagListViewModel.swift
│   └── TagSelectionViewModel.swift
├── Views/
│   ├── AddBookmarkView.swift
│   ├── AddMemoView.swift
│   ├── ArticleCardView.swift
│   ├── ArticleDetailView.swift
│   ├── ArticleWebView.swift
│   ├── BookmarkCardView.swift
│   ├── BookmarkListView.swift
│   ├── HomeView.swift
│   ├── MemoCardView.swift
│   ├── MemoListView.swift
│   ├── QuoteMemoSheet.swift
│   ├── SettingsView.swift
│   ├── SideMenuView.swift
│   ├── TagListView.swift
│   └── TagSelectionView.swift
└── KiroBookmark.xcdatamodeld/

KiroBookmarkTests/
├── PropertyTests.swift                # プロパティベーステスト (20テスト)
└── KiroBookmarkTests.swift            # ユニットテスト (48テスト)
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
| readingStatus | String | 読書状態 |
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

### リレーション
- ArticleBookmark ↔ TweetMemo (1:N)
- ArticleBookmark ↔ Tag (N:N)
- ArticleBookmark ↔ FavoriteBlog (N:1)

## 開発状況

| Task | Status | 内容 |
|------|--------|------|
| Task 1 | ✅ 完了 | Core Data初期設定 |
| Task 2 | ✅ 完了 | ブックマーク管理機能 |
| Task 3 | ✅ 完了 | メモ種類別管理機能 |
| Task 4 | ✅ 完了 | タグ管理機能 |
| Task 5 | ✅ 完了 | WebView・テキスト選択 |
| Task 6 | ✅ 完了 | 2タブ+サイドメニュー |
| Task 7 | ✅ 完了 | MVP完成・検証 |

**進捗: 7/7 (100%) - Phase 1A MVP 完了**

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

全68テストで品質保証。

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
- Service層: URL検証

## 既知の制限事項

### Phase 1A での制限
- RSS自動更新なし（Phase 1Bで実装予定）
- 検索機能なし（Phase 1Bで実装予定）
- エクスポート機能なし（Phase 1Bで実装予定）
- 写真添付なし（テキストメモのみ）
- データはローカル保存のみ（iCloud同期なし）

### 既知の警告
- Swift 6 Concurrency警告（動作には影響なし）
  - MainActor isolated initializer warnings
  - Phase 1Bでの対応予定

## ドキュメント

| ドキュメント | パス |
|--------------|------|
| 要件定義 | `.kiro/specs/bookmark-manager/requirements.md` |
| 設計書 | `.kiro/specs/bookmark-manager/design.md` |
| タスク | `.kiro/specs/bookmark-manager/tasks.md` |
| ユースケース | `.kiro/specs/bookmark-manager/usecase.md` |
| 画面設計 | `.kiro/specs/bookmark-manager/screen-design.md` |
| Claude Code設定 | `CLAUDE.md` |
| セッションレポート | `reports/YYYY-MM-DD/*.md` |

## ライセンス

未定
