abstract class NewChatRepository {
  /// 新規チャットグループを作成し、作成された groupId を返す。
  Future<String> createChat({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  });
}
