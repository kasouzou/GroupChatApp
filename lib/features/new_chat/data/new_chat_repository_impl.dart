import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart';
import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
import 'package:group_chat_app/features/new_chat/domain/entities/join_group_result.dart';
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

/// NewChatRepository 実装。
/// 画面から受け取った入力を RemoteDataSource へ委譲し、
/// グループ作成結果(groupId)を返す。
class NewChatRepositoryImpl implements NewChatRepository {
  final NewChatRemoteDataSource remote;

  NewChatRepositoryImpl({required this.remote});

  @override
  Future<String> createChat({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  }) async {
    return remote.createGroup(
      name: name,
      creatorUserId: creatorUserId,
      memberUserIds: memberUserIds,
    );
  }

  @override
  Future<GroupInviteInfo> createInvite({
    required String groupId,
    required String requesterUserId,
    int expiresInMinutes = 5,
  }) async {
    final json = await remote.createInvite(
      groupId: groupId,
      requesterUserId: requesterUserId,
      expiresInMinutes: expiresInMinutes,
    );
    return GroupInviteInfo(
      groupId: (json['group_id'] as String?) ?? groupId,
      inviteCode: (json['invite_code'] as String?) ?? '',
      inviteUrl: (json['invite_url'] as String?) ?? '',
      expiresAt:
          DateTime.tryParse((json['expires_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  @override
  Future<JoinGroupResult> joinByInviteCode({
    required String inviteCode,
    required String userId,
  }) async {
    final json = await remote.joinByInviteCode(
      inviteCode: inviteCode,
      userId: userId,
    );
    return JoinGroupResult(
      groupId: (json['group_id'] as String?) ?? '',
      groupName: (json['group_name'] as String?) ?? '',
      joined: (json['joined'] as bool?) ?? false,
    );
  }
}
