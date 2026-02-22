import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/new_chat/application/create_group_invite_usecase.dart';
import 'package:group_chat_app/features/new_chat/di/new_chat_repository_provider.dart';

/// 招待コード発行UseCaseのDI。
final createGroupInviteUseCaseProvider = Provider<CreateGroupInviteUseCase>((
  ref,
) {
  final repository = ref.watch(newChatRepositoryProvider);
  return CreateGroupInviteUseCase(repository);
});
