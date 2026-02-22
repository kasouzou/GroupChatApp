import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_payloads.dart';

/// Chat のリモート通信契約。
/// 実装はHTTP/GraphQL/gRPCのどれでもよいが、Repositoryはこの抽象だけを見る。
abstract class ChatRemoteDataSource {
  /// ユーザーの所属グループ一覧を取得。
  Future<List<Map<String, dynamic>>> fetchMyChats(String userId);

  /// 指定グループのメッセージ一覧を取得。
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId);

  /// メッセージ送信。
  Future<RemoteSendMessageResult> sendMessage(RemoteSendMessageRequest request);
}
