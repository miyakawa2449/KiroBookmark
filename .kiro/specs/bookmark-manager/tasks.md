# Implementation Plan: Bookmark Manager (Phase 1A - 1週間MVP)

## Overview

Phase 1Aでは、最初の1週間で動作する超シンプルなMVPを実装します。6タブ式ホーム画面（New Entry, Bookmark, Todo, アイディア, 感想, その他）、ブックマーク管理、メモ種類別管理、タグ付けの基本機能のみに集中し、Core Dataによるローカル保存で実装します。SwiftUIとSwiftを使用してネイティブiOSアプリとして開発します。

**Phase 1A（1週間MVP）**: 6タブ式ホーム画面・ブックマーク・メモ種類別管理・タグの基本機能のみ
**Phase 1B（後日実装）**: RSS自動更新、検索、エクスポート、通知、関連記事提案

## 🏠 新しい6タブホーム画面仕様

### UI構造
- **6タブ式ナビゲーション**: スワイプ可能なタブシステム
- **「New Entry」タブ**: お気に入りブログの最新記事を投稿日時順でカード表示
- **「Bookmark」タブ**: ユーザー登録記事を最新アクティビティ順でカード表示
- **「Todo」タブ**: TODOメモを持つ記事のみ表示
- **「アイディア」タブ**: アイディアメモを持つ記事のみ表示
- **「感想」タブ**: 感想メモを持つ記事のみ表示
- **「その他」タブ**: その他メモを持つ記事のみ表示
- **表示形式**: カード表示のみ（リスト表示は削除）

### 新機能要件
- **6タブシステム**: メモ種類別のタブ表示
- **スワイプ可能タブ**: 左右スワイプでタブ切り替え
- **未使用タブの非表示**: メモが存在しないタブは自動的に非表示
- **カスタマイズ可能タブ順序**: 設定画面でタブの並び順を変更可能
- **テキスト選択機能**: WebView内でテキスト選択して引用メモ作成
- ブログお気に入り機能（Phase 1B: 通知連携）
- 記事お気に入り機能
- 最新アクティビティ順ソート（ブックマーク日時、メモ追加日時、お気に入り設定日時）
- **アプリ内記事表示機能**（WebView + テキスト選択）
- **スクロール停止時ブックマーク登録機能**

## 🎯 Phase 1A 進捗状況

**完了**: 1/7 タスク (14%)
**推定残り時間**: 6-7日

## Tasks (Phase 1A - 1週間MVP)

### ✅ 完了済み

- [x] **Task 1: プロジェクト初期設定とCore Dataセットアップ** ✅
  - [x] Xcodeプロジェクト作成（iOS、SwiftUI、Core Data有効）
  - [x] Core Dataモデル定義（ArticleBookmark, TweetMemo, Tag）
  - [x] PersistenceController実装
  - [x] SwiftCheck統合
  - [x] 基本プロパティテスト実装（Property 1, 6, 7, 12, 13）
  - _Requirements: 1.1, 2.1, 3.1, 11.1_

### 🚧 実装予定

- [ ] **Task 2: ブックマーク管理機能** (推定: 1.5日)
  - [ ] 2.1 BookmarkRepository + お気に入りブログ機能実装
    - BookmarkRepository クラス実装（CRUD操作）
    - FavoriteBlogRepository クラス実装
    - URL検証とメタデータ取得機能
    - お気に入りブログ管理機能
    - エラーハンドリング実装
    - _Requirements: 1.1, 1.2, 1.5_

  - [ ] 2.2 ブックマークカード表示UI実装
    - BookmarkCardView（SwiftUI）作成
    - BookmarkListViewModel実装
    - カード表示（タイトル、URL、日付、サムネイル領域）
    - スワイプ削除・お気に入り機能
    - _Requirements: 1.3_

  - [ ] 2.3 ブックマーク追加UI実装
    - AddBookmarkView（SwiftUI）作成
    - URL入力フォーム
    - バリデーション表示
    - お気に入りブログ自動判定
    - _Requirements: 1.1_

  - [ ] 2.4 ブックマーク機能テスト
    - **Property 2: ブックマーク削除の完全性**
    - **Property 3: ブックマーク表示の完全性**
    - **Property 5: ブックマーク編集の永続性**
    - **Property 17: お気に入りブログ関連付け**
    - ユニットテスト（BookmarkRepository, FavoriteBlogRepository）
    - _Validates: Requirements 1.1, 1.2, 1.3, 1.5_

- [ ] **Task 3: メモ種類別管理機能** (推定: 1.5日)
  - [ ] 3.1 MemoManager + Repository実装（メモ種類対応）
    - MemoRepository クラス実装（CRUD操作 + メモ種類フィルタリング）
    - 140文字制限バリデーション
    - メモ種類別時系列ソート機能
    - メモ種類別カウント機能
    - _Requirements: 2.1, 2.2, 2.4, 2.5, 13.1, 13.2_

  - [ ] 3.2 メモ種類別表示・編集UI実装
    - MemoListView（SwiftUI）作成（種類別フィルタリング対応）
    - MemoDetailView（SwiftUI）作成
    - AddMemoView（SwiftUI）作成（メモ種類選択機能）
    - 文字数カウンター表示
    - メモ種類アイコン・色分け表示
    - _Requirements: 2.6, 13.3, 13.4_

  - [ ] 3.3 メモ機能テスト
    - **Property 9: メモ編集の更新記録**
    - **Property 10: メモ削除の完全性**
    - **Property 11: メモ時系列表示**
    - **Property 24: メモ種類別フィルタリング**
    - ユニットテスト（MemoRepository + 種類別機能）
    - _Validates: Requirements 2.1, 2.2, 2.4, 2.5, 2.6, 13.1, 13.2, 13.3, 13.4_

- [ ] **Task 4: タグ管理機能** (推定: 1日)
  - [ ] 4.1 TagManager + Repository実装
    - TagRepository クラス実装（CRUD操作）
    - 使用頻度カウント機能
    - 重複タグ防止機能
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 4.2 タグ選択・管理UI実装
    - TagSelectionView（SwiftUI）作成
    - TagListView（SwiftUI）作成
    - タグ追加・編集・削除機能
    - 使用頻度順表示
    - _Requirements: 3.4, 3.5_

  - [ ] 4.3 タグ機能テスト
    - **Property 14: タグ削除の一貫性**
    - **Property 15: タグ使用頻度順表示**
    - **Property 16: タグ編集の伝播**
    - ユニットテスト（TagRepository）
    - _Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] **Task 5: アプリ内記事表示・テキスト選択・ブックマーク登録機能** (推定: 2日)
  - [ ] 5.1 WebView記事表示機能実装
    - ArticleWebView（SwiftUI + WKWebView）作成
    - URL読み込み・表示機能
    - 読み込み状態表示（ローディング、エラー）
    - ナビゲーション機能（戻る、進む、リロード）
    - _Requirements: 10.1, 10.2_

  - [ ] 5.2 テキスト選択・引用メモ機能実装
    - WebView内テキスト選択機能
    - 選択テキスト取得機能
    - 引用メモ作成UI（選択テキスト自動挿入）
    - 引用元URL自動記録機能
    - _Requirements: 2.1, 13.1_

  - [ ] 5.3 スクロール停止検知・ブックマーク登録UI実装
    - スクロール停止検知機能
    - フローティングブックマーク登録ボタン
    - ボタン表示・非表示アニメーション
    - ブックマーク登録処理
    - 重複登録防止機能
    - _Requirements: 1.1_

  - [ ] 5.4 記事表示機能テスト
    - **Property 18: WebView記事表示の完全性**
    - **Property 19: ブックマーク登録の一意性**
    - **Property 25: テキスト選択の正確性**
    - **Property 26: 引用メモの完全性**
    - ユニットテスト（WebView機能、スクロール検知、テキスト選択）
    - _Validates: Requirements 1.1, 2.1, 10.1, 10.2, 13.1_

- [ ] **Task 6: 6タブ式ホーム画面・ナビゲーション** (推定: 2日)
  - [ ] 6.1 6タブ式ホーム画面実装
    - HomeView（SwiftUI）作成 - 6タブシステム
    - NewEntryTabView（SwiftUI）作成 - お気に入りブログの最新記事
    - BookmarkTabView（SwiftUI）作成 - ユーザー登録記事
    - TodoTabView（SwiftUI）作成 - TODOメモ記事のみ
    - IdeaTabView（SwiftUI）作成 - アイディアメモ記事のみ
    - ThoughtTabView（SwiftUI）作成 - 感想メモ記事のみ
    - OtherTabView（SwiftUI）作成 - その他メモ記事のみ
    - HomeViewModel実装 - タブ状態管理・メモ種類別フィルタリング
    - _Requirements: 10.1, 10.2, 13.4_

  - [ ] 6.2 スワイプ可能タブ・動的タブ表示実装
    - スワイプジェスチャーによるタブ切り替え
    - 未使用メモタイプタブの自動非表示機能
    - タブ表示状態の動的更新
    - タブインジケーター・アニメーション
    - _Requirements: 13.4_

  - [ ] 6.3 カード表示統一・ソート機能実装
    - ArticleCardView（SwiftUI）作成 - 統一カードコンポーネント
    - 投稿日時順ソート（New Entryタブ）
    - 最新アクティビティ順ソート（Bookmarkタブ）
    - メモ種類別ソート（Todo/アイディア/感想/その他タブ）
    - カード表示最適化（画像領域、テキスト配置、メモ種類表示）
    - カードタップ → ArticleWebView遷移
    - _Requirements: 10.1, 10.2, 13.3_

  - [ ] 6.4 設定画面・タブカスタマイズ実装
    - SettingsView（SwiftUI）作成
    - タブ順序カスタマイズ機能
    - タブ表示/非表示設定
    - 設定データの永続化
    - _Requirements: 13.5_

  - [ ] 6.5 記事詳細画面実装
    - ArticleDetailView（SwiftUI）作成
    - 記事情報表示
    - メモ種類別一覧表示
    - タグ表示・編集
    - お気に入り切り替え
    - WebView表示ボタン
    - _Requirements: 10.1, 10.2, 13.3_

  - [ ] 6.6 統合テスト
    - 6タブ切り替えテスト
    - スワイプ操作テスト
    - 動的タブ表示テスト
    - メモ種類別フィルタリングテスト
    - カード表示テスト
    - WebView遷移テスト
    - ソート機能テスト
    - UI操作フローテスト
    - データ整合性テスト
    - _Requirements: 10.1, 10.2, 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] **Task 7: MVP完成・検証** (推定: 0.5日)
  - [ ] 7.1 最終動作確認
    - 全機能の動作テスト
    - Core Data保存・読み込み確認
    - WebView機能確認
    - エラーハンドリング確認
    - パフォーマンス確認

  - [ ] 7.2 ドキュメント更新
    - README.md更新
    - 完成機能の記録
    - 既知の問題・制限事項の記録

  - [ ] 7.3 Phase 1B準備
    - Phase 1B要件の再確認
    - 技術的負債の記録
    - 次フェーズの優先順位決定

## 📋 実装ガイドライン

### アーキテクチャパターン
- **MVVM + Repository Pattern**: ViewModel ↔ Repository ↔ Core Data
- **Dependency Injection**: Repository を ViewModel に注入
- **Single Responsibility**: 各クラスは単一の責務を持つ

### 実装順序の理由
1. **Task 2 (ブックマーク)**: 基盤となるデータ管理機能 + お気に入りブログ機能
2. **Task 3 (メモ)**: ブックマークに依存する機能
3. **Task 4 (タグ)**: ブックマークとメモに関連する機能
4. **Task 5 (WebView)**: アプリ内記事表示 + ブックマーク登録機能
5. **Task 6 (ホーム画面)**: Twitter風タブ式UI + カード表示統一
6. **Task 7 (検証)**: 完成品の品質確認

### テスト戦略
- **プロパティテスト**: 各機能の普遍的な性質を検証
- **ユニットテスト**: Repository層のビジネスロジックを検証
- **統合テスト**: UI操作からデータ保存までの一連の流れを検証

### Phase 1A 制約の再確認
- ✅ **実装対象**: Twitter風ホーム画面・ブックマーク・メモ・タグの基本CRUD・お気に入り機能
- ❌ **除外機能**: RSS自動更新、通知、検索、エクスポート、AI機能、写真添付
- 🎯 **目標**: 1週間で動作するTwitter風MVPアプリ

### 新仕様による変更点
- **UI**: リスト表示削除、カード表示のみ
- **ホーム画面**: 6タブ式（New Entry, Bookmark, Todo, アイディア, 感想, その他）
- **スワイプ操作**: タブ間の左右スワイプ切り替え
- **動的タブ**: 未使用メモタイプタブの自動非表示
- **テキスト選択**: WebView内でのテキスト選択・引用メモ作成
- **設定画面**: タブ順序のカスタマイズ機能
- **ソート**: 投稿日時順 / 最新アクティビティ順 / メモ種類別
- **お気に入り**: ブログ・記事両方に対応
- **通知**: Phase 1Bに延期（基盤のみPhase 1Aで実装）

## Phase 1B Tasks (後日実装予定)

以下の機能は1週間MVP完成後に実装予定：

### 🔔 通知・RSS機能
- [ ] RSS自動検出・監視機能の実装
- [ ] ブログ更新通知機能の実装
- [ ] 記事更新通知機能の実装
- [ ] Push通知設定画面の実装

### 🔍 検索・フィルタ機能
- [ ] 統合検索機能の実装
- [ ] 読書進捗管理機能の実装
- [ ] ドメイン整理機能の実装
- [ ] 時間経過表示機能の実装

### 📤 エクスポート・AI機能
- [ ] エクスポート機能の実装
- [ ] 関連記事自動提案機能の実装
- [ ] メモ種類分類機能の実装
- [ ] 写真添付機能の実装
- [ ] オプション機能（AI要約・タグ推薦）の実装
- [ ] オプション機能（AI要約・タグ推薦）の実装

## Notes

### 🎯 Phase 1A Success Criteria
- [x] **基盤**: Core Data + SwiftUI + プロパティテスト環境
- [ ] **ブックマーク**: URL追加・カード表示・削除・お気に入り機能が動作
- [ ] **メモ**: 記事ごとに複数メモ追加・編集・削除・種類別分類が動作
- [ ] **タグ**: 記事にタグ付け・タグ管理が動作
- [ ] **WebView**: アプリ内記事表示・テキスト選択・スクロール停止時ブックマーク登録が動作
- [ ] **6タブホーム画面**: 6タブ式UI（New Entry, Bookmark, Todo, アイディア, 感想, その他）が動作
- [ ] **スワイプ操作**: タブ間のスワイプ切り替えが動作
- [ ] **動的タブ**: 未使用メモタイプタブの自動非表示が動作
- [ ] **設定画面**: タブ順序カスタマイズが動作
- [ ] **統合**: 全機能が1つのアプリで連携動作
- [ ] **品質**: 全プロパティテスト・ユニットテストが通過

### 🚀 開発効率化のポイント
- **Repository Pattern**: Core Data操作を抽象化、テスト容易性向上
- **SwiftUI Preview**: UI開発の高速化
- **Property-Based Testing**: エッジケースの自動発見
- **MVVM**: UI とビジネスロジックの分離
- **6タブシステム**: メモ種類別の効率的な記事管理
- **スワイプ操作**: 直感的なタブ切り替え
- **動的UI**: 未使用タブの自動非表示による最適化

### 📊 進捗追跡
- **Daily Standup**: 毎日の進捗確認
- **Git Commit**: `[Task X.Y completed]` で自動進捗更新
- **Quality Check**: 各タスク完了時のコード品質確認

### 🔄 Phase 1B への準備
- **技術的負債**: Phase 1A で妥協した部分の記録
- **拡張ポイント**: RSS、検索、AI機能の実装準備
- **パフォーマンス**: 大量データ対応の検討事項
- **6タブシステム拡張**: カスタムメモタイプ追加機能の準備

## 🧪 新しいプロパティテスト（6タブシステム対応）

### Property 24: メモ種類別フィルタリング
*For any* memo type, when filtering articles by memo type, the system should return only articles that have memos of that specific type
**Validates: Requirements 13.4**

### Property 25: テキスト選択の正確性
*For any* selected text in WebView, the system should accurately capture the selected text content without modification
**Validates: Requirements 2.1**

### Property 26: 引用メモの完全性
*For any* selected text, when creating a quote memo, the system should include both the selected text and the source URL
**Validates: Requirements 2.1, 13.1**

### Property 27: タブ表示の動的性
*For any* memo type with zero associated articles, the corresponding tab should be automatically hidden from the tab bar
**Validates: Requirements 13.4**

### Property 28: スワイプタブ切り替えの一貫性
*For any* tab position, when swiping left or right, the system should transition to the adjacent tab in the correct direction
**Validates: Requirements 10.1**

### Property 29: タブ順序カスタマイズの永続性
*For any* custom tab order configuration, when the user changes the tab order in settings, the new order should be saved and persist across app restarts
**Validates: Requirements 13.5**