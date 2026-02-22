import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

class CreateChatUsecase {
  final NewChatRepository repository;

  CreateChatUsecase(this.repository);

  Future<String> call({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  }) {
    return repository.createChat(
      name: name,
      creatorUserId: creatorUserId,
      memberUserIds: memberUserIds,
    );
  }
}
