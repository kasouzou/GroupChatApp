// メッセージのデータを扱うための簡単なクラス（疎結合を意識！）
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_status.dart';

class ChatMessageModel {
  final String localId; // UUID
  final String groupId; // どの家族か
  final String senderId; // 送信者のGoogle UID
  final String? serverId;
  final String role; // 役割: "leader" または "member"
  final MessageStatus status;
  final MessageContent content;
  final int createdAt;
  final int retryCount;
  final int? nextRetryAtMs;

  ChatMessageModel({
    required this.localId,
    required this.groupId,
    required this.senderId,
    this.serverId,
    required this.role,
    required this.status,
    required this.content,
    required this.createdAt,
    this.retryCount = 0,
    this.nextRetryAtMs,
  });

  // --- 便利機能（ヘルパーメソッド） ---

  // 💡 ツッコミ！: 権限チェックを文字列比較で何度も書くのは非効率。
  // こうやって getter を作っておけば、将来役割が増えてもここを直すだけで済む（疎結合！）
  bool get isLeader => role == 'leader';
  bool get isMember => role == 'member';

  factory ChatMessageModel.createPending({
    required String localId,
    required String groupId,
    required String senderId,
    required String role,
    required MessageContent content,
    required int createdAt,
  }) {
    return ChatMessageModel(
      localId: localId,
      groupId: groupId,
      senderId: senderId,
      role: role,
      content: content,
      createdAt: createdAt,
      status: MessageStatus.sending,
    );
  }

  ChatMessageModel copyWith({
    String? localId,
    String? groupId,
    String? senderId,
    String? serverId,
    String? role,
    MessageStatus? status,
    MessageContent? content,
    int? createdAt,
    int? retryCount,
    int? nextRetryAtMs,
  }) {
    return ChatMessageModel(
      localId: localId ?? this.localId,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      serverId: serverId ?? this.serverId,
      role: role ?? this.role,
      status: status ?? this.status,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAtMs: nextRetryAtMs ?? this.nextRetryAtMs,
    );
  }

  // 💡 markAsSent は copyWith を使って「差分」だけを伝える
  ChatMessageModel markAsSent({
    required String serverId,
    required int serverSentAtMs, //サーバー時刻
  }) {
    if (status == MessageStatus.sent) throw StateError('already sent');

    return copyWith(
      status: MessageStatus.sent,
      serverId: serverId,
      createdAt: serverSentAtMs, // 💡 ここでサーバータイムに上書き（SSOT!）
    );
  }

  ChatMessageModel markAsFailed({required int nextRetryAtMs}) {
    return copyWith(
      status: MessageStatus.failed,
      retryCount: retryCount + 1,
      nextRetryAtMs: nextRetryAtMs,
    );
  }

  // バックエンド（JSON）から変換する「工場」
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      localId: json['id'],
      groupId: json['group_id'],
      senderId: json['sender_id'],
      role: json['role'],
      content: json['content'],
      createdAt: json['created_at'],
      status: json['status'],
    );
  }
}
