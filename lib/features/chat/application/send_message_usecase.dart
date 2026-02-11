import 'package:group_chat_app/features/chat/domain/chat_repository.dart';

class SendMessageUsecase {
  final ChatRepository repository;

  SendMessageUsecase(this.repository);

  Future<void> call(String groupId, String senderId, String text) {
    return repository.sendMessage(groupId, senderId, text);
  }
}
