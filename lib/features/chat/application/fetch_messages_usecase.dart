import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';

class FetchMessagesUsecase {
  final ChatRepository repository;

  FetchMessagesUsecase(this.repository);

  Stream<List<ChatMessageModel>> call(String groupId) {
    return repository.watchMessages(groupId);
  }
}
