import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_group_summary.dart';
import 'package:group_chat_app/features/chat/domain/entities/send_message_response.dart';

/// チャット機能のドメイン境界。
/// UI/Application はこの契約だけに依存し、実装詳細を隠蔽する。
abstract class ChatRepository {
  // チャット画面で指定したグループのメッセージをリアルタイムに監視する「流れ」を取得。
  Stream<List<ChatMessageModel>> watchMessages(String groupId);

  // チャット一覧（groupId/groupName/最終メッセージなど）を監視する
  Stream<List<ChatGroupSummary>> watchMyChats();

  // メッセージを送信する系のメソッド
  Future<void> saveMessage(ChatMessageModel message);

  Future<SendMessageResponse> sendMessage(ChatMessageModel message);
}
