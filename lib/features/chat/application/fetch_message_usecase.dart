import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';

class FetchMessagesUseCase {
  final ChatRepository repository;

  FetchMessagesUseCase(this.repository);

  Stream<List<ChatMessageModel>> watchMessages(String groupId) {
    return repository.watchMessages(groupId);
  }
}