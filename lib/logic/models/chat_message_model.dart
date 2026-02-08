// メッセージのデータを扱うための簡単なクラス（疎結合を意識！）

class ChatMessageModel {
  final String id;        // UUID
  final String groupId;   // どの家族か
  final String senderId;  // 送信者のGoogle UID
  final String text;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  // バックエンド（JSON）から変換する「工場」
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
