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
  // 未ログイン時は空文字を設定し、API側401/403に委ねる。
  // ここで例外を投げると画面遷移中にProvider例外が露出しやすいため。
  final currentUserId = authSession?.id ?? '';

  // Domain層には ChatRepository 抽象だけを公開し、実装詳細を隠蔽する。
  return ChatRepositoryImpl(
    local: local,
    remote: remote,
    currentUserId: currentUserId,
  );
}
