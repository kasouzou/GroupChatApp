// リポジトリの抽象インターフェースを利用するためのインポート
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

// チャット作成ユースケースクラスの定義
class CreateChatUsecase {
  // ユースケースが操作を依頼するリポジトリ
  final NewChatRepository repository;

  // コンストラクタでリポジトリを受け取る
  CreateChatUsecase(this.repository);

  // ユースケース呼び出し。グループ名や初期メンバーを受け取りグループを作成する
  Future<String> call({
    // 作成するグループの名前
    required String name,
    // グループ作成者のユーザーID
    required String creatorUserId,
    // 初期参加ユーザーのIDリスト
    required List<String> memberUserIds,
  }) {
    // リポジトリに作成処理を委譲し、生成されたグループIDを返す
    return repository.createChat(
      name: name,
      creatorUserId: creatorUserId,
      memberUserIds: memberUserIds,
    );
  }
}
