# Implementation Plan: Bookmark Manager (Phase 1A - 1週間MVP)

## Overview

Phase 1Aでは、最初の1週間で動作する超シンプルなMVPを実装します。ブックマーク追加・表示、メモ追加、タグ付けの基本機能のみに集中し、Core Dataによるローカル保存で実装します。SwiftUIとSwiftを使用してネイティブiOSアプリとして開発します。

**Phase 1A（1週間MVP）**: ブックマーク・メモ・タグの基本機能のみ
**Phase 1B（後日実装）**: RSS、検索、エクスポート、関連記事提案、ドメイン整理、読書進捗管理

## Tasks (Phase 1A - 1週間MVP)

- [x] 1. プロジェクト初期設定とCore Dataセットアップ ✅
  - Xcodeプロジェクト作成（iOS、SwiftUI、Core Data有効）
  - Core Dataモデル定義（ArticleBookmark, TweetMemo, Tag のみ）
  - 基本的なCore Dataスタック設定
  - _Requirements: 1.1, 2.1, 3.1, 11.1_

- [x] 1.1 Core Dataモデルのプロパティテスト作成 ✅
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
    - シンプルなリスト表示（サムネイル表示は後回し）
    - 基本的な記事情報表示
    - _Requirements: 1.3_

  - [ ] 2.4 表示機能のプロパティテスト
    - **Property 3: ブックマーク表示の完全性**
    - **Validates: Requirements 1.3**

- [ ] 3. Twitter風メモ機能の実装
  - [ ] 3.1 TweetMemoエンティティとCRUD操作実装
    - TweetMemo Core Dataエンティティ作成
    - MemoManager クラス実装
    - 140文字制限バリデーション
    - 写真添付機能は後回し（テキストのみ）
    - _Requirements: 2.1, 2.2, 2.4, 2.5_

  - [ ] 3.2 メモ機能のプロパティテスト
    - **Property 6: メモ追加の関連付け**
    - **Property 7: メモ文字数制限**
    - **Property 9: メモ編集の更新記録**
    - **Property 10: メモ削除の完全性**
    - **Validates: Requirements 2.1, 2.2, 2.4, 2.5**

  - [ ] 3.3 メモ表示UI実装
    - MemoListView（SwiftUI）作成
    - シンプルなメモ一覧表示
    - 時系列順表示
    - _Requirements: 2.6_

  - [ ] 3.4 メモ表示のプロパティテスト
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

  - [ ] 4.3 タグ表示UI実装
    - TagSelectionView（SwiftUI）作成
    - シンプルなタグ一覧表示
    - タグ選択・編集機能
    - _Requirements: 3.4, 3.5_

- [ ] 5. メイン画面とナビゲーションの実装
  - [ ] 5.1 メインUI構造実装
    - ContentView（SwiftUI）作成
    - シンプルなナビゲーション
    - ブックマーク一覧画面
    - _Requirements: 10.1, 10.2_

  - [ ] 5.2 UI機能のユニットテスト
    - ナビゲーション機能のテスト
    - 基本表示のテスト
    - _Requirements: 10.1, 10.2_

- [ ] 6. Checkpoint - 1週間MVP完成確認
  - すべての基本機能が動作することを確認
  - Core Data保存・読み込みテスト
  - UI操作の動作確認
  - ユーザーに最終確認を求める

## Phase 1B Tasks (後日実装予定)

以下の機能は1週間MVP完成後に実装予定：

- [ ] RSS機能の実装（手動更新版）
- [ ] 統合検索機能の実装
- [ ] 読書進捗管理機能の実装
- [ ] エクスポート機能の実装
- [ ] 関連記事自動提案機能の実装
- [ ] ドメイン整理機能の実装
- [ ] 時間経過表示機能の実装
- [ ] メモ種類分類機能の実装
- [ ] 写真添付機能の実装
- [ ] サムネイル表示機能の実装
- [ ] オプション機能（AI要約・タグ推薦）の実装

## Notes

- **Phase 1A focuses on 1-week MVP with core functionality only**
- Each task references specific requirements for traceability
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
- Phase 1A uses local storage only (Core Data)
- Advanced features (RSS, search, export, etc.) are deferred to Phase 1B
- Simplified UI implementation for faster development
- All tests are required for comprehensive development approach