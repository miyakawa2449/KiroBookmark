# Implementation Plan: Bookmark Manager (Phase 1A - 1週間MVP)

## Overview

Phase 1Aでは、最初の1週間で動作する超シンプルなMVPを実装します。2タブ + サイドメニュー式ホーム画面（New Entry, Bookmark + サイドメニュー）、ブックマーク管理、メモ種類別管理、タグ付けの基本機能のみに集中し、Core Dataによるローカル保存で実装します。SwiftUIとSwiftを使用してネイティブiOSアプリとして開発します。

**Phase 1A（1週間MVP）**: 2タブ + サイドメニュー式ホーム画面・ブックマーク・メモ種類別管理・タグの基本機能のみ
**Phase 1B（後日実装）**: RSS自動更新、検索、エクスポート、通知、関連記事提案

## 🏠 新しい2タブ + サイドメニューホーム画面仕様

### UI構造
- **2タブ式ナビゲーション**: New EntryとBookmarkの2タブのみ
- **「New Entry」タブ**: お気に入りブログの最新記事を投稿日時順でカード表示
- **「Bookmark」タブ**: ユーザー登録記事を最新アクティビティ順でカード表示
- **サイドメニュー（右スワイプ）**: いいね、アイディア、感想、TODO、その他
- **ヘッダー中央**: アプリアイコン（後日追加）
- **表示形式**: カード表示のみ（リスト表示は削除）

### 新機能要件
- **2タブシステム**: New EntryとBookmarkのシンプルなタブ表示
- **サイドメニュー**: 右スワイプで表示、メモ種類別フィルタリング
- **未使用メニュー項目の非表示**: メモが存在しないメニュー項目は自動的に非表示
- **カスタマイズ可能メニュー順序**: 設定画面でメニュー項目の並び順を変更可能
- **テキスト選択機能**: WebView内でテキスト選択して引用メモ作成
- ブログお気に入り機能（Phase 1B: 通知連携）
- 記事お気に入り機能
- 最新アクティビティ順ソート（ブックマーク日時、メモ追加日時、お気に入り設定日時）
- **アプリ内記事表示機能**（WebView + テキスト選択）
- **スクロール停止時ブックマーク登録機能**

## 🎯 Phase 1A 進捗状況

**完了**: 7/7 タスク (100%) ✅
**Phase 1A MVP 完了**

## Tasks (Phase 1A - 1週間MVP)

### ✅ 完了済み

- [x] **Task 1: プロジェクト初期設定とCore Dataセットアップ** ✅
  - [x] Xcodeプロジェクト作成（iOS、SwiftUI、Core Data有効）
  - [x] Core Dataモデル定義（ArticleBookmark, TweetMemo, Tag）
  - [x] PersistenceController実装
  - [x] SwiftCheck統合
  - [x] 基本プロパティテスト実装（Property 1, 5, 6, 11, 12）
  - _Requirements: 1.1, 2.1, 3.1, 11.1_

- [x] **Task 2: ブックマーク管理機能** ✅
  - [x] 2.1 BookmarkRepository + お気に入りブログ機能実装
  - [x] 2.2 ブックマークカード表示UI実装
  - [x] 2.3 ブックマーク追加UI実装
  - [x] 2.4 ブックマーク機能テスト
  - _Validates: Requirements 1.1, 1.2, 1.3, 1.5_

- [x] **Task 3: メモ種類別管理機能** ✅
  - [x] 3.1 MemoManager + Repository実装（メモ種類対応）
  - [x] 3.2 メモ種類別表示・編集UI実装
  - [x] 3.3 メモ機能テスト
  - _Validates: Requirements 2.1, 2.2, 2.4, 2.5, 2.6, 13.1, 13.2, 13.3, 13.5_

- [x] **Task 4: タグ管理機能** ✅
  - [x] 4.1 TagManager + Repository実装
  - [x] 4.2 タグ選択・管理UI実装
  - [x] 4.3 タグ機能テスト
  - _Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] **Task 5: アプリ内記事表示・テキスト選択・ブックマーク登録機能** ✅
  - [x] 5.1 WebView記事表示機能実装
  - [x] 5.2 テキスト選択・引用メモ機能実装
  - [x] 5.3 スクロール停止検知・ブックマーク登録UI実装
  - [x] 5.4 記事表示機能テスト（Property 24, 25）
  - _Validates: Requirements 1.1, 2.1, 10.1, 10.2, 19.1, 19.3, 19.4_

- [x] **Task 6: 2タブ + サイドメニュー式ホーム画面・ナビゲーション** ✅
  - [x] 6.1 2タブ + サイドメニュー式ホーム画面実装
  - [x] 6.2 サイドメニュー・動的メニュー表示実装
  - [x] 6.3 カード表示統一・ソート機能実装
  - [x] 6.4 設定画面・メニューカスタマイズ実装
  - [x] 6.5 記事詳細画面実装
  - [x] 6.6 統合テスト（Property 26, 27, 28）
  - _Validates: Requirements 10.1, 10.2, 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

- [x] **Task 7: MVP完成・検証** ✅
  - [x] 7.1 最終動作確認
    - 全68テスト成功
    - ビルド成功（エラーなし）
    - Core Data保存・読み込み確認済み
  - [x] 7.2 ドキュメント更新
    - README.md更新完了
    - 既知の制限事項を記録
  - [x] 7.3 Phase 1B準備
    - 技術的負債: Swift 6 Concurrency警告
    - Phase 1B機能: RSS、検索、エクスポート、AI機能

## 📋 実装ガイドライン

### アーキテクチャパターン
- **MVVM + Repository Pattern**: ViewModel ↔ Repository ↔ Core Data
- **Dependency Injection**: Repository を ViewModel に注入
- **Single Responsibility**: 各クラスは単一の責務を持つ

### 🛠️ 開発環境・ツール連携

#### Kiro（仕様管理）
- 要件定義・設計の管理
- タスク進捗の追跡
- 仕様変更の影響分析
- design.md、tasks.md、requirements.mdの管理

#### Claude Code（実装・レビュー）
- コード実装
- Agent Skills自動実行
  - **ios-security**: Keychain使用、ATS設定、OWASP準拠チェック
  - **swiftui-review**: View200行以下、MVVM遵守、パフォーマンス・アクセシビリティ
  - **swift-build**: ビルド・テスト実行（iOS/macOS対応）
  - **appstore-prep**: App Store申請前チェックリスト
- MCP連携
  - **GitHub MCP**: PR/Issue管理
  - **Filesystem MCP**: ローカルファイル操作
  - **Sequential Thinking MCP**: 複雑な設計判断の段階的思考支援

#### タスク完了条件（必須チェック項目）
各タスク完了時に以下を確認：
- [ ] **SwiftLint警告0**: コード品質基準を満たす
- [ ] **セキュリティチェック通過**: ios-security Skillによる検証
  - Keychain使用（機密情報保存時）
  - ATS無効化なし
  - ハードコードされたシークレットなし
- [ ] **SwiftUIコンポーネント200行以下**: swiftui-review Skillによる検証
  - View肥大化の防止
  - 適切なコンポーネント分割
- [ ] **ビルド・テスト成功**: swift-build Skillによる検証
  - iOS Simulatorでビルド成功
  - 全ユニットテスト通過
- [ ] **プロパティテスト通過**: 該当するプロパティテストが全て成功
- [ ] **MVVM遵守**: ビジネスロジックがViewModelに分離されている

#### 役割分担
- **設計判断**: Kiroで仕様を確認・更新
- **実装**: Claude Codeで実装・Skills自動実行
- **品質保証**: 両者連携でチェック項目を確認

### 実装順序の理由
1. **Task 2 (ブックマーク)**: 基盤となるデータ管理機能 + お気に入りブログ機能
2. **Task 3 (メモ)**: ブックマークに依存する機能
3. **Task 4 (タグ)**: ブックマークとメモに関連する機能
4. **Task 5 (WebView)**: アプリ内記事表示 + ブックマーク登録機能
5. **Task 6 (ホーム画面)**: Twitter風タブ式UI + カード表示統一
6. **Task 7 (検証)**: 完成品の品質確認

### テスト戦略
- **プロパティテスト**: 各機能の普遍的な性質を検証（SwiftCheck使用）
- **ユニットテスト**: Repository層のビジネスロジックを検証
- **統合テスト**: UI操作からデータ保存までの一連の流れを検証
- **Skills自動実行**: Claude Code側でセキュリティ・品質チェック自動実行
- **仕様整合性確認**: Kiro側で設計ドキュメントとの整合性確認

### Phase 1A 制約の再確認
- ✅ **実装対象**: 2タブ + サイドメニュー式ホーム画面・ブックマーク・メモ・タグの基本CRUD・お気に入り機能
- ❌ **除外機能**: RSS自動更新、通知、検索、エクスポート、AI機能、写真添付
- 🎯 **目標**: 1週間で動作する2タブ + サイドメニュー式MVPアプリ

### 新仕様による変更点
- **UI**: リスト表示削除、カード表示のみ
- **ホーム画面**: 2タブ（New Entry, Bookmark）+ サイドメニュー（いいね、アイディア、感想、TODO、その他）
- **スワイプ操作**: 右スワイプでサイドメニュー表示、左スワイプ・メニュー外タップで閉じる
- **動的メニュー**: 未使用メモタイプメニュー項目の自動非表示
- **テキスト選択**: WebView内でのテキスト選択・引用メモ作成
- **設定画面**: メニュー項目順序のカスタマイズ機能
- **ソート**: 投稿日時順 / 最新アクティビティ順 / メモ種類別
- **お気に入り**: ブログ・記事両方に対応
- **通知**: Phase 1Bに延期（基盤のみPhase 1Aで実装）
- **ヘッダー**: 中央にアプリアイコン（後日追加）

## Phase 1B Tasks (後日実装予定)

以下の機能は1週間MVP完成後に実装予定：

### ✅ 記事プレビューUI改善 (完了)

**目的**: カードタップで記事がワンタップで読めるように改善

| タスク | 内容 | 状態 |
|--------|------|------|
| Task 1 | ArticleCardViewのタップアクション変更（カード→WebView直接遷移） | ✅ 完了 |
| Task 2 | ArticleWebViewにツールバー追加（4ボタン: メモ、TODO、お気に入り、詳細） | ✅ 完了 |
| Task 3 | ツールバーアクション実装（TODO事前選択、お気に入りトグル等） | ✅ 完了 |
| Task 4 | ロングプレスメニュー実装（6アクション: 記事を読む、メモ追加、タグ編集、お気に入り、詳細、削除） | ✅ 完了 |
| Task 5 | ArticleDetailViewの調整（「記事を読む」ボタン削除、アイコンボタン化） | ✅ 完了 |

**Before**: カード → 詳細画面 → 「記事を読む」→ WebView（2タップ）
**After**: カード → WebView + ツールバー（1タップ）

**追加改善**:
- AddMemoSheet: 記事セクション削除で入力欄拡大
- ArticleDetailView: アクションボタンをアイコンのみに変更

### ✅ RSS自動検出・監視機能 (完了)
- [x] RSS自動検出・監視機能の実装

### ✅ 通知機能 (完了)
- [x] ローカル通知サービスの実装 (NotificationService) ✅
- [x] バックグラウンド更新サービスの実装 (BackgroundRefreshService) ✅
- [x] 通知設定画面の実装 (SettingsView) ✅
- [x] NewEntryViewModel への通知統合 ✅

### 🔍 検索・フィルタ機能
- [x] 統合検索機能の実装 ✅
- [x] 記事閲覧状態管理機能の実装 ✅
- [x] ドメイン整理機能の実装 ✅
- [x] 時間経過表示機能の実装 ✅

### ✅ New Entry/Bookmark分離・トースト通知 (完了)
- [x] New Entry/Bookmark タブ分離機能の実装 ✅
- [x] ブックマーク登録時のトースト通知機能の実装 ✅

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
- [ ] **2タブホーム画面**: 2タブ式UI（New Entry, Bookmark）が動作
- [ ] **サイドメニュー**: 右スワイプでメニュー表示、メモ種類別フィルタリングが動作
- [ ] **動的メニュー**: 未使用メモタイプメニュー項目の自動非表示が動作
- [ ] **設定画面**: メニュー項目順序カスタマイズが動作
- [ ] **統合**: 全機能が1つのアプリで連携動作
- [ ] **品質**: 全プロパティテスト・ユニットテストが通過

### 🚀 開発効率化のポイント
- **Repository Pattern**: Core Data操作を抽象化、テスト容易性向上
- **SwiftUI Preview**: UI開発の高速化
- **Property-Based Testing**: エッジケースの自動発見
- **MVVM**: UI とビジネスロジックの分離
- **2タブ + サイドメニュー**: シンプルなホーム画面とメモ種類別の効率的な記事管理
- **スワイプ操作**: 直感的なサイドメニュー表示
- **動的UI**: 未使用メニュー項目の自動非表示による最適化

### 📊 進捗追跡
- **Daily Standup**: 毎日の進捗確認
- **Git Commit**: `[Task X.Y completed]` で自動進捗更新
- **Quality Check**: 各タスク完了時のコード品質確認

### 🔄 Phase 1B への準備
- **技術的負債**: Phase 1A で妥協した部分の記録
- **拡張ポイント**: RSS、検索、AI機能の実装準備
- **パフォーマンス**: 大量データ対応の検討事項
- **2タブ + サイドメニュー拡張**: カスタムメモタイプ追加機能の準備

## 🧪 新しいプロパティテスト（2タブ + サイドメニューシステム対応）

### Property 23: メモ種類別フィルタリング
*For any* memo type, when filtering articles by memo type, the system should return only articles that have memos of that specific type
**Validates: Requirements 13.5**

### Property 24: テキスト選択の正確性
*For any* selected text in WebView, the system should accurately capture the selected text content without modification
**Validates: Requirements 19.1**

### Property 25: 引用メモの完全性
*For any* selected text, when creating a quote memo, the system should include both the selected text and the source URL
**Validates: Requirements 19.3, 19.4**

### Property 26: サイドメニュー項目の動的表示
*For any* memo type with zero associated articles, the corresponding side menu item should be automatically hidden
**Validates: Requirements 21.1, 21.3**

### Property 27: サイドメニュー開閉の一貫性
*For any* swipe gesture, when a user swipes right, the side menu should open, and when swiping left or tapping outside, it should close
**Validates: Requirements 20.1, 20.2, 20.3**

### Property 28: メニュー設定の永続性
*For any* menu configuration change, when the user changes menu item order or visibility, the new configuration should persist across app restarts
**Validates: Requirements 22.4**