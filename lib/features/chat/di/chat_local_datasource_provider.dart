import 'package:group_chat_app/features/chat/data/datasource/local/chat_dao.dart';
import 'package:group_chat_app/features/chat/data/datasource/local/chat_local_datasource_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_local_datasource_provider.g.dart';

@riverpod
ChatLocalDataSourceImpl chatLocalDataSource(ChatLocalDataSourceRef ref) {
  final daoAsync = ref.watch(chatDaoProvider);
  final dao = daoAsync.maybeWhen(
    data: (dao) => dao,
    orElse: () => throw StateError('ChatDao not initialized'),
  );

  final impl = ChatLocalDataSourceImpl(dao);
  ref.onDispose(impl.dispose);
  return impl;
}
