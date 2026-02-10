// メッセージのデータを扱うための簡単なクラス（疎結合を意識！）

class ChatMessageModel {
  final String id;        // UUID
  final String groupId;   // どの家族か
  final String senderId;  // 送信者のGoogle UID
  final String role; // 役割: "leader" または "member"
  final String text;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  // --- 便利機能（ヘルパーメソッド） ---

  // 💡 ツッコミ！: 権限チェックを文字列比較で何度も書くのは非効率。
  // こうやって getter を作っておけば、将来役割が増えてもここを直すだけで済む（疎結合！）
  bool get isLeader => role == 'leader';
  bool get isMember => role == 'member';

  // バックエンド（JSON）から変換する「工場」
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      role: json['role'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
