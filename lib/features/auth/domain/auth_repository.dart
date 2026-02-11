import 'package:group_chat_app/core/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
}
