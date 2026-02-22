import 'package:group_chat_app/features/chat/domain/entities/chat_group_summary.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_status.dart';

/// メッセージ送信時のHTTPリクエストPayload。
/// DomainのMessageContentをAPI受け渡し用JSONへ変換する責務を持つ。
class RemoteSendMessageRequest {
  final String localId;
  final String groupId;
  final String senderId;
  final String role;
  final MessageContent content;
  final int createdAt;

  const RemoteSendMessageRequest({
    required this.localId,
    required this.groupId,
    required this.senderId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'local_id': localId,
      'group_id': groupId,
      'sender_id': senderId,
      'role': role,
      'content': _serializeContent(content),
      'created_at': createdAt,
    };
  }

  Map<String, dynamic> _serializeContent(MessageContent content) {
    return switch (content) {
      TextContent(:final text) => {'type': 'text', 'text': text},
      ImageContent(
        :final fileName,
        :final sizeInBytes,
        :final width,
        :final height,
      ) =>
        {
          'type': 'image',
          'file_name': fileName,
          'size_in_bytes': sizeInBytes,
          'width': width,
          'height': height,
        },
    };
  }
}

class RemoteSendMessageResult {
  final String serverId;
  final int serverSentAtMs;

  const RemoteSendMessageResult({
    required this.serverId,
    required this.serverSentAtMs,
  });

  factory RemoteSendMessageResult.fromJson(Map<String, dynamic> json) {
    return RemoteSendMessageResult(
      serverId: json['server_id'] as String,
      serverSentAtMs: (json['server_sent_at_ms'] as num).toInt(),
    );
  }
}

/// Remote JSON <-> Domain Entity の変換器。
/// 変換ロジックを1箇所に集約して、Repositoryを読みやすく保つ。
class ChatRemoteMapper {
  static ChatGroupSummary toGroupSummary(Map<String, dynamic> json) {
    return ChatGroupSummary(
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String,
      lastMessagePreview: (json['last_message_preview'] as String?) ?? '',
      lastMessageAt: (json['last_message_at_ms'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 1,
    );
  }

  static ChatMessageModel toMessage(Map<String, dynamic> json) {
    final contentJson =
        (json['content'] as Map<String, dynamic>? ?? <String, dynamic>{});
    return ChatMessageModel(
      localId: (json['local_id'] as String?) ?? (json['server_id'] as String),
      groupId: json['group_id'] as String,
      senderId: json['sender_id'] as String,
      serverId: json['server_id'] as String?,
      role: (json['role'] as String?) ?? 'member',
      status: _statusFromString(json['status'] as String?),
      content: _contentFromJson(contentJson),
      createdAt: (json['created_at_ms'] as num?)?.toInt() ?? 0,
    );
  }

  static MessageStatus _statusFromString(String? status) {
    return switch (status) {
      'sending' => MessageStatus.sending,
      'pending_offline' => MessageStatus.pendingOffline,
      'failed' => MessageStatus.failed,
      'sent' => MessageStatus.sent,
      _ => MessageStatus.sent,
    };
  }

  static MessageContent _contentFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'image') {
      return ImageContent(
        fileName: (json['file_name'] as String?) ?? 'unknown',
        sizeInBytes: (json['size_in_bytes'] as num?)?.toInt() ?? 0,
        width: (json['width'] as num?)?.toInt() ?? 0,
        height: (json['height'] as num?)?.toInt() ?? 0,
      );
    }

    return TextContent((json['text'] as String?) ?? '');
  }
}
