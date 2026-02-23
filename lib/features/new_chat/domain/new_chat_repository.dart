// グループ招待情報のエンティティを利用するためのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
// グループ参加結果のエンティティを利用するためのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/join_group_result.dart';

// 新規チャット関連の永続化やAPI呼び出しを抽象化するリポジトリの定義
abstract class NewChatRepository {
  // 新しいチャットグループを作成し、作成されたグループIDを返すメソッドの宣言
  /// 新規チャットグループを作成し、作成された groupId を返す。
  Future<String> createChat({
    // 作成するグループの名前
    required String name,
    // グループ作成をリクエストしたユーザーのID
    required String creatorUserId,
    // グループに最初から参加させるユーザーIDのリスト
    required List<String> memberUserIds,
  });

  // 指定したグループに対する招待コードを発行するメソッドの宣言
  /// 指定グループの招待コードを発行する。
  Future<GroupInviteInfo> createInvite({
    // 招待を作成する対象のグループID
    required String groupId,
    // 招待発行をリクエストしたユーザーのID
    required String requesterUserId,
    // 招待コードの有効期限（分）。デフォルトは5分
    int expiresInMinutes = 5,
  });

  // 招待コードを使ってユーザーがグループに参加するメソッドの宣言
  /// 招待コードでグループへ参加する。
  Future<JoinGroupResult> joinByInviteCode({
    // 参加に使用する招待コード
    required String inviteCode,
    // 参加するユーザーのID
    required String userId,
  });
}
