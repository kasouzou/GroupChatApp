import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/data/datasource/remote/auth_remote_datasource.dart';
import 'package:group_chat_app/features/auth/data/datasource/remote/auth_remote_datasource_impl.dart';
import 'package:http/http.dart' as http;

/// Auth系専用のHTTPクライアント。
final authHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Auth系リモートデータソース。
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final client = ref.watch(authHttpClientProvider);
  return AuthRemoteDataSourceImpl(client);
});
