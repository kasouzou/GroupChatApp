// NewChat機能で利用するリモートデータソースのインターフェース定義
/// NewChatタブのリモート契約。
abstract class NewChatRemoteDataSource {
  // グループ作成APIを呼び出し、作成されたgroupIdを返す
  Future<String> createGroup({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  });

  // 招待コード発行APIを呼び出し、レスポンスをJSONマップで返す
  Future<Map<String, dynamic>> createInvite({
    required String groupId,
    required String requesterUserId,
    int expiresInMinutes = 5,
  });

  // 招待コードでの参加APIを呼び出し、レスポンスをJSONマップで返す
  Future<Map<String, dynamic>> joinByInviteCode({
    required String inviteCode,
    required String userId,
  });
}
