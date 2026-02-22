import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
import 'package:group_chat_app/features/new_chat/domain/entities/join_group_result.dart';

abstract class NewChatRepository {
  /// 新規チャットグループを作成し、作成された groupId を返す。
  Future<String> createChat({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  });

  /// 指定グループの招待コードを発行する。
  Future<GroupInviteInfo> createInvite({
    required String groupId,
    required String requesterUserId,
    int expiresInMinutes = 5,
  });

  /// 招待コードでグループへ参加する。
  Future<JoinGroupResult> joinByInviteCode({
    required String inviteCode,
    required String userId,
  });
}
