# 📚 KiroBookmark - AI Engineer's Blog Manager (6タブシステム)

AIエンジニア向けの技術ブログ管理ツール。6タブシステム（New Entry, Bookmark, Todo, アイディア, 感想, その他）による効率的な記事管理、テキスト選択による引用メモ、スワイプ操作による直感的なナビゲーションを提供します。

## 🎯 プロジェクト概要

**KiroBookmark**は、AIエンジニアが技術ブログを効率的に管理・学習するためのiOSアプリです。6タブシステムによるメモ種類別記事管理、テキスト選択による引用メモ作成、スワイプ操作による直感的なタブ切り替えなど、技術情報の収集と整理を革新的にサポートします。

### 主な特徴

- 📖 **6タブシステム**: New Entry, Bookmark, Todo, アイディア, 感想, その他による記事管理
- 🐦 **メモ種類別管理**: 記事ごとに種類別（アイディア、感想、TODO、引用、その他）メモを管理
- ✂️ **テキスト選択・引用メモ**: WebView内でテキスト選択して引用メモを自動作成
- 👆 **スワイプナビゲーション**: 左右スワイプによる直感的なタブ切り替え
- 🎛️ **動的タブ表示**: メモが存在しないタブの自動非表示
- ⚙️ **タブカスタマイズ**: タブ順序・表示/非表示の個人設定
- 🏷️ **タグ分類システム**: 記事を複数タグで分類、使用頻度順表示
- 📱 **ネイティブiOSアプリ**: SwiftUI + Core Dataによる高速・直感的UI

## 🚀 開発フェーズ

### Phase 1A: 1週間MVP（現在実装中）
- ✅ **6タブシステム**: New Entry, Bookmark, Todo, アイディア, 感想, その他
- ✅ **基本ブックマーク機能**: 追加・削除・カード表示
- ✅ **メモ種類別管理**: アイディア、感想、TODO、引用、その他の種類別メモ
- ✅ **テキスト選択・引用メモ**: WebView内テキスト選択による引用メモ自動作成
- ✅ **スワイプナビゲーション**: 左右スワイプによるタブ切り替え
- ✅ **動的タブ表示**: メモが存在しないタブの自動非表示
- ✅ **タブカスタマイズ**: タブ順序・表示設定の個人カスタマイズ
- ✅ **タグ管理**: 基本的な追加・編集・削除
- ✅ **Core Data**: ローカル保存
- ✅ **プロパティベーステスト**: SwiftCheckによる品質保証（43項目）

### Phase 1B: 拡張機能（後日実装）
- 🔄 RSS自動更新・通知
- 🔍 全文検索・フィルタリング
- 📤 エクスポート機能（Markdown/JSON）
- 🤖 AI要約・タグ推薦
- 📊 読書進捗管理・ドメイン整理
- 🖼️ メモ写真添付

### Phase 2: クロスプラットフォーム
- 💻 macOSアプリ対応
- ☁️ CloudKit同期
- 🔄 デバイス間データ共有

### Phase 3: サーバーサイド
- ⚡ AWS Lambda RSS監視
- 📲 リアルタイム通知
- 🧠 高度なAI機能

## 🏗️ 技術スタック

### Phase 1A 技術スタック
- **フレームワーク**: SwiftUI (iOS 17.0+)
- **言語**: Swift 5.9+
- **データベース**: Core Data
- **テスト**: SwiftCheck (Property-Based Testing) + XCTest
- **アーキテクチャ**: MVVM + Repository Pattern
- **UI**: 6タブシステム + スワイプナビゲーション
- **WebView**: WKWebView + テキスト選択機能


### 将来の技術スタック
- **同期**: CloudKit
- **サーバー**: AWS Lambda, CloudWatch Events
- **通知**: Apple Push Notification Service
- **AI**: OpenAI API (要約・タグ推薦)

## 📁 プロジェクト構造

```
KiroBookmark/
├── Core/                          # Core Data スタック
│   └── PersistenceController.swift
├── Models/                        # データモデル
├── Managers/                      # ビジネスロジック・サービス
│   ├── TabManager.swift           # 6タブシステム管理
│   ├── TextSelectionService.swift # テキスト選択・引用メモ
│   ├── SwipeNavigationService.swift # スワイプナビゲーション
│   └── DynamicTabDisplayService.swift # 動的タブ表示
├── ViewModels/                    # MVVM ViewModels
├── Views/                         # SwiftUI Views
│   ├── HomeView.swift             # 6タブ式ホーム画面
│   ├── ArticleWebView.swift       # テキスト選択対応WebView
│   ├── MemoTypeSelectionView.swift # メモ種類選択
│   ├── QuoteMemoCreationView.swift # 引用メモ作成
│   └── SettingsView.swift         # タブ設定・カスタマイズ
├── KiroBookmark.xcdatamodeld/     # Core Data モデル
├── KiroBookmarkApp.swift          # アプリエントリーポイント
└── ContentView.swift              # メインビュー

KiroBookmarkTests/
├── PropertyTests.swift            # プロパティベーステスト（43項目）
└── KiroBookmarkTests.swift        # ユニットテスト

.kiro/specs/bookmark-manager/
├── requirements.md                # 要件定義（22要件）
├── design.md                      # 設計書（15サービス）
├── tasks.md                       # 実装タスク（7タスク）
├── usecase.md                     # UseCase（12項目）
└── screen-design.md               # 画面設計（6タブシステム対応）
```

## 🗄️ データモデル

### Core Data エンティティ

#### ArticleBookmark
- `id`: UUID (Primary Key)
- `title`: String - 記事タイトル
- `url`: String - 記事URL
- `domain`: String - ドメイン名
- `bookmarkedDate`: Date - ブックマーク日時
- `publishedDate`: Date? - 記事公開日時
- `summary`: String? - 記事要約

#### TweetMemo
- `id`: UUID (Primary Key)
- `content`: String - メモ内容（140文字制限）
- `type`: MemoType - メモ種類（アイディア、感想、TODO、引用、その他）
- `createdDate`: Date - 作成日時
- `updatedDate`: Date - 更新日時
- `isQuote`: Bool - 引用メモフラグ
- `sourceURL`: String? - 引用元URL
- `selectedText`: String? - 選択されたテキスト
- `bookmark`: ArticleBookmark - 関連記事

#### Tag
- `id`: UUID (Primary Key)
- `name`: String - タグ名
- `usageCount`: Int32 - 使用回数
- `color`: String? - 表示色

### リレーションシップ
- ArticleBookmark ↔ TweetMemo (1対多)
- ArticleBookmark ↔ Tag (多対多)
- TweetMemo ↔ TextSelectionHistory (1対1, 引用メモの場合)

#### 新規エンティティ（6タブシステム対応）

#### TabSettings
- `id`: UUID (Primary Key)
- `tabOrder`: [String] - タブ順序配列
- `hiddenTabs`: [String] - 非表示タブ配列
- `swipeEnabled`: Bool - スワイプ操作有効フラグ
- `autoHideEmptyTabs`: Bool - 空タブ自動非表示フラグ

#### TextSelectionHistory
- `id`: UUID (Primary Key)
- `selectedText`: String - 選択されたテキスト
- `sourceURL`: String - 引用元URL
- `selectionDate`: Date - 選択日時
- `createdMemo`: TweetMemo? - 作成されたメモ

## 🧪 テスト戦略

### プロパティベーステスト (SwiftCheck)
- **Property 1**: ブックマーク追加の一貫性
- **Property 6**: メモ関連付けの正確性
- **Property 7**: メモ文字数制限の遵守
- **Property 12**: タグ関連付けの正確性
- **Property 13**: 複数タグ関連付けの完全性
- **Property 24-29**: 6タブシステム関連（メモ種類別フィルタリング、テキスト選択、スワイプ操作、動的タブ表示、タブ設定）
- **Property 31-43**: 新要件対応（テキスト選択、スワイプナビゲーション、動的タブ表示、タブ設定）

**合計43のプロパティテスト**で包括的な品質保証を実現

### ユニットテスト
- Core Data操作の検証
- ビジネスロジックの動作確認
- エラーハンドリングの検証

## 🚦 開発状況

### ✅ 完了済み (Task 1)
- [x] Xcodeプロジェクト作成
- [x] Core Dataモデル定義（ArticleBookmark, TweetMemo, Tag）
- [x] PersistenceController実装
- [x] SwiftCheck統合
- [x] 基本プロパティテスト実装（Property 1, 6, 7, 12, 13）

### 🚧 進行中
- [ ] Task 2: ブックマーク管理機能（1.5日）
- [ ] Task 3: メモ種類別管理機能（1.5日）
- [ ] Task 4: タグ管理機能（1日）
- [ ] Task 5: アプリ内記事表示・テキスト選択・ブックマーク登録機能（2日）
- [ ] Task 6: 6タブ式ホーム画面・ナビゲーション（2日）
- [ ] Task 7: MVP完成・検証（0.5日）

**進捗**: 1/7タスク完了（14%）、推定残り時間: 6-7日

## 🛠️ 開発環境

### 必要な環境
- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 5.9+
- **macOS**: 14.0+ (開発用)

### セットアップ手順

1. **リポジトリクローン**
   ```bash
   git clone [repository-url]
   cd KiroBookmark
   ```

2. **Xcodeでプロジェクトを開く**
   ```bash
   open KiroBookmark.xcodeproj
   ```

3. **依存関係の確認**
   - SwiftCheck (Package Manager経由で自動取得)

4. **ビルド・実行**
   - iPhone 15 Simulator推奨
   - iOS 17.0+対応デバイス

## 📋 開発ルール

### コーディング規約
- **DRY原則**: 重複コードの排除
- **KISS原則**: シンプルで読みやすい実装
- **Swift API Design Guidelines**準拠
- **メソッド**: 最大20行
- **クラス**: 最大150行
- **View**: 最大100行

### Git Workflow
- **ブランチ**: `main`で直接開発（MVP期間中）
- **コミット**: `[Task X.Y] 機能名: 実装内容`
- **進捗**: `[Task X.Y completed]`で自動進捗更新

### テスト要件
- 新機能実装時は必ずテスト作成
- プロパティテスト: 最低100回実行
- ユニットテスト: エッジケース・エラー条件をカバー

## 📖 ドキュメント

- **要件定義**: [requirements.md](.kiro/specs/bookmark-manager/requirements.md)
- **設計書**: [design.md](.kiro/specs/bookmark-manager/design.md)
- **タスク管理**: [tasks.md](.kiro/specs/bookmark-manager/tasks.md)
- **プロジェクト管理**: [CLAUDE.md](CLAUDE.md)

## 🎯 Phase 1A 制約

### 実装対象
- ✅ 6タブシステム（New Entry, Bookmark, Todo, アイディア, 感想, その他）
- ✅ ブックマーク基本機能（カード表示のみ）
- ✅ メモ種類別管理（アイディア、感想、TODO、引用、その他）
- ✅ テキスト選択・引用メモ機能
- ✅ スワイプナビゲーション・動的タブ表示
- ✅ タブカスタマイズ・設定画面
- ✅ タグ基本機能
- ✅ Core Data ローカル保存

### 除外機能（Phase 1B以降）
- ❌ RSS自動更新・通知
- ❌ 全文検索
- ❌ エクスポート機能
- ❌ AI要約・タグ推薦
- ❌ 写真添付
- ❌ サムネイル表示
- ❌ 読書進捗管理・ドメイン整理

## 🤝 コントリビューション

Phase 1A（1週間MVP）は集中開発期間のため、外部コントリビューションは一時停止中です。Phase 1B以降でコントリビューションガイドラインを整備予定です。

## 📄 ライセンス

[ライセンス情報を追加予定]

## 📞 お問い合わせ

プロジェクトに関するご質問・ご提案は、Issuesまたは以下までお気軽にお寄せください。

---

**KiroBookmark** - AIエンジニアの技術学習を加速する 🚀