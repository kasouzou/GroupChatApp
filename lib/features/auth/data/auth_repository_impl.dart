import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/auth/domain/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<UserModel?> signInWithGoogle() async {
    return null;
  }

  @override
  Future<void> signOut() async {}
}
