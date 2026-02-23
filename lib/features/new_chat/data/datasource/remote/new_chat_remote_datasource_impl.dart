// JSONのエンコード/デコードを扱うための標準ライブラリ
import 'dart:convert';

// APIのベースURLや設定を参照するためのインポート
import 'package:group_chat_app/core/network/api_config.dart';
// エラーをアプリ例外に変換するヘルパー
import 'package:group_chat_app/core/network/api_error_parser.dart';
// リモートデータソースの契約を実装するためのインポート
import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart';
// HTTPクライアントライブラリ
import 'package:http/http.dart' as http;

// FastAPI の /api/v1/groups 等を叩く具体実装
/// FastAPI の /api/v1/groups を呼び出す実装。
class NewChatRemoteDataSourceImpl implements NewChatRemoteDataSource {
  // HTTPクライアントのインスタンス（外部注入）
  final http.Client _client;

  // コンストラクタでクライアントを受け取る
  NewChatRemoteDataSourceImpl(this._client);

  // グループ作成APIを呼び出す実装
  @override
  Future<String> createGroup({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/groups');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'creator_user_id': creatorUserId,
        'member_user_ids': memberUserIds,
      }),
    );

    // ステータスコードが2xxでない場合は例外を投げる
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw toAppException(response, endpoint: uri.toString());
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['group_id'] as String?) ?? '';
  }

  // 招待コード発行APIを呼ぶ実装
  @override
  Future<Map<String, dynamic>> createInvite({
    required String groupId,
    required String requesterUserId,
    int expiresInMinutes = 5,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/group-invites');
    final response = await _client.post(
      uri,
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

  // 招待コードで参加するAPIを呼ぶ実装
  @override
  Future<Map<String, dynamic>> joinByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/group-invites/join');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'invite_code': inviteCode, 'user_id': userId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw toAppException(response, endpoint: uri.toString());
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
