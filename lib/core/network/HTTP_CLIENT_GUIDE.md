# Http.Client の機能説明

`http.Client` は Dart 標準の HTTP クライアントライブラリ(`package:http`)が提供する基本的なHTTP通信クラスです。

このドキュメントは、GroupChatApp プロジェクトで使用される `http.Client` の具体的な機能と使用方法を説明します。

---

## 1. Http.Client の基本概念

### 提供元
```dart
import 'package:http/http.dart' as http;
```

Dart の公式 HTTP ライブラリが提供する HTTP クライアント。

### 役割
HTTP リクエストを送信し、レスポンスを受信するための基盤となるクラスです。

---

## 2. 主な機能一覧

### Http.Client が提供するメソッド

| メソッド | 説明 | 戻り値 |
|---------|------|--------|
| `post()` | POST リクエストを送信 | `Future<Response>` |
| `get()` | GET リクエストを送信 | `Future<Response>` |
| `put()` | PUT リクエストを送信 | `Future<Response>` |
| `delete()` | DELETE リクエストを送信 | `Future<Response>` |
| `patch()` | PATCH リクエストを送信 | `Future<Response>` |
| `head()` | HEAD リクエストを送信 | `Future<Response>` |
| `send()` | カスタムリクエストを送信 | `Future<StreamedResponse>` |
| `close()` | クライアントをクローズ、リソース解放 | `void` |

---

## 3. GroupChatApp での具体的な使用例

### 3.1. グループ作成 API呼び出し

```dart
@override
Future<String> createGroup({
  required String name,
  required String creatorUserId,
  required List<String> memberUserIds,
}) async {
  // 1. URI を構築
  final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/groups');
  
  // 2. HTTP POST リクエストを送信
  //    ↓ ここで http.Client の post() メソッドを使用
  final response = await _client.post(
    uri,
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': name,
      'creator_user_id': creatorUserId,
      'member_user_ids': memberUserIds,
    }),
  );

  // 3. レスポンスのステータスコードをチェック
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw toAppException(response, endpoint: uri.toString());
  }

  // 4. JSON レスポンスをパース
  final body = jsonDecode(response.body) as Map<String, dynamic>;
  return (body['group_id'] as String?) ?? '';
}
```

#### フロー図

```
リクエスト送信フロー:
┌──────────────────────────────────┐
│ _client.post(uri, ...) を呼び出す │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ Http.Client が HTTP POST を実行   │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ バックエンド (FastAPI) で処理     │
│ POST /api/v1/groups              │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ レスポンスを Future で返す         │
│ { "group_id": "grp_abc123..." }  │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ await で待機                       │
│ Response オブジェクトを受け取る    │
└────────────┬─────────────────────┘
             │
             ▼
┌──────────────────────────────────┐
│ statusCode、body を検証           │
│ エラーなら例外を投げる             │
│ 成功なら群_id を抽出して返す      │
└──────────────────────────────────┘
```

### 3.2. 招待コード発行 API呼び出し

```dart
@override
Future<Map<String, dynamic>> createInvite({
  required String groupId,
  required String requesterUserId,
  int expiresInMinutes = 5,
}) async {
  // POST リクエスト実行
  final response = await _client.post(
    Uri.parse('${ApiConfig.baseUrl}/api/v1/group-invites'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'group_id': groupId,
      'requester_user_id': requesterUserId,
      'expires_in_minutes': expiresInMinutes,
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw toAppException(response, endpoint: uri.toString());
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

**レスポンス例:**
```json
{
  "group_id": "grp_abc123",
  "invite_code": "INV-ABCDEF1234",
  "invite_url": "https://example.com/invite/INV-ABCDEF1234",
  "expires_at": "2026-02-23T15:30:00"
}
```

### 3.3. 招待コードで参加 API呼び出し

```dart
@override
Future<Map<String, dynamic>> joinByInviteCode({
  required String inviteCode,
  required String userId,
}) async {
  final response = await _client.post(
    Uri.parse('${ApiConfig.baseUrl}/api/v1/group-invites/join'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'invite_code': inviteCode,
      'user_id': userId,
    }),
  );

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw toAppException(response, endpoint: uri.toString());
  }

  return jsonDecode(response.body) as Map<String, dynamic>;
}
```

---

## 4. Http.Client の内部構造

### Http.Client は抽象クラス

```dart
abstract class Client extends BaseClient {
  // 実装はプラットフォーム固有のコードで提供される
}
```

### 実装の対象

- **Android / iOS**: ネイティブのHTTPライブラリに委譲
- **Web**: ブラウザの `XMLHttpRequest` / `fetch` API に委譲
- **Desktop / Server**: `dart:io` の `HttpClient` に委譲

---

## 5. Response クラスの構成

Http.Client が返す Response オブジェクトの構造：

```dart
class Response {
  // レスポンスボディ（文字列）
  final String body;
  
  // HTTPステータスコード（200, 404, 500 など）
  final int statusCode;
  
  // レスポンスヘッダー（Map）
  final Map<String, String> headers;
  
  // リクエストURL
  final Uri request;
}
```

### 実使用例

```dart
final response = await _client.post(uri, ...);

// statusCode でレスポンス判定
if (response.statusCode == 200) {
  print('成功');
} else if (response.statusCode == 404) {
  print('見つからない');
} else if (response.statusCode == 500) {
  print('サーバーエラー');
}

// body を JSON パース
final json = jsonDecode(response.body);

// headers を参照
final contentType = response.headers['content-type'];
```

---

## 6. AuthHttpClient による拡張

GroupChatApp では、基本的な `http.Client` を `AuthHttpClient` で拡張しています。

### AuthHttpClient の役割

```dart
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final FutureOr<String?> Function() _tokenProvider;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 1. アクセストークンを取得
    final token = await _tokenProvider();
    
    // 2. Authorization ヘッダーを自動付与
    if (token != null && token.trim().isNotEmpty) {
      request.headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    
    // 3. Accept ヘッダーを自動付与
    request.headers.putIfAbsent('Accept', () => 'application/json');
    
    // 4. 内部クライアントにリクエストを委譲
    return _inner.send(request);
  }
}
```

#### フロー図

```
リクエスト実行:
┌────────────────────────────────┐
│ AuthHttpClient.post() を呼び出し│
└────────────┬───────────────────┘
             │
             ▼
┌────────────────────────────────┐
│ send() メソッドが自動実行される  │
└────────────┬───────────────────┘
             │
             ├─ Authorization ヘッダー自動追加
             │  Bearer <token>
             │
             ├─ Accept ヘッダー自動追加
             │  application/json
             │
             └─ 内部の http.Client に委譲
                      │
                      ▼
                ┌──────────────────┐
                │ 実際のHTTPリクエスト
                │ を送信する
                └──────────────────┘
```

### メリット

- **トークン管理の自動化**: すべてのリクエストに自動で認可トークンを付与
- **ヘッダーの統一**: 毎回ヘッダーを指定する手間を削減
- **実装の分離**: 認証ロジックとAPI呼び出しロジックを分離

---

## 7. リソース管理（close メソッド）

### Http.Client のクローズ

```dart
@override
void close() {
  _inner.close();
  super.close();
}
```

HTTP接続を閉じてソケットリークを防ぎます。

### Riverpod での自動管理

```dart
final newChatHttpClientProvider = Provider<http.Client>((ref) {
  final rawClient = http.Client();
  final client = AuthHttpClient(
    inner: rawClient,
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken,
  );
  
  // Provider 破棄時に自動的に close() を呼び出し
  ref.onDispose(client.close);
  
  return client;
});
```

**重要:** `ref.onDispose()` により、Provider が破棄されるときに `client.close()` が自動実行され、メモリリークを防ぎます。

---

## 8. 実装の階層構造

GroupChatApp の HTTP 通信レイヤー：

```
┌─────────────────────────────┐
│ UI Layer (AddMemberPage)    │
│ - ユーザーインタラクション  │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ UseCase Layer               │
│ - ビジネスロジック          │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ Repository Layer            │
│ - データソース抽象化        │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ DataSource Layer            │
│ - API呼び出し実装           │
│ (NewChatRemoteDataSourceImpl)│
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ AuthHttpClient              │
│ - 認証ヘッダー自動付与      │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ Http.Client                 │
│ - 実際のHTTP通信実行        │
└────────────┬────────────────┘
             │
             ▼
┌─────────────────────────────┐
│ Platform SDK (iOS/Android)  │
│ - ネイティブHTTP実装        │
└─────────────────────────────┘
```

---

## 9. エラーハンドリング

### ステータスコードのチェック

```dart
if (response.statusCode < 200 || response.statusCode >= 300) {
  // 2xx 以外のレスポンスはエラー
  throw toAppException(response, endpoint: uri.toString());
}
```

### Http.Client が投げるエラー

| エラータイプ | 説明 |
|-----------|------|
| `SocketException` | ネットワーク接続エラー |
| `TimeoutException` | 通信タイムアウト |
| `http.ClientException` | HTTP関連のエラー |

### 例外ハンドリング例

```dart
try {
  final response = await _client.post(uri, ...);
  if (response.statusCode >= 400) {
    throw toAppException(response, endpoint: uri.toString());
  }
} on SocketException {
  print('ネットワーク接続エラー');
} on TimeoutException {
  print('通信タイムアウト');
} catch (e) {
  print('予期しないエラー: $e');
}
```

---

## 10. Http.Client の主な特徴

| 特性 | 説明 |
|------|------|
| **非同期** | すべてのメソッドが Future を返す |
| **プラットフォーム対応** | iOS/Android/Web/Desktop で動作 |
| **軽量** | Dart 標準ライブラリのみで実装 |
| **安全** | HTTPS をデフォルトでサポート |
| **リソース管理が必要** | close() でソケットをクローズする必要がある |

---

## 11. 実装の流れ（具体例）

### シナリオ：グループ作成

```
1. UI (AddMemberPage)
   └─ "グループを作成" ボタンをタップ
        │
        ▼
2. UseCase (CreateGroupUseCase)
   └─ createGroup(name, userId, memberIds) を呼び出し
        │
        ▼
3. Repository (NewChatRepositoryImpl)
   └─ remoteDataSource.createGroup(...) を呼び出し
        │
        ▼
4. RemoteDataSource (NewChatRemoteDataSourceImpl)
   └─ _client.post() を呼び出す
        │
        ▼
5. AuthHttpClient
   └─ Authorization ヘッダーを自動付与
   └─ 内部の http.Client に委譲
        │
        ▼
6. Http.Client
   └─ POST /api/v1/groups へ HTTP リクエスト送信
        │
        ▼
7. Backend (FastAPI)
   └─ グループを作成してレスポンス返却
   └─ {
        "group_id": "grp_abc123",
        "group_name": "MyGroup"
      }
        │
        ▼
8. Http.Client
   └─ Response オブジェクトで受信
        │
        ▼
9. RemoteDataSource
   └─ statusCode チェック
   └─ JSON パース
   └─ group_id を抽出
        │
        ▼
10. Repository
    └─ データを返却
        │
        ▼
11. UseCase
    └─ 結果を返却
        │
        ▼
12. UI
    └─ 画面を更新
```

---

## まとめ

| 要素 | 役割 |
|------|------|
| **Http.Client** | Dartの標準HTTP通信ライブラリ。POST/GET/PUT/DELETE等のメソッドを提供 |
| **Response** | HTTPレスポンス情報を保持（statusCode, body, headers等） |
| **AuthHttpClient** | Http.Clientを拡張し、認証トークンを自動付与 |
| **NewChatRemoteDataSourceImpl** | AuthHttpClientを利用して具体的なAPI呼び出しを実装 |
| **close()** | リソース解放。Riverpod の `ref.onDispose()` で自動実行 |

Http.Client は、GroupChatApp の各レイヤー（UI → UseCase → Repository → RemoteDataSource）を貫く**HTTP通信の要（かなめ）**として機能しています。
