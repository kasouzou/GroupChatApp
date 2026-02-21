import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_group_summary.dart';

/// チャット一覧取得のユースケース。
/// 一覧取得ロジックをUIから分離し、テスト容易性を高める。
class FetchMyChatsUseCase {
  final ChatRepository repository;

  FetchMyChatsUseCase(this.repository);

  Stream<List<ChatGroupSummary>> watchMyChats() {
    return repository.watchMyChats();
  }
}
