

import 'package:group_chat_app/pages/user_pages/my_chats_tab/model/chat_message_model.dart';

abstract class ChatAbstract {
  // 指定したグループのメッセージをリアルタイムに監視する「流れ」を取得
  Stream<List<ChatMessageModel>> watchMessages(String groupId);
  
  void dispose(); // リソース解放用メソッド

  // メッセージを送信する
  Future<void> sendMessage(String groupId, String senderId, String text);
}