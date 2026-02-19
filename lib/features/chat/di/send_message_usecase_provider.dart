import 'package:group_chat_app/features/chat/application/send_message_usecase.dart';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_message_usecase_provider.g.dart';

@riverpod
SendMessageUseCase sendMessageUseCase (SendMessageUseCaseRef ref){
  final repository = ref.watch(ChatRepositoryProvider);
  return ChatRepeository(repository);
}