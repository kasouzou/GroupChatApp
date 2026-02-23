// 招待情報のエンティティを使うためのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
// リポジトリの抽象インターフェースを使うためのインポート
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

// 招待コードを発行するユースケースクラス
/// 招待コード発行ユースケース。
class CreateGroupInviteUseCase {
  // ユースケースが利用するリポジトリの参照
  final NewChatRepository repository;

  // コンストラクタでリポジトリを受け取る
  CreateGroupInviteUseCase(this.repository);

  // ユースケースの呼び出しメソッド。指定グループの招待コードを作る
  Future<GroupInviteInfo> call({
    // 招待を作成する対象のグループID
    required String groupId,
    // 招待発行をリクエストしたユーザーのID
    required String requesterUserId,
    // 招待コード有効期限（分）、デフォルトは5分
    int expiresInMinutes = 5,
  }) {
    // リポジトリに処理を委譲して招待情報を取得する
    return repository.createInvite(
      groupId: groupId,
      requesterUserId: requesterUserId,
      expiresInMinutes: expiresInMinutes,
    );
  }
}
