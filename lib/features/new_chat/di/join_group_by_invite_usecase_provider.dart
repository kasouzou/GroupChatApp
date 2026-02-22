import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/new_chat/application/join_group_by_invite_usecase.dart';
import 'package:group_chat_app/features/new_chat/di/new_chat_repository_provider.dart';

/// 招待コード参加UseCaseのDI。
final joinGroupByInviteUseCaseProvider = Provider<JoinGroupByInviteUseCase>((
  ref,
) {
  final repository = ref.watch(newChatRepositoryProvider);
  return JoinGroupByInviteUseCase(repository);
});
