// ここがVPSのエンドポイントになる。
import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource.dart';

// コメントアウト含め、将来的なXserver の REST API エンドポイントを使った実装例だよ
class ProfileRemoteDatasourceImpl implements ProfileRemoteDataSource {

  static const String baseUrl = 'https://your-xserver-domain.com/api';
  // final http.Client httpClient;
  // ProfileRemoteDatasourceImpl(this.httpClient);

  @override
  Future<UserModel> fetchUser(String userId) async {

    // 実際はこんな感じでHTTP通信を書く
    // final response = await httpClient.get(
    //   Uri.parse('$baseUrl/users/$userId'),
    // );
    // if (response.statusCode == 200) {
    //   return UserModel.fromJson(jsonDecode(response.body));
    // }
    // throw Exception('Failed to fetch user');
    
    return UserModel(
      id: userId,
      displayName: 'RemoteUser',
      photoUrl: 'https://example.com/photo.png',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    // HTTP PUTを書く
    // final response = await httpClient.put(
    //   Uri.parse('$baseUrl/users/${user.id}'),
    //   headers: {'Content-Type': 'application/json'},
    //   body: jsonEncode(user.toJson()),
    // );
    // if (response.statusCode != 200) {
    //   throw Exception('Failed to update profile');
    // }
    // サーバーから返ってきた更新時刻（確定値）を使う想定。
    final serverUpdatedAt = DateTime.now().toUtc();
    return user.copyWith(updatedAt: serverUpdatedAt);
  }

  @override
  Future<String> uploadImage(String filePath) async {
    // final file = File(filePath);
    // final request = http.MultipartRequest(
    //   'POST',
    //   Uri.parse('$baseUrl/uploads/profile-image'),
    // );
    // request.files.add(await http.MultipartFile.fromPath('file', filePath));
    
    // final response = await request.send();
    // if (response.statusCode == 201) {
    //   final responseBody = await response.stream.bytesToString();
    //   return jsonDecode(responseBody)['imageUrl'];
    // }
    // throw Exception('Failed to upload image');

    // multipart uploadを書く
    return 'https://example.com/new.png';
  }
}
