import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:group_chat_app/core/network/api_config.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_datasource.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_payloads.dart';

/// FastAPIエンドポイントと通信する実装。
/// ここでは「HTTPプロトコルの詳細」だけを扱い、業務ロジックはRepository側に寄せる。
///
/// 実装方針:
/// 1. URI組み立てとHTTPメソッド選択
/// 2. ステータスコード判定（2xx以外は例外）
/// 3. JSONのdecode
/// 4. 生JSONを Repository 側のMapperへ引き渡す
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final http.Client _client;

  ChatRemoteDataSourceImpl(this._client);

  @override
  Future<List<Map<String, dynamic>>> fetchMyChats(String userId) async {
    // 例: GET /api/v1/users/user-001/groups
    // 一覧画面のサマリー（group名・最終メッセージ等）に利用される。
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/$userId/groups');
    final response = await _client.get(uri);

    _ensureSuccess(response, endpoint: uri.toString());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final groups = (body['groups'] as List<dynamic>? ?? const <dynamic>[]);
    return groups.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId) async {
    // 例: GET /api/v1/groups/family_group_001/messages
    // チャット画面の本文描画に使うメッセージ配列を取得する。
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
    // 例: POST /api/v1/messages
    // 送信本文は request.toJson() で MessageContent をAPI仕様へ変換済み。
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
    // 2xx 以外は例外化して上位層へ通知。
    // ここで例外を投げることで、Notifier側のエラー表示やリトライ制御に繋げられる。
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'Remote request failed: ${response.statusCode} endpoint=$endpoint body=${response.body}',
    );
  }
}
