import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_payloads.dart';

/// Chat のリモート通信契約。
/// 実装はHTTP/GraphQL/gRPCのどれでもよいが、Repositoryはこの抽象だけを見る。
///
/// 設計意図:
/// - Domain層・UseCase層が通信手段に依存しないようにする
/// - API仕様変更時の影響を DataSource 実装側に閉じ込める
/// - テスト時は Fake 実装に差し替え可能にする
abstract class ChatRemoteDataSource {
  /// ユーザーの所属グループ一覧を取得。
  /// 想定API: GET /api/v1/users/{user_id}/groups
  Future<List<Map<String, dynamic>>> fetchMyChats(String userId);

  /// 指定グループのメッセージ一覧を取得。
  /// 想定API: GET /api/v1/groups/{group_id}/messages
  Future<List<Map<String, dynamic>>> fetchMessages(String groupId);

  /// メッセージ送信。
  /// 想定API: POST /api/v1/messages
  /// 返却される server_id / server_sent_at_ms はサーバー確定値として扱う。
  Future<RemoteSendMessageResult> sendMessage(RemoteSendMessageRequest request);
}
