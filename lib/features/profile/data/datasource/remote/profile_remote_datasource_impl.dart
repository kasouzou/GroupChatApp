import 'dart:convert';

import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/core/network/api_config.dart';
import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource.dart';
import 'package:http/http.dart' as http;

/// Profileタブ専用のリモート通信実装。
///
/// エンドポイント対応:
/// - GET  /api/v1/users/{user_id}
/// - PUT  /api/v1/users/{user_id}
/// - POST /api/v1/uploads/profile-image
class ProfileRemoteDatasourceImpl implements ProfileRemoteDataSource {
  final http.Client _client;

  ProfileRemoteDatasourceImpl([http.Client? client])
    : _client = client ?? http.Client();

  @override
  Future<UserModel> fetchUser(String userId) async {
    // プロフィール表示の初期データ取得。
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/$userId');
    final response = await _client.get(uri);
    _ensureSuccess(response, endpoint: uri.toString());
    return UserModel.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    // 編集後プロフィールをサーバーへ保存し、確定値を受け取る。
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/${user.id}');
    final response = await _client.put(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'display_name': user.displayName,
        'photo_url': user.photoUrl,
      }),
    );
    _ensureSuccess(response, endpoint: uri.toString());
    return UserModel.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<String> uploadImage(String filePath) async {
    // 現状はサーバーでURL発行のみ（実ファイルアップロードは将来拡張）。
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/uploads/profile-image');
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'file_path': filePath}),
    );
    _ensureSuccess(response, endpoint: uri.toString());
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['image_url'] as String?) ?? '';
  }

  void _ensureSuccess(http.Response response, {required String endpoint}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw Exception(
      'Profile API failed: status=${response.statusCode} endpoint=$endpoint body=${response.body}',
    );
  }
}
