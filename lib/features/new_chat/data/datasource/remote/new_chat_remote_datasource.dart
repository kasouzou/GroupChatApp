/// NewChatタブのリモート契約。
abstract class NewChatRemoteDataSource {
  Future<String> createGroup({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  });
}
