# KiroBookmark

AIエンジニア向けの技術ブログ管理iOSアプリ。2タブ + サイドメニューによる効率的な記事管理を提供します。

## 概要

技術ブログのブックマーク管理、メモ種類別の記事整理、タグ付けをシンプルなUIで実現するネイティブiOSアプリです。

## 機能

### Phase 1A（MVP）
- **2タブナビゲーション**: New Entry / Bookmark
- **サイドメニュー**: 右スワイプでメモ種類別フィルタ（いいね、アイディア、感想、TODO、その他）
- **ブックマーク管理**: URL追加・カード表示・削除・お気に入り
- **メモ機能**: 記事ごとに種類別メモ（140文字制限）
- **タグ管理**: 記事への複数タグ付け
- **WebView**: アプリ内記事表示・テキスト選択・引用メモ作成
- **動的メニュー**: メモが存在しないメニュー項目の自動非表示

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
├── Models/
│   └── Enums.swift              # MemoType, ReadingStatus, MainTabType, SideMenuItem
├── Repositories/
│   ├── BookmarkRepository.swift
│   └── FavoriteBlogRepository.swift
├── Services/
│   └── URLValidationService.swift
├── ViewModels/
│   ├── BookmarkListViewModel.swift
│   └── AddBookmarkViewModel.swift
├── Views/
│   ├── BookmarkListView.swift
│   ├── BookmarkCardView.swift
│   └── AddBookmarkView.swift
└── KiroBookmark.xcdatamodeld/

KiroBookmarkTests/
├── PropertyTests.swift          # プロパティベーステスト
└── KiroBookmarkTests.swift      # ユニットテスト
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
| Task 1 | 完了 | Core Data初期設定 |
| Task 2 | 完了 | ブックマーク管理機能 |
| Task 3 | 未着手 | メモ種類別管理機能 |
| Task 4 | 未着手 | タグ管理機能 |
| Task 5 | 未着手 | WebView・テキスト選択 |
| Task 6 | 未着手 | 2タブ+サイドメニュー |
| Task 7 | 未着手 | MVP完成・検証 |

**進捗: 2/7 (28%)**

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

全30テストで品質保証。

```bash
# Xcodeでテスト実行
Cmd + U
```

### プロパティテスト（SwiftCheck）
- ブックマーク追加の一貫性
- URL検証と正規化
- 重複検出
- お気に入りブログ検出
- メモ関連付けの正確性

## ドキュメント

| ドキュメント | パス |
|--------------|------|
| 要件定義 | `.kiro/specs/bookmark-manager/requirements.md` |
| 設計書 | `.kiro/specs/bookmark-manager/design.md` |
| タスク | `.kiro/specs/bookmark-manager/tasks.md` |
| ユースケース | `.kiro/specs/bookmark-manager/usecase.md` |
| 画面設計 | `.kiro/specs/bookmark-manager/screen-design.md` |
| Claude Code設定 | `CLAUDE.md` |

## ライセンス

未定
