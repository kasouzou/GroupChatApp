import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/send_message_response.dart';

abstract class ChatRepository {

  // 指定したグループのメッセージをリアルタイムに監視する「流れ」を取得
  Stream<List<ChatMessageModel>> watchMessages(String groupId);
  
  // メッセージを送信する系のメソッド
  Future<void> saveMessage(ChatMessageModel message);

  Future<SendMessageResponse> sendMessage(ChatMessageModel message);
}
