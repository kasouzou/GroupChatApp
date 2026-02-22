import 'package:group_chat_app/features/chat/di/chat_local_datasource_provider.dart';
import 'package:group_chat_app/features/chat/di/chat_remote_datasource_provider.dart';
import 'package:group_chat_app/features/chat/data/repository/chat_repository_impl.dart';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository_provider.g.dart';

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  final local = ref.watch(chatLocalDataSourceProvider);
  final remote = ref.watch(chatRemoteDataSourceProvider);
  const currentUserId = String.fromEnvironment(
    'CHAT_USER_ID',
    defaultValue: 'user-001',
  );

  return ChatRepositoryImpl(
    local: local,
    remote: remote,
    currentUserId: currentUserId,
  );
}
