import 'dart:async';

import 'package:group_chat_app/features/chat/data/datasource/local/chat_dao.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_status.dart';

class ChatLocalDataSourceImpl {
  final ChatDao _dao;

  ChatLocalDataSourceImpl(this._dao);

  final _controller = StreamController<ChatMessageModel>.broadcast();

  // ローカルにメッセージ保存
  Future<void> saveMessage(ChatMessageModel message) async {
    await _dao.insertMessage(_toRow(message));
    _controller.add(message);
  }

  Stream<ChatMessageModel> watchMessages() {
    return _controller.stream;
  }

  Future<List<ChatMessageModel>> getUnsentMessages() async {
    final rows = await _dao.getUnsentMessages();
    return rows.map(_fromRow).toList();
  }

  Map<String, dynamic> _toRow(ChatMessageModel message) {
    return {
      'id': message.serverId,
      'group_id': message.groupId,
      'sender_id': message.senderId,
      'role': message.role,
      'text': _serializeContent(message.content),
      'created_at': message.createdAt.toString(),
      'sync_status': message.status == MessageStatus.sent ? 1 : 0,
    };
  }

  ChatMessageModel _fromRow(Map<String, dynamic> row) {
    final createdAtRaw = row['created_at']?.toString() ?? '0';
    final createdAt = int.tryParse(createdAtRaw) ?? 0;
    final text = row['text']?.toString() ?? '';
    final syncStatus = (row['sync_status'] as int?) ?? 0;

    return ChatMessageModel(
      localId: (row['local_id']?.toString() ?? ''),
      groupId: (row['group_id']?.toString() ?? ''),
      senderId: (row['sender_id']?.toString() ?? ''),
      serverId: row['id']?.toString(),
      role: (row['role']?.toString() ?? 'member'),
      status: syncStatus == 1 ? MessageStatus.sent : MessageStatus.sending,
      content: _deserializeContent(text),
      createdAt: createdAt,
    );
  }

  String _serializeContent(MessageContent content) {
    return switch (content) {
      TextContent(:final text) => text,
      ImageContent(:final fileName) => 'img:$fileName',
    };
  }

  MessageContent _deserializeContent(String text) {
    if (text.startsWith('img:')) {
      return ImageContent(
        fileName: text.substring(4),
        sizeInBytes: 0,
        width: 0,
        height: 0,
      );
    }

    return TextContent(text);
  }

  void dispose() => _controller.close();
}
