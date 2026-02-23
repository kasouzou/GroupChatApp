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

## バックエンドを含めたデータフロー（詳細）
以下はフロントエンド（Flutter）からバックエンド（FastAPI）を横断する、実際に発生するHTTPリクエスト、サーバー側の処理、DB への書き込み、そしてクライアント側での結果受け取りまでを時系列に追った詳細設計です。ファイル/関数名は実装の参照先を併記しています。

### A. 新規チャット作成フロー（Create Group）

概要: ユーザーが `MakeChatPage` でチャット名等を入力して「保存」を押すと、フロントエンドは `CreateChatUsecase` 経由で `NewChatRepository` を呼び出し、最終的に `POST /api/v1/groups` に対して HTTP リクエストが発行され、新しい `ChatGroup` が DB に作成される。

#### フロント（呼び出し順）

- `MakeChatPage._onSavePressed` — [lib/features/new_chat/presentation/pages/make_chat_page.dart](lib/features/new_chat/presentation/pages/make_chat_page.dart)
  - 1) 入力検証（非空など）
  - 2) `usecase.call(name, creatorUserId, memberUserIds)` を await
  - 3) 成功時: `Navigator.pop(context, groupId)` で呼び出し元へ戻す
  - 4) 失敗時: Snackbar でエラーメッセージ表示

- `CreateChatUsecase.call` — [lib/features/new_chat/application/create_chat_usecase.dart](lib/features/new_chat/application/create_chat_usecase.dart)
  - 役割: パラメータの受け渡し。追加の業務ルール（例えばメンバー最大数）をここでチェックしても良い。

- `NewChatRepositoryImpl.createChat` — [lib/features/new_chat/data/new_chat_repository_impl.dart](lib/features/new_chat/data/new_chat_repository_impl.dart)
  - 役割: `remote.createGroup(...)` を呼び、戻り `group_id` をそのまま返す（現実装）

- `NewChatRemoteDataSourceImpl.createGroup` — [lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart](lib/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart)
  - HTTP リクエスト:
    - メソッド: POST
    - URL: `${ApiConfig.baseUrl}/api/v1/groups`
    - ヘッダ: `Content-Type: application/json`, Authorization は `AuthHttpClient` が付与
    - ボディ例:
      ```json
      {
        "name": "チームA",
        "creator_user_id": "user_123",
        "member_user_ids": ["user_123", "user_456"]
      }
      ```
  - 正常レスポンス期待値 (2xx): JSON 例 `{ "group_id": "grp_abc123...", "group_name": "チームA" }`
  - HTTP エラー: ステータスコード非2xx は `toAppException(response, endpoint)` を通じて `AppException` に変換される。

#### サーバー側（FastAPI）

- ルータ: `create_group` — [backend/chat_api/app/api/group_router.py](backend/chat_api/app/api/group_router.py)
  - 入力スキーマ: `CreateGroupRequest`（`creator_user_id`, `name`, `member_user_ids`）
  - 主な処理:
    1. 認証済みユーザー（`auth_user`）の ID と `creator_user_id` が一致するか検証。異なれば 403 を返す。
    2. `AppUser` テーブルに `creator_user_id` が存在することを確認（404）。
    3. `group_id` をサーバー側で採番（例: `grp_${uuid4().hex[:12]}`）し、`ChatGroup` を作成して `db.add(group)`。
    4. メンバーリスト（作成者を含めた集合）を生成し、既存の `AppUser` のみ `ChatGroupMember` に追加する（自動作成は行わない実装）。
    5. `await db.commit()` でコミット（ここでトランザクションが確定）。
    6. 成功レスポンス: `CreateGroupResponse(group_id=..., group_name=...)`

#### DB（重要な書き込み）

- `chat_groups` テーブルに1行追加（[backend/chat_api/app/models/models.py](backend/chat_api/app/models/models.py) `ChatGroup` クラス）
  - カラム: `id` (PRIMARY KEY), `name`, `creator_user_id`, `created_at`
  - 実装例: `group_id = f"grp_{uuid4().hex[:12]}"`

- `chat_group_members` テーブルに N 行追加
  - カラム: `id` (AUTOINCREMENT), `group_id` (FK), `user_id`
  - ユニーク制約: `uq_chat_group_member` (group_id, user_id)

#### 戻り値とフロント側での扱い

- DataSource は `group_id` を受け取り Repository が返し、UseCase が UI に返す（`String groupId`）
- UI は `groupId` を使って初期画面遷移やローカルキャッシュ更新を行う

#### 失敗ケースと対処

- **403** (creator mismatch): フロントは再ログインや権限エラーのダイアログを表示
- **404** (creator not found): 未登録ユーザーエラー。UI は詳細を示し、サポート誘導
- **ネットワーク/タイムアウト**: リトライ or ユーザーに再試行を促す
- **DB 制約違反**（例: ユニーク制約）: バックエンドで 409 を返す実装推奨。フロントは競合メッセージ表示。

#### 注意点（運用／改善）

- 同時作成やID重複を避けるためサーバ側で固有 ID を採番している。クライアント側では冪等性トークンを導入すると安全。
- グループ名の重複許容 or 不許容のポリシー決定とそのサーバチェック

---

### B. 新規ユーザー招待フロー（招待発行：発行者側）

概要: 発行者が `AddMemberPage` などから「招待リンクを生成」すると、フロントは `CreateGroupInviteUseCase` 経由で `POST /api/v1/group-invites` を呼び、サーバは招待テーブルにレコードを作成して `invite_code` と `invite_url` を返す。

#### フロント（呼び出し順）

- UI: `AddMemberPage` ボタン押下 → `createGroupInviteUseCase.call(groupId, requesterUserId, expiresInMinutes)`
  - [lib/features/new_chat/application/create_group_invite_usecase.dart](lib/features/new_chat/application/create_group_invite_usecase.dart)
- UseCase → Repository → DataSource の順で `remote.createInvite(...)` を呼び出す

#### HTTP リクエスト（DataSource 層）

- メソッド: POST
- URL: `${ApiConfig.baseUrl}/api/v1/group-invites`
- ボディ例:
  ```json
  {
    "group_id": "grp_abc123",
    "requester_user_id": "user_123",
    "expires_in_minutes": 60
  }
  ```

#### サーバー側（FastAPI）処理

- ルータ: `create_group_invite` — [backend/chat_api/app/api/group_router.py](backend/chat_api/app/api/group_router.py)
  1. `requester_user_id` と現在の `auth_user.id` を比較して一致を検証（403）。
  2. `ChatGroup` 存在チェック（404）、`AppUser` 存在チェック（404）
  3. 発行者がそのグループのメンバーであることを `ChatGroupMember` テーブルで確認（403）
  4. 招待コード生成（`INV-${uuid4().hex[:10]}`）
  5. `ChatGroupInvite` を作成し `db.add(invite)`、`await db.commit()` で永続化
  6. `invite_url` を組み立てて `CreateInviteResponse` を返却（`expires_at` は ISO 文字列）

#### DB 書き込み

- `chat_group_invites` テーブルに1行追加 — [backend/chat_api/app/models/models.py](backend/chat_api/app/models/models.py) の `ChatGroupInvite`
  - カラム: `id` (AUTOINCREMENT), `group_id` (FK), `invite_code`, `created_by_user_id`, `expires_at`, `created_at`, `consumed_by_user_id` (NULL), `consumed_at` (NULL)
  - ユニーク制約: `uq_chat_group_invite_code` (invite_code)

#### レスポンス例

```json
{
  "group_id": "grp_abc123",
  "invite_code": "INV-4F5A1C",
  "invite_url": "http://localhost:8080/invite/INV-4F5A1C",
  "expires_at": "2026-02-23T12:34:56+00:00"
}
```

#### フロントでの扱い

- `NewChatRepositoryImpl.createInvite` — [lib/features/new_chat/data/new_chat_repository_impl.dart](lib/features/new_chat/data/new_chat_repository_impl.dart)
  - 受け取った JSON から `GroupInviteInfo` を生成して返す
  - 実装上のポイント: `expires_at` は ISO 文字列→ `DateTime.tryParse` 変換し、失敗時は `DateTime.now()` にフォールバック

- UI は `inviteUrl` を表示・コピー・共有シートに渡す

#### 失敗ケースと注意

- **403** (requester not group member): 発行権限がない旨を UI に表示
- **404** (group/user not found): ユーザーまたはグループが存在しない
- **競合**: `invite_code` は `uq_chat_group_invite_code` のユニーク制約があるため、ごく稀に生成衝突が起きる可能性あり。バックエンドで生成衝突を検出したら再生成ループを実装するか、DBトランザクションで失敗時に再試行する。

#### セキュリティ上の考慮

- 招待コードの長さと予測困難性を確保する。公開 URL に含めるため、短すぎると当たり判定されやすい。
- 共有時のログと監査（誰がいつ発行したか）を `created_by_user_id` で追跡している。
- 招待が漏洩した場合に備え、有効期限と消費制御（1回 or 多回）を設けることを検討する。

---

### C. 招待を使って参加するフロー（受け手側）

概要: 受け手が `invite_code` を受け取りアプリ上で「参加」を選ぶと、フロントは `JoinGroupByInviteUseCase` を呼び、最終的に `POST /api/v1/group-invites/join` を呼んで参加処理を行う。

#### フロント（呼び出し順）

- `JoinGroupByInviteUseCase.call(inviteCode, userId)` を実行 — [lib/features/new_chat/application/join_group_by_invite_usecase.dart](lib/features/new_chat/application/join_group_by_invite_usecase.dart)
- `NewChatRepositoryImpl.joinByInviteCode` が `remote.joinByInviteCode(inviteCode, userId)` を呼ぶ

#### HTTP リクエスト（DataSource 層）

- メソッド: POST
- URL: `${ApiConfig.baseUrl}/api/v1/group-invites/join`
- ボディ例:
  ```json
  { "invite_code": "INV-4F5A1C", "user_id": "user_789" }
  ```

#### サーバー側（FastAPI）処理

- ルータ: `join_group_by_invite` — [backend/chat_api/app/api/group_router.py](backend/chat_api/app/api/group_router.py)
  1. `payload.user_id` と `auth_user.id` を比較（403）
  2. `ChatGroupInvite` を `invite_code` で検索。見つからなければ 404
  3. 期限チェック (`invite.expires_at < now`) → 410（Gone）
  4. 既に `consumed_at` がある場合は 409（Conflict）
  5. 対象 `ChatGroup` の存在確認（404）
  6. `AppUser` の存在確認（404）
  7. 既に `ChatGroupMember` に登録済みか確認
     - 未登録なら `ChatGroupMember` を `db.add(...)` して `joined = True`
     - すでにメンバーなら `joined = False`（冪等性を維持）
  8. `invite` の `consumed_by_user_id` と `consumed_at` をセットして `db.commit()`
  9. レスポンス: `JoinByInviteResponse(group_id=..., group_name=..., joined=bool)`

#### DB の状態変化

- 参加成功で `chat_group_members` に行が追加される（`uq_chat_group_member` に注意）
- `chat_group_invites` の `consumed_by_user_id` と `consumed_at` が更新される
- 同一招待による複数参加は `consumed_at` が既に set されているため、409 で拒否される（1回限りの実装）

#### 失敗ケースと UI 対応

- **404** (invite not found): 「招待コードが無効です」と表示
- **410** (expired): 「招待コードは期限切れです」と表示し再発行を促す
- **409** (already consumed): 「すでに使われた招待です」と表示
- **404** (user not found): ユーザー登録が完了していない場合はサインアップ促進

#### 実運用での注意

- 同時アクセス（複数端末が同じ invite を同時に消費しようとする場合）への対処は DB レベルのトランザクションとユニーク制約で担保しているが、409 をクライアントで受け取った場合の UX を設計しておくこと。
- 参加処理の後にプッシュ通知やリアルタイムのメンバーリスト更新が必要なら、参加コミット直後にイベントを発行（例: メッセージキューや WebSocket 経由）する。
- 複数回利用可能な招待への拡張を検討する場合は、`consumed_at` モデルから `usage_count` / `max_usage_count` モデルへの変更が必要。

---

## 具体的な HTTP レスポンス例（正常/エラー）

### 正常系

グループ作成 成功 (201 or 200):
```json
{
  "group_id": "grp_abc123",
  "group_name": "チームA"
}
```

招待作成 成功 (201 or 200):
```json
{
  "group_id": "grp_abc123",
  "invite_code": "INV-4F5A1C",
  "invite_url": "https://example.com/invite/INV-4F5A1C",
  "expires_at": "2026-02-23T12:34:56+00:00"
}
```

招待参加 成功 (200):
```json
{
  "group_id": "grp_abc123",
  "group_name": "チームA",
  "joined": true
}
```

### エラー系（バックエンドが返すHTTPステータスと想定レスポンス）

```
400: リクエスト不正（validation error）
401/403: 認証/権限エラー（例: 未ログイン、別ユーザーによる操作）
404: リソース未発見（group / user / invite not found）
409: 競合（invite already consumed, unique constraint collision）
410: 期限切れ（invite expired）
5xx: サーバーエラー
```

クライアントでは `api_error_parser.toAppException` がレスポンス本文を parse して `AppException` を生成するため、フロントは `try/catch` で `AppException` を捕捉してメッセージを表示する実装が既存の方針。

---

## テスト／検証の観点

### ユニットテスト

- **UseCase**: モック Repository を注入して成功・失敗パスを検証
  - `CreateChatUsecase`: パラメータ検証→ repo 呼び出しまで
  - `CreateGroupInviteUseCase`: パラメータ→ repo 呼び出しまで
  - `JoinGroupByInviteUseCase`: 形式チェック→ repo 呼び出しまで

- **RepositoryImpl**: モック DataSource を注入して JSON マッピングを検証
  - `NewChatRepositoryImpl.createChat`: group_id 抽出の正確性
  - `NewChatRepositoryImpl.createInvite`: expires_at パース、GroupInviteInfo 構築
  - `NewChatRepositoryImpl.joinByInviteCode`: JoinGroupResult 構築、エラーハンドリング

- **DataSourceImpl**: HTTP クライアントをスタブしてステータスコード別の挙動を検証
  - `NewChatRemoteDataSourceImpl.createGroup`: リクエストボディ構築、レスポンスパース、HTTP エラーマッピング

### 統合テスト（Backend + DB + Front）

- `backend/chat_api` をテスト用 DB（sqlite in-memory 等）で立ち上げ、実際に HTTP を投げて DB の変化を検証する
- 招待のライフサイクル（作成→参加→既消費）を順にテスト
- 並行処理テスト：複数ユーザーが同時にグループに参加する場合のユニーク制約と冪等性確認

---

## 参考：データベーススキーマ概要

[backend/chat_api/app/models/models.py](backend/chat_api/app/models/models.py) の主要テーブル:

- `AppUser`: ユーザーテーブル（`id`, `display_name`, `photo_url`, `created_at`, `updated_at`）
- `ChatGroup`: グループテーブル（`id`, `name`, `creator_user_id`, `created_at`）
- `ChatGroupMember`: グループメンバーシップテーブル（`id`, `group_id`, `user_id`, UC: `group_id+user_id`）
- `ChatGroupInvite`: 招待テーブル（`id`, `group_id`, `invite_code`, `created_by_user_id`, `expires_at`, `created_at`, `consumed_by_user_id`, `consumed_at`, UC: `invite_code`）

---

このセクションは `backend/chat_api/app/api/group_router.py`、`backend/chat_api/app/models/models.py` の現在の実装に基づいています。実装が変わった場合は、ここにあるエンドポイント、レスポンス、DB スキーマとの整合性を再チェックして更新してください。


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
