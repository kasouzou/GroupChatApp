import 'package:group_chat_app/features/chat/di/chat_local_datasource_provider.dart';
import 'package:group_chat_app/features/chat/di/chat_remote_datasource_provider.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/chat/data/repository/chat_repository_impl.dart';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_repository_provider.g.dart';

@riverpod
ChatRepository chatRepository(ChatRepositoryRef ref) {
  // local: オフライン時のキャッシュ・即時表示用
  final local = ref.watch(chatLocalDataSourceProvider);
  // remote: FastAPIエンドポイントとの通信
  final remote = ref.watch(chatRemoteDataSourceProvider);
  final authSession = ref.watch(authSessionProvider);
  // 現在ユーザーID。将来は認証基盤(JWT等)から供給する想定。
  const currentUserId = String.fromEnvironment(
    'CHAT_USER_ID',
    defaultValue: 'user-001',
  );

  // Domain層には ChatRepository 抽象だけを公開し、実装詳細を隠蔽する。
  return ChatRepositoryImpl(
    local: local,
    remote: remote,
    currentUserId: authSession?.id ?? currentUserId,
  );
}
