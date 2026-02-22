import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart';
import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource_impl.dart';
import 'package:group_chat_app/features/new_chat/data/new_chat_repository_impl.dart';
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';
import 'package:http/http.dart' as http;

/// NewChat用HTTPクライアント。
/// Provider破棄時にcloseしてソケットリークを防ぐ。
final newChatHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// NewChat用リモートデータソース。
/// API仕様変更時はこの層の実装を差し替える。
final newChatRemoteDataSourceProvider = Provider<NewChatRemoteDataSource>((
  ref,
) {
  final client = ref.watch(newChatHttpClientProvider);
  return NewChatRemoteDataSourceImpl(client);
});

/// NewChat用Repository。
/// UseCaseはこの抽象経由で利用し、通信実装を意識しない。
final newChatRepositoryProvider = Provider<NewChatRepository>((ref) {
  final remote = ref.watch(newChatRemoteDataSourceProvider);
  return NewChatRepositoryImpl(remote: remote);
});
