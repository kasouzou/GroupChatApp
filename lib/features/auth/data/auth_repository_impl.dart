import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:group_chat_app/features/auth/domain/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepositoryImpl implements AuthRepository {
  final GoogleSignIn _googleSignIn;
  final AuthRemoteDataSource _remote;
  Future<void>? _initializeFuture;

  AuthRepositoryImpl({
    required GoogleSignIn googleSignIn,
    required AuthRemoteDataSource remote,
  }) : _googleSignIn = googleSignIn,
       _remote = remote;

  @override
  Future<UserModel?> signInWithGoogle() async {
    await _initialize();
    final account = await _googleSignIn.authenticate();

    // Googleで取得したプロフィールをバックエンドへ連携し、サーバー側の正を返す。
    final user = await _remote.loginWithGoogleToken(
      id: account.id,
      displayName: account.displayName ?? 'NoName',
      photoUrl: account.photoUrl ?? '',
    );
    return user;
  }

  @override
  Future<void> signOut() async {
    await _initialize();
    await _googleSignIn.signOut();
  }

  Future<void> _initialize() {
    _initializeFuture ??= _googleSignIn.initialize();
    return _initializeFuture!;
  }
}
