import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_payloads.dart';

abstract class ChatRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchMyChats(String userId);
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId);
  Future<RemoteSendMessageResult> sendMessage(RemoteSendMessageRequest request);
}
