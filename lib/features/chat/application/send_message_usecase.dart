import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:uuid/uuid.dart';

class SendMessageUseCase {
  final ChatRepository repository;
  final String sender;

  SendMessageUseCase({
    required this.repository,
    required this.sender,
  });

  /// ①〜⑥ のフロー（UI通知は不要。repository.saveがStreamを発火してUIが更新される）
  Future<void> execute(String groupId, String senderId, String role, MessageContent content) async {

    final uuid = Uuid().v4();
    final localId = uuid;

    // ①　ローカル保存
    var message = ChatMessageModel.createPending(
      localId: localId, 
      groupId: groupId, 
      senderId: senderId, 
      role: role,  
      content: content, 
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    // ②　UIはrepository.watchMessages(groupId)を購読しているのでこの時点で即表示される
    await repository.saveMessage(message); 

    try {
      // ③　リモートへ送信
      final response = await repository.sendMessage(message); 

      // ④ 【ここがポイント！】サーバー確定値で状態を更新
      // 内部で copyWith が動いて、新しいインスタンスが返ってくる
      message = message.markAsSent(
        serverId: response.serverId, 
        serverSentAtMs: response.serverSentAtMs,
      );

      // ⑤ ローカルDBを最新（サーバータイム版）に更新
      await repository.saveMessage(message);

    } catch (_) {
      // ⑥ 失敗時の処理
      message = message.markAsFailed(
        nextRetryAtMs: DateTime.now().millisecondsSinceEpoch + 5000,
      );
    }
  }

}
