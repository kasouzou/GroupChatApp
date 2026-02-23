# 依存性注入（Dependency Injection）の思想と実装ガイド

このドキュメントは、GroupChatApp プロジェクトで採用されている依存性注入（DI）の基本思想、設計パターン、そして実装フロー全体をカバーする包括的なガイドです。

---

## 目次

1. [DI の基本思想](#1-di-の基本思想)
2. [従来のコード（DI なし）](#2-従来のコード（di-なし）)
3. [DI を使ったコード](#3-di-を使ったコード)
4. [このプロジェクトで採用している Riverpod](#4-このプロジェクトで採用している-riverpod)
5. [Provider の具体的な実装例](#5-provider-の具体的な実装例)
6. [処理フロー全体（UI から API まで）](#6-処理フロー全体（ui-から-api-まで）)
7. [テスト容易性](#7-テスト容易性)
8. [メモリ管理とリソース解放](#8-メモリ管理とリソース解放)
9. [このプロジェクトでの DI パターン集](#9-このプロジェクトでの-di-パターン集)
10. [よくある課題と対策](#10-よくある課題と対策)

---

## 1. DI の基本思想

### 1.1 DI とは何か

**依存性注入（Dependency Injection）** は、クラスが必要とするオブジェクト（依存性）を、そのクラスの外部から提供するデザインパターンです。

#### キーコンセプト

```
┌─────────────────────────────────────────────────────┐
│ DI の根本思想                                        │
├─────────────────────────────────────────────────────┤
│                                                     │
│ クラスが「何を使うか」を自分で作らない。           │
│ 外部から「何を使うか」を渡してもらう。             │
│                                                     │
│ これにより：                                        │
│ - クラスは自分の仕事に集中できる                   │
│ - クラス間の結合度を低下させられる                 │
│ - テストが容易になる                               │
│ - 実装を入れ替えやすくなる                         │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 1.2 DI の4つの主要な利点

#### (1) 疎結合（Loose Coupling）

```
┌─────────────────────────────────────────────────┐
│ 疎結合とは                                       │
├─────────────────────────────────────────────────┤
│                                                 │
│ クラスA が クラスB に依存する度合いを低くする  │
│                                                 │
│ [従来の密結合]                                  │
│ Class A がクラスB を new で作成                 │
│    ↓ A と B が強く結びついている                │
│    ↓ B が変わったら A も変わる必要がある       │
│                                                 │
│ [DI による疎結合]                               │
│ Class A が InterfaceB を受け取る               │
│    ↓ A は InterfaceB の仕様のみ知っていれば良い│
│    ↓ B の実装が変わっても A は変わらない       │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### (2) 再利用性（Reusability）

```
┌─────────────────────────────────────────────────┐
│ 再利用性の向上                                   │
├─────────────────────────────────────────────────┤
│                                                 │
│ DI を使うと、同じコンポーネントを異なる        │
│ コンテキストで再利用しやすくなる               │
│                                                 │
│ 例）                                            │
│ AuthHttpClient を NewChat でも Message でも   │
│ Profile でも使える                              │
│  ↓ HTTP クライアントの生成ロジックを           │
│    一箇所に集約できるから                       │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### (3) テスト容易性（Testability）

```
┌─────────────────────────────────────────────────┐
│ テスト容易性の向上                               │
├─────────────────────────────────────────────────┤
│                                                 │
│ DI を使うと、本物のオブジェクトの代わりに      │
│ モック（偽のオブジェクト）を注入できる         │
│                                                 │
│ 例）                                            │
│ NewChatRepository を テストするとき             │
│  - 本当の http.Client の代わりに               │
│  - 偽の http.Client（モック）を注入           │
│  → 実際のAPI呼び出しなしにテストできる        │
│                                                 │
└─────────────────────────────────────────────────┘
```

#### (4) 実装の交換可能性（Substitutability）

```
┌─────────────────────────────────────────────────┐
│ 実装の切り替えが簡単                             │
├─────────────────────────────────────────────────┤
│                                                 │
│ 例）データベースを変更する場合                  │
│                                                 │
│ [DI なし]                                       │
│ Repository が直接 SQLiteDatabase を使っている  │
│   ↓ PostgreSQL に変える には                    │
│   ↓ Repository の実装を全て書き換える必要がある│
│                                                 │
│ [DI あり]                                       │
│ Repository が IDatabase インターフェース使用   │
│   ↓ SQLiteDatabase の代わりに                  │
│   ↓ PostgreSQL 実装を注入するだけで OK         │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## 2. 従来のコード（DI なし）

### 2.1 密結合な設計の問題点

```dart
// ❌ DI を使わないコード（問題あり）

// データベースから直接ユーザー情報を取得
class UserRepository {
  final DatabaseConnection _db = DatabaseConnection(); // 直接作成！
  
  Future<User> getUser(String userId) async {
    return _db.query('SELECT * FROM users WHERE id = ?', [userId]);
  }
}

// API 経由でユーザー情報を取得
class GetUserUseCase {
  // リポジトリを new で作成
  final UserRepository _repository = UserRepository();
  
  Future<User> execute(String userId) async {
    return _repository.getUser(userId);
  }
}

// UI からユースケースを使用
class UserProfilePage extends StatefulWidget {
  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  // ユースケースを new で作成
  final GetUserUseCase _useCase = GetUserUseCase();
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _useCase.execute('user123'),
      child: Text('ユーザー情報取得'),
    );
  }
}
```

#### このコードの問題点

| 問題 | 説明 | 影響 |
|------|------|------|
| **密結合** | UserProfilePage が GetUserUseCase に強く依存 | GetUserUseCase が変わるたびに UserProfilePage も変える必要がある |
| **テスト困難** | 実際のデータベースが必ず動く | ネットワークなしでテストできない |
| **実装固定** | DatabaseConnection が SQLite に決まっている | PostgreSQL に変えるには全コードを修正 |
| **リソース管理** | DatabaseConnection がいつ close されるか不明確 | メモリリークの可能性 |

---

## 3. DI を使ったコード

### 3.1 コンストラクタインジェクション

```dart
// ✅ DI を使ったコード（改善版）

// インターフェース（契約）を定義
abstract class IDatabase {
  Future<User> queryUser(String userId);
}

// 実装 1: SQLite
class SQLiteDatabase implements IDatabase {
  late final DatabaseConnection _connection;
  
  SQLiteDatabase() {
    _connection = DatabaseConnection();
  }
  
  @override
  Future<User> queryUser(String userId) async {
    return _connection.query('SELECT * FROM users WHERE id = ?', [userId]);
  }
}

// 実装 2: PostgreSQL
class PostgreSQLDatabase implements IDatabase {
  late final PostgreSQLConnection _connection;
  
  PostgreSQLDatabase() {
    _connection = PostgreSQLConnection();
  }
  
  @override
  Future<User> queryUser(String userId) async {
    return _connection.query('SELECT * FROM users WHERE id = ?', [userId]);
  }
}

// リポジトリは IDatabase を受け取る（コンストラクタインジェクション）
class UserRepository {
  final IDatabase _database; // インターフェースに依存
  
  // 外部から実装を受け取る
  UserRepository({required IDatabase database}) : _database = database;
  
  Future<User> getUser(String userId) async {
    return _database.queryUser(userId);
  }
}

// ユースケースもコンストラクタで受け取る
class GetUserUseCase {
  final UserRepository _repository;
  
  GetUserUseCase({required UserRepository repository}) : _repository = repository;
  
  Future<User> execute(String userId) async {
    return _repository.getUser(userId);
  }
}

// UI からはプロバイダー経由で取得
class UserProfilePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // プロバイダーから取得（実装の詳細は隠れている）
        final useCase = ref.read(getUserUseCaseProvider);
        await useCase.execute('user123');
      },
      child: Text('ユーザー情報取得'),
    );
  }
}
```

#### このコードの利点

| 利点 | 説明 | 効果 |
|------|------|------|
| **疎結合** | インターフェースに依存 | GetUserUseCase の仕様が変わってもプロバイダーを調整するだけで OK |
| **テスト簡単** | モック実装を注入可能 | `MockDatabase` を注入して実装の詳細なし でテスト可能 |
| **実装切り替え** | 異なる IDatabase の実装を切り替え可能 | SQLite → PostgreSQL の切り替えが簡単 |
| **リソース管理** | DI フレームワークが一元管理 | `ref.onDispose()` で自動的にリソース解放 |

---

## 4. このプロジェクトで採用している Riverpod

### 4.1 Riverpod とは

```
┌───────────────────────────────────────────────────┐
│ Riverpod（リバーポッド）                          │
├───────────────────────────────────────────────────┤
│                                                   │
│ Dart/Flutter 向けの DI フレームワーク             │
│                                                   │
│ 特徴：                                            │
│ - Provider ベースの設計                          │
│ - グローバルな依存性管理                          │
│ - リアクティブな値の管理                          │
│ - テスト時のオーバーライド対応                    │
│ - リソースの自動管理（ref.onDispose）            │
│                                                   │
│ 公式ページ: https://riverpod.dev                 │
│                                                   │
└───────────────────────────────────────────────────┘
```

### 4.2 Provider の基本

```dart
// 基本的な Provider の定義方法

// [1] 単純な値を返すプロバイダー
final simpleValueProvider = Provider<String>((ref) {
  return 'Hello, World!';
});

// [2] 依存性を受け取るプロバイダー
final dependentProvider = Provider<int>((ref) {
  // 他のプロバイダーの値を取得
  final value = ref.read(simpleValueProvider);
  return value.length; // 'Hello, World!' の長さ = 13
});

// [3] 非同期処理を扱うプロバイダー
final asyncProvider = FutureProvider<User>((ref) async {
  // 非同期処理（API呼び出しなど）
  return await api.getUser('user123');
});

// [4] リソース管理をするプロバイダー
final resourceProvider = Provider<HttpClient>((ref) {
  final client = HttpClient();
  
  // cleanup 処理
  ref.onDispose(() {
    client.close();
  });
  
  return client;
});
```

### 4.3 Riverpod が Singleton パターンを実現

```
┌─────────────────────────────────────────────┐
│ Riverpod による Singleton 管理               │
├─────────────────────────────────────────────┤
│                                             │
│ final httpClientProvider = Provider((ref) {
│   return HttpClient();
│ });
│                                             │
│ ↓ Riverpod が以下を自動実行                 │
│                                             │
│ 1. 初回アクセス時に HttpClient() を作成     │
│ 2. それ以降は同じインスタンスを再利用       │
│ 3. Provider が破棄されるまで保持            │
│ 4. 破棄時に ref.onDispose() を実行         │
│                                             │
│ → 複数の場所で httpClientProvider を        │
│   読み込んでも、同じ HttpClient が          │
│   返される（Singleton）                    │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 5. Provider の具体的な実装例

このセクションでは、GroupChatApp の実際のコードから DI パターンを分析します。

### 5.1 HTTP クライアントプロバイダー

**ファイル**: `lib/features/new_chat/di/new_chat_repository_provider.dart`

```dart
/// NewChat用HTTPクライアント。
/// Provider破棄時にcloseしてソケットリークを防ぐ。
final newChatHttpClientProvider = Provider<http.Client>((ref) {
  // [Step 1] 生のHTTPクライアントを作成
  final rawClient = http.Client();
  
  // [Step 2] 認証機能を追加したラッパーを作成
  final client = AuthHttpClient(
    inner: rawClient,
    // 認証セッションプロバイダーから動的にトークンを取得
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken,
  );
  
  // [Step 3] リソース管理：破棄時に自動で close() を呼ぶ
  ref.onDispose(client.close);
  
  return client;
});
```

#### このプロバイダーの処理フロー

```
┌──────────────────────────────────────────────────┐
│ newChatHttpClientProvider の実行フロー            │
└──────────────────────┬───────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        ▼                             ▼
    初回アクセス               2回目以降のアクセス
        │                             │
        ▼                             ▼
    [1] http.Client()        同じ AuthHttpClient
        │                    を返す（キャッシュ）
        ▼
    [2] AuthHttpClient に wrap
        │
        ├─ tokenProvider を登録
        │  （authSessionProvider から
        │   トークンを動的に取得する関数）
        │
        ▼
    [3] ref.onDispose を登録
        │  破棄時に client.close()
        │  を呼ぶ
        │
        ▼
    AuthHttpClient を返す
```

#### なぜ ref.read(authSessionProvider) なのか？

```dart
tokenProvider: () => ref.read(authSessionProvider)?.accessToken
                      │
                      └─ 毎回呼ばれるたびに最新のトークンを取得する
                      
// こうすることで：
// - ログイン前: tokenProvider() は null を返す
// - ログイン後: tokenProvider() は有効なトークンを返す
// - ログアウト後: tokenProvider() は null を返す
```

### 5.2 リモートデータソースプロバイダー

```dart
/// NewChat用リモートデータソース。
/// API仕様変更時はこの層の実装を差し替える。
final newChatRemoteDataSourceProvider = Provider<NewChatRemoteDataSource>((
  ref,
) {
  // [依存性] HTTP クライアントを取得
  final client = ref.watch(newChatHttpClientProvider);
  
  // [構成] クライアントを注入して具体実装を作成
  return NewChatRemoteDataSourceImpl(client);
});
```

#### 多層の依存関係

```
┌─────────────────────────────────────────────┐
│ Provider の依存関係チェーン                  │
└─────────────────────────────────────────────┘

newChatRemoteDataSourceProvider
    │
    └─ ref.watch(newChatHttpClientProvider)
        │
        └─ AuthHttpClient
            │
            ├─ http.Client (raw)
            │
            └─ ref.read(authSessionProvider)
                │
                └─ ユーザーのセッション情報
```

### 5.3 リポジトリプロバイダー

```dart
/// NewChat用Repository。
/// UseCaseはこの抽象経由で利用し、通信実装を意識しない。
final newChatRepositoryProvider = Provider<NewChatRepository>((ref) {
  // [依存性] リモートデータソースを取得
  final remote = ref.watch(newChatRemoteDataSourceProvider);
  
  // [構成] 具体実装を作成
  return NewChatRepositoryImpl(remote: remote);
});
```

### 5.4 ユースケースプロバイダー（例：招待コード作成）

```dart
// 通常、プロジェクト内に定義されているはず
final createGroupInviteUseCaseProvider = Provider<CreateGroupInviteUseCase>((ref) {
  // [依存性] Repository を取得
  final repository = ref.watch(newChatRepositoryProvider);
  
  // [構成] ユースケースを作成
  return CreateGroupInviteUseCase(repository: repository);
});
```

---

## 6. 処理フロー全体（UI から API まで）

このセクションでは、実際のユースケース（グループ作成）を通じて、DI がどのように機能するかを段階的に説明します。

### 6.1 ユーザーがボタンをタップしてからレスポンスが返るまで

```
┌──────────────────────────────────────────────────────────────┐
│ AddMemberPage - グループ作成ボタンをタップ                  │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ [UI Layer] AddMemberPage._refreshInvite() が実行される       │
│                                                              │
│ void _refreshInvite() {                                     │
│   // 手順 1: プロバイダーから UseCase を取得する           │
│   final useCase = ref.read(                                │
│     createGroupInviteUseCaseProvider                       │
│   );                                                        │
│                                                              │
│   // 手順 2: UseCase を実行                                │
│   final info = await useCase.call(                         │
│     groupId: groupId,                                      │
│     requesterUserId: userId,                               │
│     expiresInMinutes: 5,                                   │
│   );                                                        │
│                                                              │
│   // 手順 3: 結果で UI を更新                              │
│   setState(() => _inviteInfo = info);                      │
│ }                                                            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼ ③ ref.read(createGroupInviteUseCaseProvider)
┌──────────────────────────────────────────────────────────────┐
│ [DI Framework - Riverpod] プロバイダーチェーンが発動         │
│                                                              │
│ createGroupInviteUseCaseProvider
│   ├─ 初回呼び出しか判定
│   │
│   ├─ [初回] プロバイダーを実行
│   │   │
│   │   └─ ref.watch(newChatRepositoryProvider) を取得
│   │       │
│   │       ▼
│   │       newChatRepositoryProvider を実行
│   │        └─ ref.watch(newChatRemoteDataSourceProvider)
│   │            │
│   │            ▼
│   │            newChatRemoteDataSourceProvider を実行
│   │             └─ ref.watch(newChatHttpClientProvider)
│   │                 │
│   │                 ▼
│   │                 newChatHttpClientProvider を実行
│   │                  ├─ http.Client() を作成
│   │                  ├─ AuthHttpClient でラップ
│   │                  ├─ ref.onDispose(client.close) を登録
│   │                  └─ AuthHttpClient を返す
│   │                   │
│   │                   ▼ ← ref.read(authSessionProvider)
│   │                   トークンをここで取得
│   │                   （まだ使わない、関数として保存）
│   │
│   └─ [2回目以降] キャッシュされたインスタンスを返す
│
│ ← newChatHttpClientProvider が返す
│
│ この AuthHttpClient を使って
│ NewChatRemoteDataSourceImpl を作成
│
│ ← newChatRemoteDataSourceProvider が返す
│
│ このリモートデータソースを使って
│ NewChatRepositoryImpl を作成
│
│ ← newChatRepositoryProvider が返す
│
│ このリポジトリを使って
│ CreateGroupInviteUseCase を作成
│
│ ← CreateGroupInviteUseCase インスタンスを返す
│
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼ ④ await useCase.call(...)
┌──────────────────────────────────────────────────────────────┐
│ [UseCase Layer] CreateGroupInviteUseCase                     │
│                                                              │
│ class CreateGroupInviteUseCase {                            │
│   final NewChatRepository _repository;                      │
│                                                              │
│   Future<GroupInviteInfo> call({...}) async {              │
│     // ビジネスロジック（バリデーション等）を実行           │
│     // その後、Repository を呼ぶ                            │
│     return await _repository.createInvite(...);             │
│   }                                                          │
│ }                                                            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ [Repository Layer] NewChatRepositoryImpl                      │
│                                                              │
│ class NewChatRepositoryImpl implements NewChatRepository {   │
│   final NewChatRemoteDataSource _remote;                    │
│                                                              │
│   Future<GroupInviteInfo> createInvite({...}) async {      │
│     // リモートデータソースを呼び出す                       │
│     final rawData = await _remote.createInvite(...);        │
│     // レスポンスをエンティティにマッピング                 │
│     return GroupInviteInfo.fromJson(rawData);              │
│   }                                                          │
│ }                                                            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ [DataSource Layer] NewChatRemoteDataSourceImpl                │
│                                                              │
│ class NewChatRemoteDataSourceImpl                            │
│     implements NewChatRemoteDataSource {                    │
│   final http.Client _client;                               │
│                                                              │
│   Future<Map<String, dynamic>> createInvite({...}) async { │
│     // HTTP POST リクエストを送信                           │
│     final response = await _client.post(                   │
│       uri,                                                 │
│       headers: {...},                                      │
│       body: jsonEncode({...}),                             │
│     );                                                      │
│                                                              │
│     // ここで AuthHttpClient が自動的に以下を実行：        │
│     // 1. tokenProvider() を呼び出し                       │
│     // 2. authSessionProvider の最新値を取得               │
│     // 3. 'Authorization: Bearer <token>' を追加            │
│     // 4. request.headers.putIfAbsent(...) で付与         │
│     // 5. 内部の http.Client.send() にリクエスト送信       │
│                                                              │
│     // レスポンスをチェック                                 │
│     if (response.statusCode >= 400) {                      │
│       throw toAppException(response);                      │
│     }                                                        │
│                                                              │
│     return jsonDecode(response.body);                      │
│   }                                                          │
│ }                                                            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼ (HTTP送信)
┌──────────────────────────────────────────────────────────────┐
│ [ネットワーク層] HTTP通信                                    │
│                                                              │
│ AuthHttpClient が以下を実行：                               │
│                                                              │
│ @override                                                  │
│ Future<http.StreamedResponse> send(                        │
│   http.BaseRequest request                                │
│ ) async {                                                  │
│   // 最新のトークンを動的に取得                            │
│   final token = await _tokenProvider();                    │
│                                                              │
│   // トークンをヘッダーに追加                               │
│   if (token != null && token.trim().isNotEmpty) {          │
│     request.headers.putIfAbsent(                           │
│       'Authorization',                                     │
│       () => 'Bearer $token',  ← ここがポイント！           │
│     );                                                      │
│   }                                                          │
│                                                              │
│   // 実際のHTTP送信を実行                                  │
│   return _inner.send(request);                            │
│ }                                                            │
│                                                              │
│ POST /api/v1/group-invites                                │
│ Authorization: Bearer eyJhbGciOiJIUzI1NiIs...             │
│ Content-Type: application/json                             │
│ {                                                           │
│   "group_id": "grp_abc123",                               │
│   "requester_user_id": "user456",                          │
│   "expires_in_minutes": 5                                  │
│ }                                                            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼ (バックエンド処理)
┌──────────────────────────────────────────────────────────────┐
│ [Backend - FastAPI] /api/v1/group-invites                   │
│                                                              │
│ @router.post("/group-invites")                             │
│ async def create_group_invite(                             │
│   payload: CreateInviteRequest,                            │
│   auth_user: AuthUser = Depends(require_auth_user),       │
│ ):                                                          │
│   # トークン検証（require_auth_user）                      │
│   # グループ存在確認                                       │
│   # メンバーシップ確認                                     │
│   # 招待コード生成                                         │
│   # DBに保存                                               │
│   return {                                                  │
│     "group_id": "grp_abc123",                              │
│     "invite_code": "INV-XYZ789",                           │
│     "invite_url": "https://example.com/invite/INV-XYZ789", │
│     "expires_at": "2026-02-23T15:30:00"                   │
│   }                                                          │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼ (レスポンス送信)
┌──────────────────────────────────────────────────────────────┐
│ [ネットワーク層] HTTP レスポンス受信                         │
│                                                              │
│ Status: 200 OK                                              │
│ Content-Type: application/json                              │
│ {                                                            │
│   "group_id": "grp_abc123",                                │
│   "invite_code": "INV-XYZ789",                             │
│   "invite_url": "https://example.com/invite/INV-XYZ789",   │
│   "expires_at": "2026-02-23T15:30:00"                     │
│ }                                                            │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼ response オブジェクトが返される
┌──────────────────────────────────────────────────────────────┐
│ [DataSource Layer] NewChatRemoteDataSourceImpl（続き）        │
│                                                              │
│ // レスポンスを JSON パース                                 │
│ final rawData = jsonDecode(response.body);                 │
│ //                                                          │
│ // {                                                        │
│ //   "group_id": "grp_abc123",                             │
│ //   "invite_code": "INV-XYZ789",                          │
│ //   "invite_url": "https://...",                          │
│ //   "expires_at": "2026-02-23T15:30:00"                   │
│ // }                                                         │
│                                                              │
│ return rawData;  // Map<String, dynamic> として返す        │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ [Repository Layer] NewChatRepositoryImpl（続き）             │
│                                                              │
│ // rawData を GroupInviteInfo にマッピング                 │
│ return GroupInviteInfo(                                    │
│   groupId: rawData['group_id'],                            │
│   inviteCode: rawData['invite_code'],                      │
│   inviteUrl: rawData['invite_url'],                        │
│   expiresAt: DateTime.parse(rawData['expires_at']),        │
│ );                                                           │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ [UseCase Layer] CreateGroupInviteUseCase（続き）             │
│                                                              │
│ // Repository からの GroupInviteInfo を返す                │
│ return await _repository.createInvite(...);                │
│ // → GroupInviteInfo インスタンス                           │
└────────────────┬─────────────────────────────────────────────┘
                 │
                 ▼
┌──────────────────────────────────────────────────────────────┐
│ [UI Layer] AddMemberPage._refreshInvite()（続き）            │
│                                                              │
│ final info = await useCase.call(...);                      │
│ // info = GroupInviteInfo(                                 │
│ //   inviteCode: 'INV-XYZ789',                             │
│ //   inviteUrl: 'https://example.com/invite/INV-XYZ789',   │
│ //   expiresAt: DateTime(2026, 2, 23, 15, 30),             │
│ // )                                                         │
│                                                              │
│ setState(() => _inviteInfo = info);  // UI を更新          │
│                                                              │
│ // build() が再実行される                                  │
│ // inviteCode = info.inviteCode ?? '----'                 │
│ // qrData = info.inviteUrl ?? 'INVITE_NOT_READY'          │
│ // expiresAt = info.expiresAt                              │
│                                                              │
│ // 画面に表示される：                                       │
│ // QR コード: INV-XYZ789の QR                             │
│ // 招待コード: INV-XYZ789                                  │
│ // 有効期限: 2026-02-23 15:30                             │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 各レイヤーの責任

```
┌─────────────────────────────────────────────────────────────┐
│ レイヤーアーキテクチャと DI                                  │
└─────────────────────────────────────────────────────────────┘

UI Layer (AddMemberPage)
  └─ 責任: ユーザー操作の受け付け、画面表示
  └─ DI: ref.read(useCase) で UseCase を取得
  └─ 知らなくてよいこと: UseCase の内部実装

UseCase Layer (CreateGroupInviteUseCase)
  └─ 責任: ビジネスロジック（バリデーション、フロー制御）
  └─ DI: コンストラクタで Repository を受け取る
  └─ 知らなくてよいこと: Repository がどこからデータを取得するか

Repository Layer (NewChatRepositoryImpl)
  └─ 責任: データ取得の抽象化（複数ソースの統合）
  └─ DI: コンストラクタで DataSource を受け取る
  └─ 知らなくてよいこと: DataSource が API なのかキャッシュなのか

DataSource Layer (NewChatRemoteDataSourceImpl)
  └─ 責任: 実際の外部 API 呼び出し
  └─ DI: コンストラクタで http.Client を受け取る
  └─ 知らなくてよいこと: http.Client がどのように作られたか

Network Layer (AuthHttpClient + http.Client)
  └─ 責任: HTTP 通信の実装
  └─ DI: Riverpod Provider で一元管理
  └─ 知らなくてよいこと: ネットワークライブラリの詳細
```

---

## 7. テスト容易性

DI の最大の利点の一つが、テストの容易さです。

### 7.1 ユニットテストの例

```dart
// test/features/new_chat/domain/usecases/create_group_invite_usecase_test.dart

void main() {
  group('CreateGroupInviteUseCase', () {
    test('有効なリクエストで招待コードを返す', () async {
      // [Setup] モックを作成
      final mockRepository = MockNewChatRepository();
      
      // [Setup] モックの動作を定義
      when(mockRepository.createInvite(
        groupId: anyNamed('groupId'),
        requesterUserId: anyNamed('requesterUserId'),
        expiresInMinutes: anyNamed('expiresInMinutes'),
      )).thenAnswer((_) async => GroupInviteInfo(
        groupId: 'grp_test123',
        inviteCode: 'INV-TEST789',
        inviteUrl: 'https://test.example.com/invite/INV-TEST789',
        expiresAt: DateTime.now().add(Duration(minutes: 5)),
      ));
      
      // [Action] UseCase を実行（モック Repository を注入）
      final useCase = CreateGroupInviteUseCase(repository: mockRepository);
      final result = await useCase.call(
        groupId: 'grp_test123',
        requesterUserId: 'user_test456',
        expiresInMinutes: 5,
      );
      
      // [Assert] 結果を検証
      expect(result.inviteCode, equals('INV-TEST789'));
      expect(result.groupId, equals('grp_test123'));
      
      // [Assert] モックが呼ばれたことを確認
      verify(mockRepository.createInvite(
        groupId: 'grp_test123',
        requesterUserId: 'user_test456',
        expiresInMinutes: 5,
      )).called(1);
    });
  });
}
```

#### DI なしでのテストの困難さ

```dart
// ❌ DI がないテスト（困難）
test('有効なリクエストで招待コードを返す', () async {
  // UseCase が直接 Repository を new で作成している場合：
  final useCase = CreateGroupInviteUseCase();
  
  // ⚠️ 問題：実際のバックエンド API が呼ばれる
  // - ネットワーク接続が必要
  // - テストが遅い
  // - 本当の API に影響を与える
  // - バックエンドが down していると失敗する
  
  final result = await useCase.call(
    groupId: 'grp_test123',
    requesterUserId: 'user_test456',
    expiresInMinutes: 5,
  );
  
  // テストが本当に useCase のロジックをテストしているのか、
  // ネットワーク接続をテストしているのか不明確
});
```

#### DI ありでのテストの利点

```dart
// ✅ DI があるテスト（容易）
test('有効なリクエストで招待コードを返す', () async {
  // [1] モック Repository を作成
  //     → 実際のネットワーク呼び出しは発生しない
  final mockRepository = MockNewChatRepository();
  
  // [2] モックの動作を定義
  //     → 予測可能な結果を返す
  when(mockRepository.createInvite(...)).thenAnswer((_) async => 
    GroupInviteInfo(...));
  
  // [3] UseCase にモック Repository を注入
  //     → 完全に隔離されたテスト環境
  final useCase = CreateGroupInviteUseCase(repository: mockRepository);
  
  // [4] UseCase の純粋なロジックだけをテストできる
  final result = await useCase.call(...);
  
  // テストが高速（ネットワーク待機なし）
  // テストが安定（バックエンド状態に依存しない）
  // テストが明確（useCase のロジックのみをテスト）
});
```

### 7.2 統合テストでの DI オーバーライド

Riverpod は Provider をオーバーライドしてテストできます。

```dart
void main() {
  testWidgets('グループ招待コード取得フロー', (tester) async {
    // [Setup] モック Provider を作成
    final mockRepository = MockNewChatRepository();
    when(mockRepository.createInvite(...)).thenAnswer(
      (_) async => GroupInviteInfo(
        inviteCode: 'INV-TEST789',
        inviteUrl: 'https://test/invite/INV-TEST789',
        expiresAt: DateTime.now().add(Duration(minutes: 5)),
      ),
    );
    
    // [Setup] Provider をオーバーライド
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          newChatRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MyApp(),
      ),
    );
    
    // [Action] ボタンをタップ
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    
    // [Assert] 招待コードが表示されることを確認
    expect(find.text('INV-TEST789'), findsOneWidget);
  });
}
```

---

## 8. メモリ管理とリソース解放

DI フレームワークによるリソース管理の自動化。

### 8.1 ref.onDispose の役割

```dart
final newChatHttpClientProvider = Provider<http.Client>((ref) {
  final rawClient = http.Client();
  final client = AuthHttpClient(inner: rawClient, ...);
  
  // [重要] Provider が破棄されるときに自動実行
  ref.onDispose(client.close);
  
  return client;
});

// リソース管理フロー：
// 
// 1. 初回アクセス：client = http.Client() が作成される
//    ↓ ソケット確保
//
// 2. 複数回アクセス：同じ client インスタンスが再利用される
//    ↓ メモリ効率的
//
// 3. Provider が不要になる：自動的に ref.onDispose() が実行
//    ↓ client.close() が呼ばれる
//    ↓ ソケット解放
//    ↓ メモリリーク防止
```

### 8.2 複数の cleanup 処理

```dart
final complexResourceProvider = Provider<ComplexResource>((ref) {
  final resource = ComplexResource();
  
  // 複数の cleanup 処理を登録可能
  ref.onDispose(() {
    print('cleanup 1');
    resource.closeConnection();
  });
  
  ref.onDispose(() {
    print('cleanup 2');
    resource.flushCache();
  });
  
  ref.onDispose(() {
    print('cleanup 3');
    resource.dispose();
  });
  
  // 登録順の逆順で実行される：
  // cleanup 3 → cleanup 2 → cleanup 1
  
  return resource;
});
```

---

## 9. このプロジェクトでの DI パターン集

### 9.1 単純な値プロバイダー

```dart
// 認証セッション情報
final authSessionProvider = Provider<AuthSession?>((ref) {
  // 認証情報を取得・管理するロジック
  return AuthSession(
    id: 'user123',
    accessToken: 'eyJhbGc...',
    refreshToken: 'refresh_token...',
  );
});

// 使用例
final userId = ref.read(authSessionProvider)?.id;
```

### 9.2 非同期データプロバイダー

```dart
// 非同期で API からデータを取得
final getUserProvider = FutureProvider<User>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser('user123');
});

// 使用例
final userAsync = ref.watch(getUserProvider);
if (userAsync.when(
  data: (user) => Text(user.name),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
));
```

### 9.3 ネストされた依存性

```dart
// Provider1
final baseUrlProvider = Provider<String>((ref) {
  return 'https://api.example.com';
});

// Provider2: Provider1 に依存
final httpClientProvider = Provider<http.Client>((ref) {
  final baseUrl = ref.watch(baseUrlProvider);
  // baseUrl を使ってクライアントを構成
  return AuthHttpClient(...);
});

// Provider3: Provider2 に依存
final apiServiceProvider = Provider<ApiService>((ref) {
  final client = ref.watch(httpClientProvider);
  return ApiService(client: client);
});

// Provider4: Provider3 に依存
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserRepository(apiService: apiService);
});

// ↓ 変更時の波及：
// baseUrlProvider を変更
//   → httpClientProvider が自動更新
//     → apiServiceProvider が自動更新
//       → userRepositoryProvider が自動更新
//         → UI が再構築
```

### 9.4 状態を持つプロバイダー（StateNotifier）

```dart
// 状態を管理するクラス
class UserNotifier extends StateNotifier<User?> {
  final UserRepository _repository;
  
  UserNotifier({required UserRepository repository})
      : _repository = repository,
        super(null);
  
  Future<void> loadUser(String userId) async {
    state = await _repository.getUser(userId);
  }
  
  Future<void> updateUser(User user) async {
    await _repository.updateUser(user);
    state = user;
  }
}

// StateNotifierProvider
final userNotifierProvider = StateNotifierProvider<UserNotifier, User?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository: repository);
});

// 使用例
final user = ref.watch(userNotifierProvider);
ref.read(userNotifierProvider.notifier).updateUser(newUser);
```

### 9.5 キャッシュを伴うプロバイダー

```dart
// データをキャッシュして再利用
final cachedUserProvider = FutureProvider.autoDispose<User>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  // autoDispose: 使われなくなったら自動破棄
  return await repository.getUser('user123');
});

// ref.refresh() でキャッシュを無効化
ref.refresh(cachedUserProvider);
```

---

## 10. よくある課題と対策

### 10.1 循環依存（Circular Dependency）

#### 問題

```dart
// ❌ 循環依存
final providerA = Provider<A>((ref) {
  final b = ref.watch(providerB);  // B に依存
  return A(b: b);
});

final providerB = Provider<B>((ref) {
  final a = ref.watch(providerA);  // A に依存（循環！）
  return B(a: a);
});
```

#### 対策

```dart
// ✅ インターフェースを導入して循環を解く
abstract class IB {
  void doSomething();
}

class B implements IB {
  final IA _a;
  B({required IA a}) : _a = a;
  
  void doSomething() { /* 実装 */ }
}

final providerB = Provider<IB>((ref) {
  final a = ref.watch(providerA);
  return B(a: a);
});
```

### 10.2 Provider の過度なキャッシング

#### 問題

```dart
// ❌ 常にキャッシュされるため、ログアウト後も古いトークンが使われる可能性
final httpClientProvider = Provider<http.Client>((ref) {
  return AuthHttpClient(
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken,
  );
});

// ログアウト
logout(); // authSessionProvider が null になる

// しかし httpClientProvider はまだ古い AuthHttpClient を持っている
```

#### 対策

```dart
// ✅ authSessionProvider の変更を監視
final httpClientProvider = Provider<http.Client>((ref) {
  // authSessionProvider が変わるたびに再生成
  final session = ref.watch(authSessionProvider);
  
  final client = AuthHttpClient(
    tokenProvider: () => session?.accessToken,
  );
  
  ref.onDispose(client.close);
  return client;
});
```

### 10.3 Provider 内での await の多用

#### 問題

```dart
// ❌ Provider 内で await すると、すべてのアクセスが async になる
final heavyDataProvider = Provider<HeavyData>((ref) async {
  // 初期化に時間がかかる
  final data = await loadHeavyData();
  return data;
});

// 使用時：
final data = ref.read(heavyDataProvider);  // ❌ 型エラー
final dataAsync = ref.watch(heavyDataProvider);  // FutureProvider になる
```

#### 対策

```dart
// ✅ FutureProvider を使う
final heavyDataProvider = FutureProvider<HeavyData>((ref) async {
  return await loadHeavyData();
});

// 使用時：
final dataAsync = ref.watch(heavyDataProvider);
dataAsync.when(
  data: (data) => Text(data.toString()),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error'),
);
```

### 10.4 family を使った パラメータ化された Provider

```dart
// プロバイダーに引数を渡したい場合
final userProvider = FutureProvider.family<User, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return await repository.getUser(userId);
});

// 使用例：
final user1 = ref.watch(userProvider('user1'));
final user2 = ref.watch(userProvider('user2'));
// → 異なる userId ごとに異なるプロバイダーインスタンスが生成される
```

---

## 11. DI アーキテクチャのベストプラクティス

### 11.1 依存性の方向

```
┌────────────────────────────────────────┐
│ 依存性は下層へのみ向くべき              │
└────────────────────────────────────────┘

上層（UI Layer）
    ↓ 依存 OK
中層（UseCase Layer）
    ↓ 依存 OK
下層（Repository/DataSource Layer）
    ↓ 依存 OK
底層（Network/Database Layer）

❌ 逆依存（下層が上層に依存）は避ける
```

### 11.2 インターフェース駆動設計

```dart
// ✅ Repository はインターフェースに依存
abstract class UserRepository {
  Future<User> getUser(String userId);
  Future<void> updateUser(User user);
}

// 実装 1
class UserRepositoryImpl implements UserRepository {
  final http.Client _client;
  UserRepositoryImpl({required http.Client client}) : _client = client;
  
  @override
  Future<User> getUser(String userId) async {
    // API 実装
  }
}

// 実装 2（テスト用）
class MockUserRepository implements UserRepository {
  @override
  Future<User> getUser(String userId) async {
    return User(id: 'test', name: 'Test User');
  }
}

// UseCase は インターフェース経由でのみアクセス
class GetUserUseCase {
  final UserRepository _repository;  // インターフェースに依存
  GetUserUseCase({required UserRepository repository})
      : _repository = repository;
}
```

### 11.3 プロバイダーの責務分離

```dart
// ✅ プロバイダーの責務を明確に分ける

// [1] 設定値プロバイダー
final apiBaseUrlProvider = Provider<String>((ref) {
  return 'https://api.example.com';
});

// [2] 低レベルのインフラプロバイダー
final httpClientProvider = Provider<http.Client>((ref) {
  final baseUrl = ref.watch(apiBaseUrlProvider);
  return AuthHttpClient(
    baseUrl: baseUrl,
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken,
  );
});

// [3] データ取得プロバイダー
final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  final client = ref.watch(httpClientProvider);
  return RemoteDataSourceImpl(client);
});

// [4] ビジネスロジックプロバイダー
final repositoryProvider = Provider<Repository>((ref) {
  final dataSource = ref.watch(remoteDataSourceProvider);
  return RepositoryImpl(dataSource);
});

// [5] ユースケースプロバイダー
final useCaseProvider = Provider<UseCase>((ref) {
  final repository = ref.watch(repositoryProvider);
  return UseCase(repository);
});
```

---

## 12. まとめ：DI の本質

### 12.1 DI が解く問題

```
┌──────────────────────────────────────────┐
│ DI がなければ発生する問題                │
├──────────────────────────────────────────┤
│                                          │
│ ❌ 密結合                                │
│    ↓ クラスが直接 new で依存性を作成    │
│    ↓ 他のクラスの変更に敏感              │
│                                          │
│ ❌ テスト困難                            │
│    ↓ 実装の詳細に依存                   │
│    ↓ 本物の API 呼び出しが必須          │
│    ↓ テストが遅く不安定                 │
│                                          │
│ ❌ 実装交換困難                          │
│    ↓ 実装が固定されている               │
│    ↓ 別の実装に変更するのに多大な労力   │
│                                          │
│ ❌ リソース管理困難                      │
│    ↓ いつリソースを破棄するか不明確     │
│    ↓ メモリリークの可能性               │
│                                          │
└──────────────────────────────────────────┘
```

### 12.2 DI がもたらす利点

```
┌──────────────────────────────────────────┐
│ DI がもたらす効果                        │
├──────────────────────────────────────────┤
│                                          │
│ ✅ 疎結合                                │
│    ↓ クラスはインターフェースに依存     │
│    ↓ 実装が変わっても影響を受けない     │
│                                          │
│ ✅ テスト容易                            │
│    ↓ モック実装を注入可能               │
│    ↓ 高速・安定・信頼度の高いテスト     │
│                                          │
│ ✅ 実装交換簡単                          │
│    ↓ インターフェース実装を差し替え     │
│    ↓ 他の部分への影響なし               │
│                                          │
│ ✅ リソース管理自動化                    │
│    ↓ ref.onDispose() で自動破棄         │
│    ↓ メモリリーク防止                   │
│                                          │
│ ✅ コードの再利用性向上                  │
│    ↓ 同じコンポーネントを複数箇所で利用│
│    ↓ 異なるコンテキストに対応           │
│                                          │
└──────────────────────────────────────────┘
```

### 12.3 GroupChatApp での実装の流れ（再掲）

```
UI (AddMemberPage)
  ↓ ref.read(usecase)
DI Framework (Riverpod)
  ├─ usecase を取得するため repository を取得
  │  └─ repository を取得するため dataSource を取得
  │     └─ dataSource を取得するため httpClient を取得
  │        └─ httpClient を取得するため authSession を取得
  │           └─ authSession から最新トークンを取得
  │
  └─ すべての依存性が組み立てられる
       ↓
UseCase + Repository + DataSource + HttpClient が連携
       ↓
バックエンド API と通信
       ↓
レスポンスを UI に返す
       ↓
画面が更新される
```

### 12.4 DI がないアプリケーション

```
❌ 各クラスが new で依存性を直接作成
   └─ 密結合
   └─ テスト困難
   └─ 実装交換困難
   └─ リソース管理が曖昧
```

### 12.5 DI があるアプリケーション（GroupChatApp）

```
✅ 依存性を外部から注入
   └─ 疎結合
   └─ テスト容易
   └─ 実装交換簡単
   └─ リソース管理を自動化
```

---

## 参考資料

- [Riverpod 公式ドキュメント](https://riverpod.dev/)
- [Flutter の依存性注入パターン](https://codewithandrea.com/articles/flutter-state-management-riverpod/)
- [Clean Architecture in Flutter](https://resocoder.com/flutter-clean-architecture)

---

## 復習チェックリスト

このドキュメントを読み終わった後、以下の質問に答えられますか？

### 基本概念
- [ ] DI とは何か、簡潔に説明できる
- [ ] DI の 4 つの主要な利点を列挙できる
- [ ] 従来のコード（DI なし）の問題点を3つ以上挙げられる

### Riverpod の実装
- [ ] Provider とは何か説明できる
- [ ] ref.watch() と ref.read() の違いを説明できる
- [ ] ref.onDispose() の役割を説明できる

### このプロジェクト固有
- [ ] AuthHttpClient が何をしているか説明できる
- [ ] newChatHttpClientProvider → newChatRemoteDataSourceProvider → newChatRepositoryProvider の依存関係を説明できる
- [ ] AddMemberPage から API レスポンスが返ってくるまでのフロー全体を説明できる

### テストと応用
- [ ] モック実装を使ったテストの利点を説明できる
- [ ] Provider をオーバーライドしてテストする方法を説明できる
- [ ] 循環依存の問題と対策を説明できる

---

## 最後に

DI は、単なるテクニックではなく、**ソフトウェア設計の思想**です。

このプロジェクトで Riverpod を使った DI を採用することで：

1. **現在**：コードの保守性・テスト容易性が大幅に向上
2. **将来**：仕様変更や実装交換が容易になる
3. **団体**：チームメンバー全員がコード構造を理解しやすい

となります。

このドキュメントを参照しながら、DI の本質を何度も思い出し、
実装するたびに「なぜこの設計にしているのか」を自問してください。

その繰り返しが、真の理解に繋がります。
