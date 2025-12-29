# Requirements Document

## Introduction

AIエンジニア向けの技術ブログ管理ツール。技術系ブログの最新記事や更新を自動検知して通知し、記事に対する複数のTwitter風メモ（写真付き）を管理できる。タグ分類、ドメイン整理、検索機能、読書進捗管理を提供する。

## Glossary

- **Blog_Manager**: 技術ブログ管理システム全体
- **Article_Bookmark**: 保存された技術記事のURL、タイトル、メモ、タグを含むエンティティ
- **Update_Monitor**: 技術ブログの新記事や更新を検知するサービス
- **Notification_Service**: 記事更新通知を配信するサービス
- **Tweet_Memo**: 各記事に追加できるTwitter風の短いメモ（写真最大4枚付き）
- **Tag**: 記事を分類するためのラベル
- **Domain_Group**: 同一ドメインの記事をグループ化する機能
- **Reading_Status**: 未読、既読、お気に入りの状態管理
- **RSS_Feed**: 技術ブログのRSS/Atomフィード
- **Feed_Detector**: 記事URLからRSSフィードを自動検出するサービス
- **Memo_Type**: メモの種類（アイディア、感想、TODO、引用、その他）
- **Full_Text_Search**: 記事本文を含む全文検索機能
- **Export_Service**: ブックマークとメモをエクスポートする機能
- **Recommendation_Engine**: 関連記事を自動提案するエンジン
- **AI_Summarizer**: 記事内容を自動要約するAIサービス
- **Tag_Recommender**: 記事内容に基づいてタグを自動推薦するAIサービス
- **Two_Tab_System**: 2つのメインタブ（New Entry, Bookmark）による記事管理システム
- **Side_Menu**: 右スワイプで表示されるメニュー（いいね、アイディア、感想、TODO、その他）
- **Tab_Manager**: 2タブシステムとサイドメニューの表示を管理するサービス
- **Text_Selection_Service**: WebView内でのテキスト選択・引用メモ作成を管理するサービス
- **Swipe_Navigation**: 右スワイプによるサイドメニュー表示機能
- **Dynamic_Menu_Display**: メモが存在しないメニュー項目の自動非表示機能
- **Menu_Configuration**: ユーザーがカスタマイズ可能なメニュー項目の順序・表示設定

## Requirements

### Requirement 1: 記事ブックマーク管理

**User Story:** AIエンジニアとして、技術ブログの記事をブックマークとして保存・管理したい。後で簡単にアクセスできるようにしたい。

#### Acceptance Criteria

1. WHEN ユーザーがURLを入力してブックマーク追加を実行する THEN THE Blog_Manager SHALL 新しい記事ブックマークを作成してリストに追加する
2. WHEN ユーザーがブックマークを削除する THEN THE Blog_Manager SHALL そのブックマークと関連するすべてのメモをリストから完全に削除する
3. WHEN ユーザーがブックマークリストを表示する THEN THE Blog_Manager SHALL 保存されたすべてのブックマークをタイトル、URL、サムネイル、記事公開日、経過時間と共にカード形式で表示する
4. WHEN ユーザーが2タブシステムを使用する THEN THE Blog_Manager SHALL New EntryタブとBookmarkタブで記事を表示する
5. WHEN ユーザーがブックマークを編集する THEN THE Blog_Manager SHALL タイトルとタグの変更を保存する
6. WHEN New Entry記事がRSSから追加される THEN THE Blog_Manager SHALL 記事を未ブックマーク状態（isUserBookmarked = false）で保存する
7. WHEN ユーザーがNew Entry記事をブックマークに追加する THEN THE Blog_Manager SHALL isUserBookmarkedフラグをtrueに更新してBookmarkタブに表示する
8. WHEN New Entry記事が20日間経過する THEN THE Blog_Manager SHALL 未ブックマーク記事を自動的に削除する

### Requirement 2: Twitter風メモ機能

**User Story:** AIエンジニアとして、技術記事を読んで浮かんだアイディアや感想を複数のTwitter風メモとして記録したい。写真も添付して後で振り返りやすくしたい。

#### Acceptance Criteria

1. WHEN ユーザーが記事にメモを追加する THEN THE Blog_Manager SHALL そのメモを記事に関連付けて保存し、作成日時を記録する
2. WHEN メモが140文字を超える THEN THE Blog_Manager SHALL 入力を制限してエラーメッセージを表示する
3. WHEN ユーザーがメモに写真を添付する THEN THE Blog_Manager SHALL 最大4枚まで写真を保存する
4. WHEN ユーザーが既存のメモを編集する THEN THE Blog_Manager SHALL 変更されたメモを保存して更新日時を記録する
5. WHEN ユーザーがメモを削除する THEN THE Blog_Manager SHALL そのメモと添付写真を完全に削除する
6. WHEN 1つの記事に複数のメモが存在する THEN THE Blog_Manager SHALL 時系列順でメモを表示する

### Requirement 3: タグ管理機能

**User Story:** AIエンジニアとして、技術記事を複数のタグで分類したい。関連する記事をまとめて見つけやすくしたい。

#### Acceptance Criteria

1. WHEN ユーザーが記事にタグを追加する THEN THE Blog_Manager SHALL そのタグを記事に関連付けて保存する
2. WHEN ユーザーが複数のタグを1つの記事に設定する THEN THE Blog_Manager SHALL すべてのタグを記事に関連付ける
3. WHEN ユーザーがタグを削除する THEN THE Blog_Manager SHALL そのタグを記事から削除する
4. WHEN ユーザーがタグ一覧を表示する THEN THE Blog_Manager SHALL 使用頻度順でタグを表示する
5. WHEN ユーザーがタグを編集する THEN THE Blog_Manager SHALL 関連するすべての記事のタグを更新する

### Requirement 4: ドメイン整理機能

**User Story:** AIエンジニアとして、同じ技術ブログ（ドメイン）の記事をまとめて管理したい。ブログごとに整理して閲覧したい。

#### Acceptance Criteria

1. WHEN 記事がブックマークされる THEN THE Blog_Manager SHALL 自動的にドメインを抽出してグループ化する
2. WHEN ユーザーがドメイン別表示を選択する THEN THE Blog_Manager SHALL 同一ドメインの記事をグループ表示する
3. WHEN ユーザーがドメイングループを展開する THEN THE Blog_Manager SHALL そのドメインのすべての記事を表示する
4. WHEN ユーザーがドメイン名をカスタマイズする THEN THE Blog_Manager SHALL 表示名を変更して保存する
5. WHEN ドメイングループ内で記事を並び替える THEN THE Blog_Manager SHALL 公開日時、ブックマーク日時、タイトル順で並び替える

### Requirement 5: 検索機能

**User Story:** AIエンジニアとして、保存した技術記事を様々な条件で検索したい。必要な情報を素早く見つけたい。

#### Acceptance Criteria

1. WHEN ユーザーがキーワード検索を実行する THEN THE Blog_Manager SHALL タイトル、メモ、タグ、メモ種別の内容から該当する記事を返す
2. WHEN ユーザーがタグ検索を実行する THEN THE Blog_Manager SHALL 指定されたタグを持つすべての記事を返す
3. WHEN ユーザーがメモ種別検索を実行する THEN THE Blog_Manager SHALL 指定されたメモ種別を持つすべての記事を返す
4. WHEN ユーザーがドメイン検索を実行する THEN THE Blog_Manager SHALL 指定されたドメインのすべての記事を返す
5. WHEN ユーザーが複合検索を実行する THEN THE Blog_Manager SHALL 複数の条件を組み合わせて検索結果を返す
6. WHEN 検索結果が表示される THEN THE Blog_Manager SHALL 関連度順で結果を並び替える

### Requirement 6: 記事閲覧状態管理

**User Story:** AIエンジニアとして、技術記事の閲覧状況を管理したい。未読、既読、お気に入りを区別して効率的に学習したい。

#### Acceptance Criteria

1. WHEN 記事がブックマークされる THEN THE Blog_Manager SHALL 初期状態を「未読」に設定する
2. WHEN ユーザーがNew Entry記事をタップして閲覧する THEN THE Blog_Manager SHALL 閲覧日時を記録し、既読フラグを設定し、閲覧回数をインクリメントする
3. WHEN ユーザーがBookmark記事を開く THEN THE Blog_Manager SHALL 閲覧日時を記録し、閲覧回数をインクリメントする
4. WHEN ユーザーが記事を「既読」に設定する THEN THE Blog_Manager SHALL 既読フラグと日時を記録する
5. WHEN ユーザーが記事を「お気に入り」に設定する THEN THE Blog_Manager SHALL お気に入りフラグを設定する
6. WHEN ユーザーが閲覧状況でフィルタリングする THEN THE Blog_Manager SHALL 指定された状態の記事のみを表示する
7. WHEN 記事一覧を表示する THEN THE Blog_Manager SHALL 各記事の閲覧状況を視覚的に区別して表示する
8. WHEN New Entry記事が閲覧される THEN THE Blog_Manager SHALL 自動的に既読状態に更新する

### Requirement 7: 時間経過表示

**User Story:** AIエンジニアとして、記事が公開されてからの経過時間を確認したい。新しい記事を優先的に読む判断材料にしたい。

#### Acceptance Criteria

1. WHEN 記事一覧を表示する THEN THE Blog_Manager SHALL 各記事の公開日からの経過時間を表示する
2. WHEN 経過時間が24時間以内 THEN THE Blog_Manager SHALL 「X時間前」の形式で表示する
3. WHEN 経過時間が7日以内 THEN THE Blog_Manager SHALL 「X日前」の形式で表示する
4. WHEN 経過時間が7日を超える THEN THE Blog_Manager SHALL 公開日付を表示する
5. WHEN 経過時間が短い記事 THEN THE Blog_Manager SHALL 視覚的に強調表示する

### Requirement 8: 更新検知・通知機能

**User Story:** AIエンジニアとして、フォローしている技術ブログの新記事や既存記事の更新を自動で検知して通知を受け取りたい。最新の技術情報を見逃さないようにしたい。

#### Acceptance Criteria

1. WHEN Update_Monitor が技術ブログをチェックする THEN THE Update_Monitor SHALL 新記事の公開や既存記事の更新を検出する
2. WHEN 新記事が検出される THEN THE Update_Monitor SHALL 新記事を自動的にブックマークリストに追加する
3. WHEN 既存記事の更新が検出される THEN THE Update_Monitor SHALL 更新フラグを設定して通知をトリガーする
4. WHEN 更新チェックが失敗する THEN THE Update_Monitor SHALL エラーをログに記録して次回のチェックを継続する
5. THE Update_Monitor SHALL 各ブログを定期的（1時間ごと）にチェックする
6. WHEN ユーザーが手動で更新チェックを実行する THEN THE Update_Monitor SHALL 即座にすべてのブログをチェックする

### Requirement 9: 通知機能

**User Story:** AIエンジニアとして、技術ブログの更新をiPhoneとMacの両方で通知を受け取りたい。どのデバイスを使っていても最新情報を得られるようにしたい。

#### Acceptance Criteria

1. WHEN 新記事や更新が検知される THEN THE Notification_Service SHALL iPhoneとMacの両方に通知を送信する
2. WHEN 通知が送信される THEN THE Notification_Service SHALL 記事タイトル、ブログ名、更新内容の概要を含める
3. WHEN ユーザーが通知をタップする THEN THE Blog_Manager SHALL 該当する記事の詳細画面を表示する
4. WHEN ユーザーが通知設定を変更する THEN THE Notification_Service SHALL 新しい設定に従って通知を送信する
5. WHEN 複数の更新が同時に発生する THEN THE Notification_Service SHALL ブログ別にグループ化して通知する

### Requirement 10: ユーザーインターフェース・2タブ + サイドメニューシステム

**User Story:** AIエンジニアとして、iPhoneとMacで一貫性のある使いやすい2タブ + サイドメニューインターフェースを使いたい。効率的に記事を管理・閲覧したい。

#### Acceptance Criteria

1. WHEN ユーザーがアプリを起動する THEN THE Blog_Manager SHALL 2タブシステムのホーム画面を読み込み時間内（3秒以内）に表示する
2. WHEN ユーザーがNew Entry記事をタップする THEN THE Blog_Manager SHALL 記事をアプリ内WebViewで開き、閲覧日時と閲覧回数を記録し、既読状態に更新する
3. WHEN ユーザーがBookmark記事をタップする THEN THE Blog_Manager SHALL 記事をアプリ内WebViewで開き、閲覧日時と閲覧回数を記録する
4. WHEN ユーザーがNew Entry一覧でブックマーク追加ボタンをタップする THEN THE Blog_Manager SHALL 記事をブックマークに追加してBookmarkタブに表示する
5. WHEN ユーザーがWebViewでブックマーク追加ボタンをタップする THEN THE Blog_Manager SHALL 記事をブックマークに追加してBookmarkタブに表示する
6. WHEN ユーザーがスワイプジェスチャーを使用する THEN THE Blog_Manager SHALL 削除、編集、読書状況変更のオプションを表示する
7. WHEN アプリがダークモードで表示される THEN THE Blog_Manager SHALL 適切なダークテーマを適用する
8. WHEN ユーザーが記事詳細画面を表示する THEN THE Blog_Manager SHALL 記事情報、メモ種類別一覧、タグ、読書状況を表示する
9. WHEN ユーザーが2タブシステムを使用する THEN THE Blog_Manager SHALL New EntryタブとBookmarkタブを提供する
10. WHEN ユーザーがヘッダーを表示する THEN THE Blog_Manager SHALL 中央にアプリアイコンを表示する
11. WHEN New Entryタブを表示する THEN THE Blog_Manager SHALL 未ブックマーク記事（isUserBookmarked == false）のみを表示する
12. WHEN Bookmarkタブを表示する THEN THE Blog_Manager SHALL ブックマーク済み記事（isUserBookmarked == true）のみを表示する

### Requirement 11: データ永続化・同期

**User Story:** システム管理者として、ユーザーの記事データが安全に保存され、デバイス間で同期されるようにしたい。

#### Acceptance Criteria

1. WHEN 記事やメモが作成・変更される THEN THE Blog_Manager SHALL データをローカルストレージに即座に保存する
2. WHEN アプリが予期せず終了する THEN THE Blog_Manager SHALL 次回起動時にすべてのデータを復元する
3. WHEN データの破損が検出される THEN THE Blog_Manager SHALL バックアップから復元を試行する
4. WHEN ユーザーがiPhoneで記事を追加する THEN THE Blog_Manager SHALL その記事をMacにも同期する
5. WHEN 同期中にネットワークエラーが発生する THEN THE Blog_Manager SHALL 接続回復後に自動的に同期を再開する

### Requirement 12: RSS/Atomフィード自動検出

**User Story:** AIエンジニアとして、記事URLを入力するだけでRSSフィードを自動検出・登録したい。手動でフィードURLを探す手間を省きたい。

#### Acceptance Criteria

1. WHEN ユーザーが記事URLを入力する THEN THE Feed_Detector SHALL そのサイトのRSSフィードを自動検出する
2. WHEN RSSフィードが検出される THEN THE Blog_Manager SHALL フィードを監視対象に自動追加する
3. WHEN 自動検出が失敗する THEN THE Blog_Manager SHALL ユーザーに手動でフィードURLを入力するオプションを提供する
4. WHEN RSS フィードに新記事が追加される THEN THE Blog_Manager SHALL 自動的に新記事をブックマークリストに追加する
5. WHEN RSS フィードの取得に失敗する THEN THE Blog_Manager SHALL エラーをログに記録して次回の取得を継続する
6. WHEN ユーザーがフィード一覧を表示する THEN THE Blog_Manager SHALL 登録済みフィードと最終更新日時を表示する
7. WHEN ユーザーがフィードを削除する THEN THE Blog_Manager SHALL そのフィードの監視を停止する

### Requirement 13: メモ種類分類・サイドメニューシステム

**User Story:** AIエンジニアとして、記事に対するメモを種類別（アイディア、感想、TODO、引用、その他）に分類し、サイドメニューで効率的に管理したい。メモ種類ごとに記事を整理して閲覧したい。

#### Acceptance Criteria

1. WHEN ユーザーがメモを作成する THEN THE Blog_Manager SHALL メモの種類（アイディア、感想、TODO、引用、その他）を選択できるオプションを提供する
2. WHEN ユーザーがメモ種類を設定する THEN THE Blog_Manager SHALL そのメモに種類ラベルを関連付ける
3. WHEN メモ一覧を表示する THEN THE Blog_Manager SHALL 各メモの種類を視覚的に区別して表示する
4. WHEN ユーザーが右スワイプする THEN THE Blog_Manager SHALL サイドメニューを表示する
5. WHEN ユーザーがサイドメニュー項目を選択する THEN THE Blog_Manager SHALL 該当するメモ種類を持つ記事のみを表示する
6. WHEN メモが存在しないメニュー項目がある THEN THE Blog_Manager SHALL そのメニュー項目を自動的に非表示にする
7. WHEN ユーザーがサイドメニューを閉じる THEN THE Blog_Manager SHALL 左スワイプまたはメニュー外タップでメニューを閉じる

### Requirement 14: 全文検索機能

**User Story:** AIエンジニアとして、記事のタイトルやメモだけでなく記事本文も検索対象にしたい。より詳細な情報を見つけやすくしたい。

#### Acceptance Criteria

1. WHEN 記事がブックマークされる THEN THE Blog_Manager SHALL 記事本文を取得して検索インデックスに追加する
2. WHEN ユーザーが全文検索を実行する THEN THE Blog_Manager SHALL タイトル、メモ、タグ、メモ種別、記事本文から該当する記事を返す
3. WHEN 記事本文の取得に失敗する THEN THE Blog_Manager SHALL タイトル、メモ、タグ、メモ種別のみを検索対象とする
4. WHEN 検索結果を表示する THEN THE Blog_Manager SHALL マッチした箇所をハイライト表示する
5. WHEN 記事本文が更新される THEN THE Blog_Manager SHALL 検索インデックスを更新する

### Requirement 15: エクスポート機能

**User Story:** AIエンジニアとして、蓄積したブックマークとメモをMarkdownやJSONで出力したい。他のツールとの連携やバックアップに活用したい。

#### Acceptance Criteria

1. WHEN ユーザーがエクスポートを実行する THEN THE Export_Service SHALL 全ブックマークとメモをMarkdown形式で出力する
2. WHEN ユーザーがJSON形式を選択する THEN THE Export_Service SHALL 構造化されたJSONファイルを生成する
3. WHEN エクスポート対象を絞り込む THEN THE Export_Service SHALL 指定されたタグやドメインの記事のみを出力する
4. WHEN エクスポートファイルを生成する THEN THE Export_Service SHALL ファイル名に日付を含めて保存する
5. WHEN エクスポートが完了する THEN THE Export_Service SHALL ユーザーにダウンロードリンクを提供する

### Requirement 16: 関連記事自動提案

**User Story:** AIエンジニアとして、現在閲覧している記事に関連する他の記事を自動で提案してもらいたい。関連する知識を効率的に学習したい。

#### Acceptance Criteria

1. WHEN ユーザーが記事詳細を表示する THEN THE Recommendation_Engine SHALL 同じタグを持つ関連記事を提案する
2. WHEN 関連記事を計算する THEN THE Recommendation_Engine SHALL タグの一致度、キーワードの類似度、ドメインの関連性を考慮する
3. WHEN 関連記事が見つからない THEN THE Recommendation_Engine SHALL 同じドメインの他の記事を提案する
4. WHEN 関連記事一覧を表示する THEN THE Recommendation_Engine SHALL 関連度の高い順で最大5件を表示する
5. WHEN ユーザーが提案された記事を閲覧する THEN THE Recommendation_Engine SHALL その行動を学習して今後の提案精度を向上させる

### Requirement 17: AI要約機能

**User Story:** AIエンジニアとして、長い技術記事の内容を自動で要約してもらいたい。記事の要点を素早く把握して時間を節約したい。

#### Acceptance Criteria

1. WHEN 記事がブックマークされる THEN THE AI_Summarizer SHALL 記事本文を解析して要約を生成する
2. WHEN 要約が生成される THEN THE AI_Summarizer SHALL 記事の主要なポイントを3-5文で要約する
3. WHEN 要約の生成に失敗する THEN THE AI_Summarizer SHALL エラーをログに記録して要約なしで記事を保存する
4. WHEN ユーザーが記事詳細を表示する THEN THE Blog_Manager SHALL 要約を記事情報と共に表示する
5. WHEN ユーザーが要約を編集する THEN THE Blog_Manager SHALL カスタム要約として保存する
6. WHEN 記事が更新される THEN THE AI_Summarizer SHALL 新しい要約を生成して既存の要約を更新する

### Requirement 18: タグ自動推薦機能

**User Story:** AIエンジニアとして、記事内容に基づいて適切なタグを自動で推薦してもらいたい。手動でタグを考える時間を節約したい。

#### Acceptance Criteria

1. WHEN 記事がブックマークされる THEN THE Tag_Recommender SHALL 記事内容を解析して関連タグを推薦する
2. WHEN タグ推薦が生成される THEN THE Tag_Recommender SHALL 最大5個の関連タグを提案する
3. WHEN ユーザーがタグ推薦を表示する THEN THE Blog_Manager SHALL 推薦されたタグを選択可能な形で表示する
4. WHEN ユーザーが推薦タグを選択する THEN THE Blog_Manager SHALL 選択されたタグを記事に追加する
5. WHEN ユーザーが推薦タグを拒否する THEN THE Tag_Recommender SHALL その情報を学習して今後の推薦精度を向上させる
6. WHEN 既存のタグと類似する推薦がある THEN THE Tag_Recommender SHALL 既存タグを優先して推薦する
### Requirement 19: テキスト選択・引用メモ機能

**User Story:** AIエンジニアとして、記事を読んでいる際に重要な部分をテキスト選択して、そのまま引用メモとして保存したい。後で参照しやすくしたい。

#### Acceptance Criteria

1. WHEN ユーザーがWebView内でテキストを選択する THEN THE Blog_Manager SHALL 選択されたテキストを正確に取得する
2. WHEN テキスト選択が完了する THEN THE Blog_Manager SHALL 「引用メモを作成」オプションを表示する
3. WHEN ユーザーが引用メモ作成を選択する THEN THE Blog_Manager SHALL 選択テキストを自動的にメモ内容に挿入する
4. WHEN 引用メモが作成される THEN THE Blog_Manager SHALL 引用元のURL、選択テキスト、作成日時を記録する
5. WHEN 引用メモを表示する THEN THE Blog_Manager SHALL 引用テキストと引用元URLを視覚的に区別して表示する
6. WHEN 選択テキストが140文字を超える THEN THE Blog_Manager SHALL テキストを適切に切り詰めて引用メモを作成する

### Requirement 20: サイドメニューナビゲーション機能

**User Story:** AIエンジニアとして、右スワイプでサイドメニューを表示して、メモ種類別の記事を素早く閲覧したい。効率的にメモ種類別の記事を管理したい。

#### Acceptance Criteria

1. WHEN ユーザーが画面を右にスワイプする THEN THE Blog_Manager SHALL サイドメニューを表示する
2. WHEN ユーザーが画面を左にスワイプする THEN THE Blog_Manager SHALL サイドメニューを閉じる
3. WHEN ユーザーがメニュー外をタップする THEN THE Blog_Manager SHALL サイドメニューを閉じる
4. WHEN サイドメニューが表示される THEN THE Blog_Manager SHALL スムーズなアニメーションでメニューを表示する
5. WHEN サイドメニューが閉じられる THEN THE Blog_Manager SHALL スムーズなアニメーションでメニューを閉じる
6. WHEN 非表示メニュー項目がある THEN THE Blog_Manager SHALL 表示されているメニュー項目のみを表示する
7. WHEN ユーザーがスワイプ操作を無効にする THEN THE Blog_Manager SHALL メニューボタンによる表示のみを有効にする

### Requirement 21: 動的メニュー表示機能

**User Story:** AIエンジニアとして、メモが存在しないメニュー項目は自動的に非表示にして、使用中のメニュー項目のみを表示したい。UIをすっきりと保ちたい。

#### Acceptance Criteria

1. WHEN 特定のメモ種類の記事が存在しない THEN THE Blog_Manager SHALL 該当するメニュー項目を自動的に非表示にする
2. WHEN 新しいメモが追加される THEN THE Blog_Manager SHALL 対応するメニュー項目を自動的に表示する
3. WHEN 最後のメモが削除される THEN THE Blog_Manager SHALL 該当するメニュー項目を自動的に非表示にする
4. WHEN いいね（お気に入り）記事が存在する THEN THE Blog_Manager SHALL いいねメニュー項目を表示する
5. WHEN メニュー項目の表示状態が変更される THEN THE Blog_Manager SHALL リアルタイムでメニューを更新する
6. WHEN 全てのメモ種類メニュー項目が非表示 THEN THE Blog_Manager SHALL サイドメニューに「メモがありません」と表示する

### Requirement 22: サイドメニュー設定・カスタマイズ機能

**User Story:** AIエンジニアとして、サイドメニュー項目の表示順序や表示/非表示を自分の使い方に合わせてカスタマイズしたい。個人の作業フローに最適化したい。

#### Acceptance Criteria

1. WHEN ユーザーが設定画面を開く THEN THE Blog_Manager SHALL サイドメニュー設定オプションを表示する
2. WHEN ユーザーがメニュー項目順序を変更する THEN THE Blog_Manager SHALL ドラッグ&ドロップでメニュー項目の並び順を変更できる
3. WHEN ユーザーがメニュー項目の表示/非表示を設定する THEN THE Blog_Manager SHALL 各メニュー項目の表示状態を個別に制御できる
4. WHEN メニュー設定が変更される THEN THE Blog_Manager SHALL 設定を永続化して次回起動時に反映する
5. WHEN ユーザーがスワイプ操作の有効/無効を設定する THEN THE Blog_Manager SHALL サイドメニュー表示の動作を制御する
6. WHEN ユーザーが自動非表示機能を無効にする THEN THE Blog_Manager SHALL 全てのメニュー項目を常時表示する
7. WHEN 設定をデフォルトに戻す THEN THE Blog_Manager SHALL 初期のメニュー項目順序と設定に復元する