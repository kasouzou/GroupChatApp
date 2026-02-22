import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/application/google_login_usecase.dart';
import 'package:group_chat_app/features/auth/di/auth_repository_provider.dart';

/// GoogleログインUseCaseのDI。
final googleLoginUseCaseProvider = Provider<GoogleLoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GoogleLoginUseCase(repository);
});
