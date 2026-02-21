/// チャット一覧表示専用の読み取りモデル。
/// Message本体とは分離し、UIが必要な情報だけを持つ。
class ChatGroupSummary {
  final String groupId;
  final String groupName;
  final String lastMessagePreview;
  final int lastMessageAt;
  final int unreadCount;
  final int memberCount;

  const ChatGroupSummary({
    required this.groupId,
    required this.groupName,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.memberCount = 1,
  });
}
