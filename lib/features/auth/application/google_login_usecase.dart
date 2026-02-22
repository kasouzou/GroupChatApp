import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/auth/domain/auth_repository.dart';

/// ログイン画面から呼ばれるユースケース。
class GoogleLoginUseCase {
  final AuthRepository _repository;

  GoogleLoginUseCase(this._repository);

  Future<UserModel?> signIn() {
    return _repository.signInWithGoogle();
  }

  Future<void> signOut() {
    return _repository.signOut();
  }
}
