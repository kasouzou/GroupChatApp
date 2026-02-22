/// NewChatタブのリモート契約。
abstract class NewChatRemoteDataSource {
  Future<String> createGroup({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  });

  Future<Map<String, dynamic>> createInvite({
    required String groupId,
    required String requesterUserId,
    int expiresInMinutes = 5,
  });

  Future<Map<String, dynamic>> joinByInviteCode({
    required String inviteCode,
    required String userId,
  });
}
