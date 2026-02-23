import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:group_chat_app/features/auth/domain/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// AuthRepository の実装。
///
/// フロー:
/// 1. Google SDKで認証（端末側）
/// 2. 認証結果をバックエンドへ送信（/auth/google-login）
/// 3. バックエンド確定の UserModel を返却
///
/// なぜバックエンド連携するか:
/// - 端末ごとの差異を吸収したユーザー正規化
/// - 将来の認可/JWT発行/監査ログ導入に備える
class AuthRepositoryImpl implements AuthRepository {
  final GoogleSignIn _googleSignIn;
  final AuthRemoteDataSource _remote;
  Future<void>? _initializeFuture;
  String? _lastAccessToken;

  AuthRepositoryImpl({
    required GoogleSignIn googleSignIn,
    required AuthRemoteDataSource remote,
  }) : _googleSignIn = googleSignIn,
       _remote = remote;

  @override
  Future<UserModel?> signInWithGoogle() async {
    await _initialize();
    // v7系では authenticate() が対話ログインの入口。
    final account = await _googleSignIn.authenticate();

    // Googleで取得したプロフィールをバックエンドへ連携し、サーバー側の正を返す。
    final user = await _remote.loginWithGoogleToken(
      id: account.id,
      displayName: account.displayName ?? 'NoName',
      photoUrl: account.photoUrl ?? '',
    );
    _lastAccessToken = user.accessToken;
    return user;
  }

  @override
  Future<void> signOut() async {
    await _initialize();
    final token = _lastAccessToken;
    if (token != null && token.isNotEmpty) {
      try {
        await _remote.logout(accessToken: token);
      } catch (_) {
        // ログアウトAPI失敗時も端末側ログアウトは継続する。
      }
    }
    // Googleセッション破棄。アプリ側セッションStateはUI層でクリアする。
    await _googleSignIn.signOut();
    _lastAccessToken = null;
  }

  Future<void> _initialize() {
    _initializeFuture ??= _googleSignIn.initialize();
    return _initializeFuture!;
  }
}
