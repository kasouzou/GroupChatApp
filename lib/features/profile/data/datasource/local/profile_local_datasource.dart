// Repositoryの抽象化とは別。これは「保存技術の抽象化」
import 'package:group_chat_app/core/models/user_model.dart';

abstract class ProfileLocalDataSource {
  Future<void> updateProfile(UserModel user);
  Stream<UserModel> watchProfile(String userId);
  Future<UserModel?> getProfile(String userId);
}
