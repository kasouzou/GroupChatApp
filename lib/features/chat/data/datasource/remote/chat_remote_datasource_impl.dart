import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:group_chat_app/core/network/api_config.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_datasource.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_payloads.dart';

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client _client;

  ChatRemoteDataSourceImpl(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchMyChats(String userId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/$userId/groups');
    final response = await _client.get(uri);

    _ensureSuccess(response, endpoint: uri.toString());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final groups = (body['groups'] as List<dynamic>? ?? const <dynamic>[]);
    return groups.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/groups/$groupId/messages',
    );
    final response = await _client.get(uri);

    _ensureSuccess(response, endpoint: uri.toString());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final messages = (body['messages'] as List<dynamic>? ?? const <dynamic>[]);
    return messages.cast<Map<String, dynamic>>();
  }

  @override
  Future<RemoteSendMessageResult> sendMessage(
    RemoteSendMessageRequest request,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/messages');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    _ensureSuccess(response, endpoint: uri.toString());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return RemoteSendMessageResult.fromJson(body);
  }

  void _ensureSuccess(http.Response response, {required String endpoint}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'Remote request failed: ${response.statusCode} endpoint=$endpoint body=${response.body}',
    );
  }
}
