/// 招待コードによる参加結果。
class JoinGroupResult {
  final String groupId;
  final String groupName;
  final bool joined;

  const JoinGroupResult({
    required this.groupId,
    required this.groupName,
    required this.joined,
  });
}
