/// 招待コード発行結果。
class GroupInviteInfo {
  final String groupId;
  final String inviteCode;
  final String inviteUrl;
  final DateTime expiresAt;

  const GroupInviteInfo({
    required this.groupId,
    required this.inviteCode,
    required this.inviteUrl,
    required this.expiresAt,
  });
}
