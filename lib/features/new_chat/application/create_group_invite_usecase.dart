import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

/// 招待コード発行ユースケース。
class CreateGroupInviteUseCase {
  final NewChatRepository repository;

  CreateGroupInviteUseCase(this.repository);

  Future<GroupInviteInfo> call({
    required String groupId,
    required String requesterUserId,
    int expiresInMinutes = 5,
  }) {
    return repository.createInvite(
      groupId: groupId,
      requesterUserId: requesterUserId,
      expiresInMinutes: expiresInMinutes,
    );
  }
}
