import 'package:group_chat_app/core/models/user_model.dart';

/// 認証系のリモート通信契約。
abstract class AuthRemoteDataSource {
  Future<UserModel> loginWithGoogleToken({
    required String id,
    required String displayName,
    required String photoUrl,
  });
}
