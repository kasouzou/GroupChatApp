import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/chat/application/fetch_my_chats_usecase.dart';
import 'package:group_chat_app/features/chat/di/chat_repository_provider.dart';

/// 一覧ユースケースのDI定義。
/// Presentation層はこのProvider経由でUseCaseを取得する。
final fetchMyChatsUseCaseProvider = Provider<FetchMyChatsUseCase>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return FetchMyChatsUseCase(repository);
});
