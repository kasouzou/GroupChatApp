import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource.dart';


class ProfileRemoteDatasourceImpl implements ProfileRemoteDataSource {

  @override
  Future<UserModel> fetchUser(String userId) async {
    // 実際はHTTP通信を書く
    return UserModel(
      id: userId,
      displayName: 'RemoteUser',
      photoUrl: 'https://example.com/photo.png',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateProfile(UserModel user) async {
    // HTTP PUTを書く
  }

  @override
  Future<String> uploadImage(String filePath) async {
    // multipart uploadを書く
    return 'https://example.com/new.png';
  }
}
