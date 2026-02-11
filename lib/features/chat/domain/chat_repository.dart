

import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';

abstract class ChatRepository {
  // 指定したグループのメッセージをリアルタイムに監視する「流れ」を取得
  Stream<List<ChatMessageModel>> watchMessages(String groupId);
  
  void dispose(); // リソース解放用メソッド

  // メッセージを送信する
  Future<void> sendMessage(String groupId, String senderId, String text);
}
