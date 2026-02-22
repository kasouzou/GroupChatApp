import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:group_chat_app/features/auth/data/auth_repository_impl.dart';
import 'package:group_chat_app/features/auth/di/auth_remote_datasource_provider.dart';
import 'package:group_chat_app/features/auth/domain/auth_repository.dart';

/// GoogleSignIn SDKの注入ポイント。
final googleSignInProvider = Provider<GoogleSignIn>((_) {
  // v7系は singleton を使う。
  return GoogleSignIn.instance;
});

/// AuthRepository をDIで構成する。
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final googleSignIn = ref.watch(googleSignInProvider);
  final remote = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(googleSignIn: googleSignIn, remote: remote);
});
