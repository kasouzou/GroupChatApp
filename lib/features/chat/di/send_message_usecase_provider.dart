import 'package:group_chat_app/features/chat/application/send_message_usecase.dart';
import 'package:group_chat_app/features/chat/di/chat_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_message_usecase_provider.g.dart';

@riverpod
SendMessageUseCase sendMessageUseCase(SendMessageUseCaseRef ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return SendMessageUseCase(
    repository: repository,
    sender: 'mock-user',
  );
}
