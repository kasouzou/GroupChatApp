import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

class CreateChatUsecase {
  final NewChatRepository repository;

  CreateChatUsecase(this.repository);

  Future<void> call(String name) {
    return repository.createChat(name);
  }
}
