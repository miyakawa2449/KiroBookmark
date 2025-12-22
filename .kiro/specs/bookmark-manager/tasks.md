# Implementation Plan: Bookmark Manager (Phase 1 - iPhone MVP)

## Overview

Phase 1では、iPhoneアプリのMVPを実装します。Core Dataによるローカル保存、基本的なブックマーク・メモ・タグ機能、RSS検出（手動更新）を含みます。SwiftUIとSwiftを使用してネイティブiOSアプリとして開発します。

## Tasks

- [ ] 1. プロジェクト初期設定とCore Dataセットアップ
  - Xcodeプロジェクト作成（iOS、SwiftUI、Core Data有効）
  - Core Dataモデル定義（ArticleBookmark, TweetMemo, Tag, RSSFeed, DomainCustomization, ExportHistory）
  - 基本的なCore Dataスタック設定
  - _Requirements: 1.1, 2.1, 3.1, 11.1_

- [ ] 1.1 Core Dataモデルのプロパティテスト作成
  - **Property 1: ブックマーク追加の一貫性**
  - **Validates: Requirements 1.1**

- [ ] 2. ブックマーク管理機能の実装
  - [ ] 2.1 ArticleBookmarkエンティティとCRUD操作実装
    - ArticleBookmark Core Dataエンティティ作成
    - BookmarkManager クラス実装（追加、削除、更新、取得）
    - URL検証とメタデータ取得機能
    - _Requirements: 1.1, 1.2, 1.5_

  - [ ] 2.2 ブックマーク操作のプロパティテスト
    - **Property 1: ブックマーク追加の一貫性**
    - **Property 2: ブックマーク削除の完全性**
    - **Property 5: ブックマーク編集の永続性**
    - **Validates: Requirements 1.1, 1.2, 1.5**

  - [ ] 2.3 ブックマーク一覧表示UI実装
    - BookmarkListView（SwiftUI）作成
    - サムネイル表示とリスト表示の切り替え機能
    - 時間経過表示機能
    - _Requirements: 1.3, 1.4, 7.1-7.5_

  - [ ] 2.4 表示機能のプロパティテスト
    - **Property 3: ブックマーク表示の完全性**
    - **Property 4: 表示モード切り替えの一貫性**
    - **Validates: Requirements 1.3, 1.4**

- [ ] 3. Twitter風メモ機能の実装
  - [ ] 3.1 TweetMemoエンティティとCRUD操作実装
    - TweetMemo Core Dataエンティティ作成
    - MemoManager クラス実装
    - 140文字制限バリデーション
    - 写真添付機能（最大4枚）
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ] 3.2 メモ機能のプロパティテスト
    - **Property 6: メモ追加の関連付け**
    - **Property 7: メモ文字数制限**
    - **Property 8: 写真添付制限**
    - **Property 9: メモ編集の更新記録**
    - **Property 10: メモ削除の完全性**
    - **Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5**

  - [ ] 3.3 メモ種類分類機能実装
    - MemoType enum実装とUI統合
    - メモ作成時の種別選択UI
    - メモ種別フィルタリング機能
    - カスタムメモ種別作成機能
    - _Requirements: 13.1, 13.2, 13.4, 13.5_

  - [ ] 3.4 メモ表示UI実装
    - MemoListView（SwiftUI）作成
    - メモ種別の視覚的区別
    - 時系列順表示
    - 写真表示機能
    - _Requirements: 2.6, 13.3_

  - [ ] 3.5 メモ表示のプロパティテスト
    - **Property 11: メモ時系列表示**
    - **Validates: Requirements 2.6**

- [ ] 4. タグ管理機能の実装
  - [ ] 4.1 Tagエンティティとタグ管理機能実装
    - Tag Core Dataエンティティ作成
    - TagManager クラス実装
    - タグの追加、削除、編集機能
    - 使用頻度カウント機能
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ] 4.2 タグ管理のプロパティテスト
    - **Property 12: タグ関連付け**
    - **Property 13: 複数タグ関連付け**
    - **Property 14: タグ削除の一貫性**
    - **Property 15: タグ使用頻度順表示**
    - **Property 16: タグ編集の伝播**
    - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5**

  - [ ] 4.3 タグ表示・選択UI実装
    - TagSelectionView（SwiftUI）作成
    - タグ一覧表示（使用頻度順）
    - タグ編集・削除機能
    - _Requirements: 3.4, 3.5_

- [ ] 4.5. ドメイン整理機能の実装
  - [ ] 4.5.1 DomainManagerとドメイン機能実装
    - DomainManager クラス実装
    - ドメイン自動抽出機能
    - ドメイン表示名カスタマイズ機能
    - ドメイン内記事並び替え機能
    - _Requirements: 4.1, 4.2, 4.4, 4.5_

  - [ ] 4.5.2 ドメイン表示UI実装
    - DomainGroupView（SwiftUI）作成
    - ドメイン別グループ表示
    - ドメイングループ展開・折りたたみ
    - ドメイン名編集機能
    - _Requirements: 4.2, 4.3, 4.4_

  - [ ] 4.5.3 ドメイン機能のユニットテスト
    - ドメイン抽出のテスト
    - グループ化機能のテスト
    - 並び替え機能のテスト
    - _Requirements: 4.1-4.5_

- [ ] 5. 時間経過表示機能の実装
  - [ ] 5.1 TimeDisplayService実装
    - 時間経過計算ロジック
    - 表示形式変換（X時間前、X日前、日付）
    - 新着記事の強調表示判定
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

  - [ ] 5.2 時間表示のユニットテスト
    - 時間経過計算のテスト
    - 表示形式のテスト
    - 強調表示判定のテスト
    - _Requirements: 7.1-7.5_

- [ ] 6. 検索機能の実装
- [ ] 6. 検索機能の実装
  - [ ] 6.1 検索エンジンとインデックス機能実装
    - SearchEngine クラス作成
    - 全文検索インデックス構築
    - キーワード、タグ、メモ種別、ドメイン検索
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 14.1, 14.2_

  - [ ] 6.2 全文検索機能実装
    - 記事本文取得・インデックス化
    - 検索結果ハイライト機能
    - 検索インデックス更新機能
    - _Requirements: 14.1, 14.2, 14.4, 14.5_

  - [ ] 6.3 検索機能のユニットテスト
    - 各種検索条件のテスト
    - 複合検索のテスト
    - 検索結果の関連度テスト
    - 全文検索のテスト
    - _Requirements: 5.1-5.5, 14.1-14.5_

  - [ ] 6.4 検索UI実装
    - SearchView（SwiftUI）作成
    - 検索フィルター機能
    - 検索結果表示
    - ハイライト表示機能
    - _Requirements: 5.1-5.5, 14.4_

- [ ] 7. RSS機能の実装（手動更新版）
- [ ] 7. RSS機能の実装（手動更新版）
  - [ ] 7.1 RSS検出・取得機能実装
    - FeedDetector クラス作成
    - HTMLからのRSSフィード自動検出
    - RSSパーサー実装
    - _Requirements: 12.1, 12.2, 12.3_

  - [ ] 7.2 RSS機能のプロパティテスト
    - **Property 17: RSS自動検出の試行**
    - **Property 18: RSS検出後の自動追加**
    - **Property 19: RSS検出失敗時のフォールバック**
    - **Validates: Requirements 12.1, 12.2, 12.3**

  - [ ] 7.3 RSS管理UI実装
    - FeedListView（SwiftUI）作成
    - 手動更新ボタン
    - フィード一覧表示
    - _Requirements: 12.6, 12.7_

- [ ] 8. 読書進捗管理機能の実装
- [ ] 8. 読書進捗管理機能の実装
  - [ ] 8.1 読書状況管理機能実装
    - ReadingProgressManager クラス実装
    - ReadingStatus enum実装
    - 状態変更ロジック
    - フィルタリング機能
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [ ] 8.2 読書進捗管理のユニットテスト
    - 状態遷移のテスト
    - フィルタリング機能のテスト
    - _Requirements: 6.1-6.6_

  - [ ] 8.3 読書状況表示UI実装
    - 読書状況の視覚的表示
    - 状況別フィルター
    - _Requirements: 6.5, 6.6_

- [ ] 9. エクスポート機能の実装
  - [ ] 9.1 ExportService実装
    - Markdown形式エクスポート機能
    - JSON形式エクスポート機能
    - エクスポートフィルター機能
    - ファイル名生成・保存機能
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

  - [ ] 9.2 エクスポート機能のユニットテスト
    - Markdown出力のテスト
    - JSON出力のテスト
    - フィルタリング機能のテスト
    - ファイル保存のテスト
    - _Requirements: 15.1-15.5_

  - [ ] 9.3 エクスポートUI実装
    - ExportView（SwiftUI）作成
    - 形式選択機能
    - フィルター設定機能
    - エクスポート実行・ダウンロード機能
    - _Requirements: 15.1-15.5_

- [ ] 10. 関連記事自動提案機能の実装
  - [ ] 10.1 RecommendationEngine実装
    - 関連記事計算アルゴリズム
    - タグ一致度・キーワード類似度計算
    - 学習機能（ユーザー行動記録）
    - _Requirements: 16.1, 16.2, 16.5_

  - [ ] 10.2 関連記事提案のユニットテスト
    - 関連度計算のテスト
    - 提案数制限のテスト
    - 学習機能のテスト
    - _Requirements: 16.1-16.5_

  - [ ] 10.3 関連記事表示UI実装
    - RelatedArticlesView（SwiftUI）作成
    - 関連記事一覧表示
    - 関連度表示機能
    - _Requirements: 16.3, 16.4_

- [ ] 11. メイン画面とナビゲーションの実装
- [ ] 11. メイン画面とナビゲーションの実装
  - [ ] 11.1 メインUI構造実装
    - ContentView（SwiftUI）作成
    - タブナビゲーション
    - ブックマーク一覧、検索、設定画面
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

  - [ ] 11.2 UI機能のユニットテスト
    - ナビゲーション機能のテスト
    - 表示切り替えのテスト
    - _Requirements: 10.1-10.5_

- [ ] 12. Checkpoint - 基本機能テスト
  - すべての基本機能が動作することを確認
  - Core Data保存・読み込みテスト
  - UI操作の動作確認
  - ユーザーに質問があれば確認

- [ ] 13. オプション機能の実装
  - [ ] 13.1 AI要約機能実装（オプション）
    - AI API連携（OpenAI等）
    - 要約生成・表示機能
    - エラーハンドリング
    - _Requirements: 17.1, 17.2_

  - [ ] 13.2 AI機能のプロパティテスト（オプション）
    - **Property 20: AI要約生成**
    - **Property 21: 要約文数制限**
    - **Validates: Requirements 17.1, 17.2**

  - [ ] 13.3 タグ自動推薦機能実装（オプション）
    - タグ推薦ロジック
    - 推薦UI実装
    - _Requirements: 18.1, 18.2_

  - [ ] 13.4 タグ推薦のプロパティテスト（オプション）
    - **Property 22: タグ推薦生成**
    - **Property 23: 推薦タグ数制限**
    - **Validates: Requirements 18.1, 18.2**

- [ ] 14. 最終統合テストと調整
  - [ ] 14.1 統合テスト実行
    - 全機能の統合動作確認
    - パフォーマンステスト
    - メモリリーク確認

  - [ ] 14.2 UI/UX調整
    - ダークモード対応確認
    - アクセシビリティ対応
    - エラーメッセージ改善

- [ ] 15. Final Checkpoint - MVP完成確認
  - すべてのテストが通ることを確認
  - アプリが安定して動作することを確認
  - ユーザーに最終確認を求める

## Notes

- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Phase 1 focuses on iPhone MVP with local storage only
- AI features (tasks 10.1-10.4) are optional for MVP
- RSS functionality is manual update only in Phase 1
- All tests are now required for comprehensive development approach