import 'package:group_chat_app/core/models/user_model.dart';

abstract class ProfileRepository {
  // ユーザー情報を取得する(外部取得の概念)
  Future<UserModel> fetchUser(String userId);

  /// プロフィールを更新する（外部保存の概念）
  Future<void> updateProfile(UserModel user);

  /// 画像ファイルをアップロードする。（外部保存の概念）
  Future<String> uploadImage(String filePath);
}
