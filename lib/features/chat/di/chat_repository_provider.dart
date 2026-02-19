import 'package:group_chat_app/features/chat/di/chat_local_datasource_provider.dart';
import 'package:group_chat_app/features/chat/data/repository/chat_repository_impl.dart';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository_provider.g.dart';

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  final local = ref.watch(chatLocalDataSourceProvider);
  return ChatRepositoryImpl(local: local);
}
