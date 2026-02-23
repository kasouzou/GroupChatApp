// リモートデータソースのインターフェースを利用するためのインポート
import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart';
// 招待情報エンティティのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
// 参加結果エンティティのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/join_group_result.dart';
// リポジトリ抽象のインポート
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

// NewChatRepository の具体実装。
// 画面（ユースケース）からの入力を RemoteDataSource に委譲し、
// 必要に応じてエンティティにマッピングして返却する層。
/// NewChatRepository 実装。
/// 画面から受け取った入力を RemoteDataSource へ委譲し、
/// グループ作成結果(groupId)を返す。
class NewChatRepositoryImpl implements NewChatRepository {
  // 外部から注入されるリモートデータソース
  final NewChatRemoteDataSource remote;

  // コンストラクタ（remote を必須で注入）
  NewChatRepositoryImpl({required this.remote});

  // グループ作成処理をリモートに委譲
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

  // 招待発行処理をリモートに委譲し、受け取ったJSONを `GroupInviteInfo` に変換して返す
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

  // 招待コード参加処理をリモートに委譲し、JSONを `JoinGroupResult` に変換して返す
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
