import 'dart:convert';

import 'package:group_chat_app/core/network/api_config.dart';
import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart';
import 'package:http/http.dart' as http;

/// FastAPI の /api/v1/groups を呼び出す実装。
class NewChatRemoteDataSourceImpl implements NewChatRemoteDataSource {
  final http.Client _client;

  NewChatRemoteDataSourceImpl(this._client);

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

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Create group failed: status=${response.statusCode} body=${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['group_id'] as String?) ?? '';
  }

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
      throw Exception(
        'Create invite failed: status=${response.statusCode} body=${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

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
      throw Exception(
        'Join by invite failed: status=${response.statusCode} body=${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
