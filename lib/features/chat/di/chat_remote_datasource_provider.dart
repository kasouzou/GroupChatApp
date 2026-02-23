import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/core/network/auth_http_client.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:http/http.dart' as http;

import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_datasource.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_datasource_impl.dart';

// HTTPクライアントのDI。
// 画面やRepositoryは直接 http.Client を new しないようにして、差し替えやテストを容易にする。
final chatHttpClientProvider = Provider<http.Client>((ref) {
  final rawClient = http.Client();
  final client = AuthHttpClient(
    inner: rawClient,
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken,
  );
  ref.onDispose(client.close);
  return client;
});

// Chat の RemoteDataSource をDIで提供。
// Repositoryはこの抽象に依存する。
final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  final client = ref.watch(chatHttpClientProvider);
  return ChatRemoteDataSourceImpl(client);
});
