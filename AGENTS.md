# AGENTS.md

## 方針
- UI は SwiftUI で実装する。
- Storyboard や XIB は使わない。
- ファイルは小さく保つ。300 行を目安の上限とする。
- SwiftUI View にビジネスロジックを書かない。
- 非同期処理には async/await を使う。
- 共有される可変状態は最小限にする。
- 新しいアプリの振る舞いは、最も近い feature フォルダに追加する。
- struct や method には、目的や責務がわかる簡潔なドキュメントコメントを付ける。
- ロジック内部には、意図が読み取りづらい箇所にだけコメントを付ける。

## ディレクトリ
- `one-thing/App`: アプリのエントリーポイント、ルート View、依存関係のセットアップ、ナビゲーション。
- `one-thing/Core`: エンティティ、ユースケース、リポジトリプロトコル。
- `one-thing/Data`: API、永続化、リポジトリ実装。
- `one-thing/DesignSystem`: 再利用可能な UI コンポーネントとデザイントークン。
- `one-thing/Features`: feature 固有の View と ViewModel。

## アーキテクチャ
- MVVM + UseCase + Repository を優先する。
- 依存方向は `Features -> Core` と `Data -> Core` にする。
- `Core` は `Data` に依存してはならない。
- View は API クライアントや永続化へ直接依存せず、ViewModel に依存する。

## テスト
- 振る舞いが変わる場合は、ユースケースと ViewModel のテストを追加する。
- リポジトリのテストでは fake や mock を使う。
- UI テストは重要なフローに絞る。
- テストターゲットが存在する場合は `xcodebuild test` を実行する。

## 避けること
- 大きな singleton を追加しない。
- View から API クライアントを直接呼び出さない。
- 利点が明確でない限り、外部依存を追加しない。
- focused feature の実装中に広範なリファクタリングを持ち込まない。

## ドキュメント
- [コンセプト](@docs/CONCEPT.md): アプリの目的・コアバリュー・やらないことの定義
- [画面仕様](@docs/SCREENS.md): 各画面のレイアウト・状態・遷移フロー
- [マイクロコピー](@docs/COPY.md): ボタンラベル・メッセージ・通知文言
- [開発ルール](@docs/DEVELOPMENT.md): Linear 連携・ステータス管理のルール
