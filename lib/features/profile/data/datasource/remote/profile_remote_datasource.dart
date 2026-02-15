import 'package:group_chat_app/core/models/user_model.dart';

abstract class ProfileRemoteDataSource {
  Future<UserModel> fetchUser(String userId);
  Future<UserModel> updateProfile(UserModel user);
  Future<String> uploadImage(String filePath);
}
