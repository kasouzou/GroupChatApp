# New Chat - データフロー詳細

## 目的と対象範囲
- 目的: `new_chat` 機能の処理フローを体系的かつ極めて詳細に記述し、実装・保守・テストのための参照にする。
- 対象範囲: `lib/features/new_chat` 以下に存在するプレゼンテーション、アプリケーション、ドメイン、データ層、およびDIのファイル群。

## 高レベル概要（ユーザー操作からバックエンドまで）
ユーザーが「新しいチャットを作る」「招待でグループに参加する」「メンバーを追加する」といった操作を行うと、
UI（ページ）→ View/State → UseCase（アプリケーション層）→ Repository（ドメイン→インフラ）→ DataSource（リモートAPI呼び出し）→ バックエンド の順で処理が進みます。

各層の責務（簡潔）:
- Presentation: UI/ユーザー入力の収集、バリデーション、状態管理、ローディング/エラーメッセージの表示、ナビゲーション
- Application (UseCase): ユースケースの調整、入力検証、リポジトリ呼び出し、結果の変換
- Domain (Repository / Entities): ドメインインターフェース、エンティティの定義
- Data (DataSource / Impl): API 呼び出し、JSON ⇄ Entity/DTO の変換、低レベル例外のドメイン例外へのマッピング
- DI: 各層の結合（プロバイダ）を提供し、テスト用の差し替えを可能にする

## ルートファイルと役割マッピング
- presentation/pages/new_chat_page.dart: 新規チャット画面（エントリーポイントの1つ）
- presentation/pages/make_chat_page.dart: 実際にチャットを作成するフォーム画面
- presentation/pages/add_member_page.dart: メンバー招待・選択のUI
- application/create_chat_usecase.dart: チャット作成ユースケース
- application/join_group_by_invite_usecase.dart: 招待コード等でグループに参加するユースケース
- application/create_group_invite_usecase.dart: 招待URL/コードを作成するユースケース
- domain/new_chat_repository.dart: リポジトリのインターフェース（抽象）
- data/new_chat_repository_impl.dart: リポジトリの実装。DataSource を呼び出す
- data/datasource/remote/new_chat_remote_datasource.dart: DataSource 抽象（API 呼び出しインターフェース）
- data/datasource/remote/new_chat_remote_datasource_impl.dart: API 呼び出しの実装（HTTP クライアントなど）
- di/*_provider.dart: UseCase や Repository を提供するプロバイダ（DI コンテナの設定）
- domain/entities/group_invite_info.dart: 招待情報エンティティ
- domain/entities/join_group_result.dart: 参加結果エンティティ

（注）以降の説明では、関数/メソッド名やファイル名を明示して、どの箇所がどの責務を担うかを追跡可能にします。

## エンティティ（構造と意味）
- `GroupInviteInfo` (`group_invite_info.dart`)
  - 代表的フィールド: inviteId / inviterId / groupId / expiresAt / maxUses / metadata
  - 意味: 招待に関するメタ情報を保持。UI はこのエンティティを表示やクリップボードコピー、シェアに利用する。
  - シリアライズ: DataSource 層で JSON に変換され、逆も同様。

- `JoinGroupResult` (`join_group_result.dart`)
  - 代表的フィールド: success(bool) / groupId / joinedMemberInfo / errorCode / message
  - 意味: 参加処理の結果。UseCase はこれを受け取り、Presentation に適切な画面遷移やメッセージ表示を指示する。

## リポジトリ層の役割と挙動
- `NewChatRepository` (抽象)
  - メソッド例: `Future<JoinGroupResult> joinGroupByInvite(GroupInviteInfo info)`, `Future<GroupInviteInfo> createGroupInvite(params)`, `Future<Chat> createChat(params)`
  - ここでは「何をするか」を定義し、「どうやるか」は実装に委ねる。

- `NewChatRepositoryImpl` (実装)
  - 内部で `NewChatRemoteDataSource` を注入。
  - 例外ハンドリング: DataSource が投げる低レベルの例（HTTP 400/500、タイムアウト、JSON パースエラー）をキャッチし、ドメイン向けの例外または `JoinGroupResult` の errorCode に変換する。
  - トランザクション性: 1 リクエスト = 1 API 呼び出しが基本。複数 API 呼び出しが必要な場合は UseCase 側で調整。

## DataSource（API 呼び出し）詳細
- 抽象: `NewChatRemoteDataSource`
  - メソッド例: `Future<GroupInviteInfoDto> createGroupInvite(CreateInviteRequest req)`, `Future<JoinGroupResponseDto> joinGroupByInvite(String inviteToken)`

- 実装: `NewChatRemoteDataSourceImpl`
  - HTTP クライアントを用いてエンドポイントを叩く。
  - JSON シリアライズ/デシリアライズの責任を持つ（DTO ↔ Entity のマッピングはここで行うか、DTO 層を別に持つ）。
  - レスポンスコードごとの処理:
    - 200/201: 正常系。レスポンス JSON を DTO にパースして Repository に返す。
    - 400 系: 入力エラー（フィールドごとのエラー情報を含むことが多い）→ カスタム例外（BadRequestException）を throw。
    - 401/403: 認証/認可エラー → AuthException。
    - 404: リソース未発見 → NotFoundException。
    - 5xx: サーバーエラー → ServerException。
    - タイムアウト/ネットワーク切断: NetworkException。

## UseCase（アプリケーション層）の詳細挙動
UseCase は「1 つのユーザー操作に対するビジネスルール」を実行する。副作用（API 呼び出し）と副次的処理（ロギング、イベント発行）を扱う。

- `CreateChatUseCase` (`create_chat_usecase.dart`)
  - 入力: `CreateChatParams`（チャット名、初期メンバー、アイコン情報など）
  - 処理:
    1. Validate params（空文字チェック、メンバー数上限チェックなど）
    2. `repository.createChat(params)` を呼ぶ
    3. 結果を `Chat` エンティティに変換して返す
  - 失敗時: ValidationError → UI に即時返す。Repository の例外 → UI に適切なダイアログで伝える。

- `JoinGroupByInviteUseCase` (`join_group_by_invite_usecase.dart`)
  - 入力: `inviteToken` や `GroupInviteInfo`
  - 処理:
    1. トークン/コードの簡易検査（形式チェック）
    2. `repository.joinGroupByInvite(...)` を呼ぶ
    3. `JoinGroupResult` を受け取り、成功時はナビゲーション（チャット画面へ移動）やローカルキャッシュ更新を行う
  - 例外処理: 期限切れ、既に満員、無効コードなどは `JoinGroupResult.errorCode` にマッピング。

- `CreateGroupInviteUseCase` (`create_group_invite_usecase.dart`)
  - 入力: 有効期限、最大利用回数、ターゲット（グループID）等
  - 処理: `repository.createGroupInvite(params)` を呼び、`GroupInviteInfo` を返す

## DI（依存注入）とプロバイダ配置
- `di/new_chat_repository_provider.dart`: `NewChatRepositoryImpl` を `NewChatRepository` として提供
- `di/create_chat_usecase_provider.dart`, `di/create_group_invite_usecase_provider.dart`, `di/join_group_by_invite_usecase_provider.dart`: それぞれ UseCase を組み立て、Presentation 層が注入して使えるようにする

DI の挙動（具体例）:
- Presentation が `CreateChatUseCase` を利用する際、プロバイダは `NewChatRepositoryImpl` と `NewChatRemoteDataSourceImpl` を注入済みの状態で UseCase を返す。

## Presentation（ページ/フォーム）の処理詳細
各ページは次のような責務を持ち、UseCase を呼び出す際のライフサイクルに注意する。

- `new_chat_page.dart`:
  - 役割: 新規チャットの入り口（ナビゲーション、テンプレート選択など）
  - イベント→処理例:
    - ユーザーが「作成」をタップ → `make_chat_page` に遷移

- `make_chat_page.dart`:
  - 役割: 実際の作成フォーム（チャット名、メンバー選択、オプション）
  - フロー:
    1. ユーザー入力（TextField、選択）
    2. ローカルバリデーション（空チェック、長さ、禁止文字）
    3. UI にローディング表示をしながら `CreateChatUseCase` を実行
    4. UseCase 結果が成功 → チャット画面へ遷移、失敗 → エラーメッセージ表示
  - 非同期注意点: ボタン連打対策（2重送信防止）、キャンセル（ページ遷移時に処理を破棄）

- `add_member_page.dart`:
  - 役割: メンバーを選択/招待する UI（連絡先や検索結果から追加）
  - フロー:
    1. 候補表示 → チェックボックスで選択
    2. 「招待」ボタンで `CreateGroupInviteUseCase` を呼ぶ場合あり（招待リンク生成）
    3. 生成した招待リンクを共有 API に渡す（プラットフォームの共有シートを呼ぶ）

## 具体的なシーケンス（作成フローの逐次手順）
ここでは「チャット作成」を例に、呼び出し階層ごとにどのデータが渡るかを示す。

1) ユーザー操作: `make_chat_page` の「作成」ボタン押下
   - UI レイヤー: `CreateChatParams` を組み立てる（例: {name: "チームA", members: [id1,id2], icon: ...}）
2) UI -> UseCase: `createChatUseCase.execute(params)` を await
   - ここで UI はローディングフラグ = true
3) UseCase:
   - Validate params
   - repository.createChat(params) を呼ぶ
4) RepositoryImpl:
   - datasource.createChat(requestDto) を await
   - datasource が返す DTO を Entity (`Chat`) に変換
   - 例外が出たらドメイン例外へ変換またはラップして rethrow
5) DataSourceImpl:
   - HTTP POST /api/chats などへ送信
   - レスポンス JSON を DTO 化
   - HTTP エラーやネットワーク例外はここで発生
6) 結果の戻り (成功):
   - UseCase は `Chat` エンティティを受け取り、Presentation に success を返す
   - UI はローディング = false、ナビゲーションでチャット画面へ移動

失敗時のデータの流れ（例: 招待期限切れ）:
- DataSource で 400/特定エラー受信 → RemoteException(BadRequest, {code: 'INVITE_EXPIRED'}) を throw
- RepositoryImpl はこれを捕捉し、`JoinGroupResult` の errorCode に変換または UseCase に例外として伝播
- UseCase/Presentation はエラーメッセージを決定し、ユーザーに表示

## エラー処理とマッピング方針
- Layered Exception Mapping の推奨:
  - DataSource: HTTP/IO 例外を RemoteException（型付き）にマッピング
  - Repository: RemoteException を DomainError / Result 型に変換
  - UseCase: DomainError を捕捉しユーザーフレンドリーなメッセージへ変換
  - Presentation: メッセージ表示ロジック（Toast / Dialog / Form エラー表示）

- エラーコードの扱い:
  - バックエンドが `error_code` を返す場合は、その値を `JoinGroupResult.errorCode` に入れて UI で分岐表示
  - 汎用ネットワークエラーは `NETWORK_ERROR`、サーバーは `SERVER_ERROR` として表示する

## 非同期処理・キャンセル・ローディング管理
- UI 側では UseCase 呼び出し時に `isLoading` フラグをセット。ボタンは非活性化。
- 長時間処理にはタイムアウトを設定（DataSource レイヤー、HTTP クライアントに設定）。
- 画面遷移時は未完了の Future をキャンセルできるならキャンセル。Cancel not supported な場合は結果ハンドラで画面がマウントされているか確認してから state 更新を行う。

## バリデーション規約
- プレゼンテーションでの即時バリデーション（UI レベル）:
  - 必須チェック、最大長、特殊文字禁止等
- UseCase レベルでの業務ルールチェック:
  - 既存チャット名との重複チェック（必要ならリポジトリ呼び出し）
- バックエンドも再度バリデーションを行う（最終安全弁）

## ロギング・監視
- 重要イベント（チャット作成成功/失敗、招待生成、招待参加の失敗コード）はログに残す
- 可能ならイベントトラッキング（Analytics）を呼ぶ

## テスト指針（ユニット/ウィジェット/統合）
- UseCase のユニットテスト:
  - モック `NewChatRepository` を注入し、正常/異常ケースを網羅
- RepositoryImpl のユニットテスト:
  - モック `NewChatRemoteDataSource` を注入し、API レスポンスの正パスと各種 HTTP エラーをテスト
- DataSource のテスト:
  - HTTP クライアントのスタブを用いて JSON パース、ステータスコード別の挙動を確認
- Widget テスト:
  - `make_chat_page` のフォーム検証、ローディング表示、エラーメッセージ表示を検証
- Integration/E2E:
  - 実際の API（またはステージ環境）を用いて、作成フローと参加フローを検証

## 開発者向け参照（主要ファイル）
- [lib/features/new_chat/presentation/pages/new_chat_page.dart](lib/features/new_chat/presentation/pages/new_chat_page.dart)
- [lib/features/new_chat/presentation/pages/make_chat_page.dart](lib/features/new_chat/presentation/pages/make_chat_page.dart)
- [lib/features/new_chat/presentation/pages/add_member_page.dart](lib/features/new_chat/presentation/pages/add_member_page.dart)
- [lib/features/new_chat/application/create_chat_usecase.dart](lib/features/new_chat/application/create_chat_usecase.dart)
- [lib/features/new_chat/application/join_group_by_invite_usecase.dart](lib/features/new_chat/application/join_group_by_invite_usecase.dart)
- [lib/features/new_chat/application/create_group_invite_usecase.dart](lib/features/new_chat/application/create_group_invite_usecase.dart)
- [lib/features/new_chat/domain/new_chat_repository.dart](lib/features/new_chat/domain/new_chat_repository.dart)
- [lib/features/new_chat/data/new_chat_repository_impl.dart](lib/features/new_chat/data/new_chat_repository_impl.dart)
- [lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart](lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart)
- [lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart](lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart)
- [lib/features/new_chat/domain/entities/group_invite_info.dart](lib/features/new_chat/domain/entities/group_invite_info.dart)
- [lib/features/new_chat/domain/entities/join_group_result.dart](lib/features/new_chat/domain/entities/join_group_result.dart)

## 追加の改善提案（任意）
- API のレスポンス DTO を明確に分離して、DataSource でのみ DTO ⇄ Entity を行う（単一責任の向上）
- 共通の例外マッピングユーティリティを導入して、RepositoryImpl 側のエラーハンドリングを簡潔にする
- 重要なユースケースにはリトライ/バックオフ戦略を導入する（例えば招待生成などの重要処理）

---
このファイルは `lib/features/new_chat` の実装を読みながら補完・更新してください。実装側で変更が入ったら、ここに手順やファイル参照を追記して最新化することを推奨します。

## 関数／行レベル注釈（実装参照）
以下は実装ファイルを参照した上での、関数・メソッド単位の詳細な注釈です。各項目は責務、引数、戻り値、非同期・例外の振る舞い、実際に使用しているエンドポイントや JSON フィールド名などを含みます。

- `CreateChatUsecase.call` — [lib/features/new_chat/application/create_chat_usecase.dart](lib/features/new_chat/application/create_chat_usecase.dart)
  - シグネチャ: `Future<String> call({required String name, required String creatorUserId, required List<String> memberUserIds})`
  - 責務: 入力を受け取り `NewChatRepository.createChat` を呼ぶ。戻り値は生成された `groupId`。
  - 非同期挙動: `Future` を返す。バリデーションは基本的に呼び出し元（UI か UseCase 前段）で行う。

- `NewChatRepositoryImpl.createChat` — [lib/features/new_chat/data/new_chat_repository_impl.dart](lib/features/new_chat/data/new_chat_repository_impl.dart)
  - シグネチャ: `Future<String> createChat({required String name, required String creatorUserId, required List<String> memberUserIds})`
  - 責務: `NewChatRemoteDataSource.createGroup` を呼び、返ってきた JSON から `group_id` を取り出して返す。
  - 例外: `NewChatRemoteDataSource` 側で HTTP エラーは `toAppException` 経由で例外化される。必要ならここで追加マッピング（再試行、ラップ）を行う。

- `NewChatRepositoryImpl.createInvite` — [lib/features/new_chat/data/new_chat_repository_impl.dart](lib/features/new_chat/data/new_chat_repository_impl.dart)
  - シグネチャ: `Future<GroupInviteInfo> createInvite({required String groupId, required String requesterUserId, int expiresInMinutes = 5})`
  - 責務: `remote.createInvite(...)` を呼び、戻り JSON の `group_id`, `invite_code`, `invite_url`, `expires_at` を `GroupInviteInfo` に変換して返す。
  - 実装上のポイント: `expires_at` は文字列→`DateTime.tryParse` しており、失敗時は `DateTime.now()` にフォールバックしている（将来的に厳密な日付検証を追加推奨）。

- `NewChatRepositoryImpl.joinByInviteCode` — [lib/features/new_chat/data/new_chat_repository_impl.dart](lib/features/new_chat/data/new_chat_repository_impl.dart)
  - シグネチャ: `Future<JoinGroupResult> joinByInviteCode({required String inviteCode, required String userId})`
  - 責務: `remote.joinByInviteCode(...)` を呼び、戻り JSON の `group_id`, `group_name`, `joined` を `JoinGroupResult` に詰めて返す。
  - 注意点: バックエンドが返すエラー情報（例: `error_code`）を `JoinGroupResult` に含めたい場合は、`remote` の戻り JSON をそのまま受け取りマッピングを拡張する必要がある。

- `NewChatRemoteDataSourceImpl.createGroup` — [lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart](lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart)
  - エンドポイント: `POST ${ApiConfig.baseUrl}/api/v1/groups`
  - リクエストボディ: `{ name, creator_user_id, member_user_ids }`
  - レスポンス期待値: JSON に `group_id` を含むこと
  - エラー処理: ステータスコードが 2xx でなければ `toAppException(response, endpoint: uri.toString())` を投げる。
  - 実装の注意: HTTP クライアントのタイムアウトやネットワーク例外はここで発生する。

- `NewChatRemoteDataSourceImpl.createInvite` — [lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart](lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart)
  - エンドポイント: `POST ${ApiConfig.baseUrl}/api/v1/group-invites`
  - リクエストボディ: `{ group_id, requester_user_id, expires_in_minutes }`
  - 戻り値: JSON Map をそのまま返す（`createInvite` は `Map<String,dynamic>` を返す実装）

- `NewChatRemoteDataSourceImpl.joinByInviteCode` — [lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart](lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart)
  - エンドポイント: `POST ${ApiConfig.baseUrl}/api/v1/group-invites/join`
  - リクエストボディ: `{ invite_code, user_id }`
  - 戻り値: JSON Map（`group_id`, `group_name`, `joined` など）

- `MakeChatPage._onSavePressed` — [lib/features/new_chat/presentation/pages/make_chat_page.dart](lib/features/new_chat/presentation/pages/make_chat_page.dart)
  - 挙動:
    1. `_chatNameController.text` を trim してバリデーション（非空）を行う
    2. `_isSaving` フラグを true にして多重送信を防止
    3. `authSessionProvider` から現在ユーザーID を取得
    4. `createChatUsecaseProvider` を読み、`usecase.call(...)` を await
    5. 成功時は `Navigator.pop(context, groupId)` で前画面へ戻す。失敗時は Snackbar にエラーメッセージを表示
  - 実装注意点: `mounted` チェックを行ってから UI 更新を行っている。例外は広くキャッチしているため、細かいエラー表示には UseCase/Repository 側でのエラー分類が必要。

- `JoinGroupByInviteUseCase.call` — [lib/features/new_chat/application/join_group_by_invite_usecase.dart](lib/features/new_chat/application/join_group_by_invite_usecase.dart)
  - シグネチャ: `Future<JoinGroupResult> call({required String inviteCode, required String userId})`
  - 責務: `repository.joinByInviteCode` を呼ぶだけのシンプルなラッパー。追加検証（形式チェックなど）をここに置ける。

- `GroupInviteInfo` エンティティ — [lib/features/new_chat/domain/entities/group_invite_info.dart](lib/features/new_chat/domain/entities/group_invite_info.dart)
  - フィールド: `groupId`, `inviteCode`, `inviteUrl`, `expiresAt`
  - 生成箇所: `NewChatRepositoryImpl.createInvite` が `remote.createInvite` の JSON を受け `GroupInviteInfo` を構築している。

### 実装レベルでの改善箇所（具体的な行・関数で推奨）
- 例外コードの伝播:
  - 現状: `NewChatRemoteDataSourceImpl` が `toAppException` で例外化し、`NewChatRepositoryImpl` はそれをそのまま受け取っている。
  - 推奨: `NewChatRepositoryImpl.joinByInviteCode` の直前で `try { ... } catch (e) { if (e is AppHttpException) return JoinGroupResult(..., errorCode: e.code); rethrow; }` のように変換して UI 側で細かく分岐可能にする。

- 日付パースの厳密化:
  - 現状: `expires_at` のパース失敗で `DateTime.now()` にフォールバックしている。
  - 推奨: パース失敗時は `FormatException` を投げるか、`GroupInviteInfo` 側に `nullable` を許容し、UI で「不明な有効期限」と表示する。

- レスポンス DTO の導入:
  - 現状: `Map<String,dynamic>` を直接扱っている箇所がある（`NewChatRemoteDataSourceImpl` → `NewChatRepositoryImpl`）。
  - 推奨: `InviteResponseDto` / `JoinResponseDto` を作成し、明示的なフィールドを型として扱う。変換の責務を DataSource に閉じることで Repository のテストが容易になる。

### 開発者向けのすばやい参照（追加）
- 追いやすい箇所: `toAppException` の実装（`lib/core/network/api_error_parser.dart`）を確認すると、どのエラーコードが投げられるか把握でき、UI の分岐ロジック設計に役立ちます。

---
（注）必要であれば、さらに各関数の実際の行番号をここに追加して行レベルでのコメントを増やせます。行番号を含めた注釈が欲しい場合は指示してください。
