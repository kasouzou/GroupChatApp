import 'package:group_chat_app/features/new_chat/domain/entities/join_group_result.dart';
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

/// 招待コード参加ユースケース。
class JoinGroupByInviteUseCase {
  final NewChatRepository repository;

  JoinGroupByInviteUseCase(this.repository);

  Future<JoinGroupResult> call({
    required String inviteCode,
    required String userId,
  }) {
    return repository.joinByInviteCode(inviteCode: inviteCode, userId: userId);
  }
}
