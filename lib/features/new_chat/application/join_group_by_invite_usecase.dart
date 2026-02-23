// グループ参加結果のエンティティを利用するためのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/join_group_result.dart';
// リポジトリの抽象インターフェースを利用するためのインポート
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

// 招待コードを使ってグループに参加するユースケースクラス
/// 招待コード参加ユースケース。
class JoinGroupByInviteUseCase {
  // ユースケースで使うリポジトリの参照
  final NewChatRepository repository;

  // コンストラクタでリポジトリを受け取る
  JoinGroupByInviteUseCase(this.repository);

  // ユースケース呼び出し。招待コードとユーザーIDを受け取り参加処理を行う
  Future<JoinGroupResult> call({
    // 使用する招待コード
    required String inviteCode,
    // 参加するユーザーのID
    required String userId,
  }) {
    // リポジトリの参加処理を呼び出す
    return repository.joinByInviteCode(inviteCode: inviteCode, userId: userId);
  }
}
