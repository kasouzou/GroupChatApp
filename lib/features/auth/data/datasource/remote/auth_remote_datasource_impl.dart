import 'dart:convert';

import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/core/network/api_config.dart';
import 'package:group_chat_app/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:http/http.dart' as http;

/// FastAPI の /api/v1/auth/google-login と通信する実装。
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client _client;

  AuthRemoteDataSourceImpl(this._client);

  @override
  Future<UserModel> loginWithGoogleToken({
    required String id,
    required String displayName,
    required String photoUrl,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/google-login');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'display_name': displayName,
        'photo_url': photoUrl,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Auth API failed: status=${response.statusCode} body=${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel.fromMap(body);
  }
}
