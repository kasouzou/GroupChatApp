import 'package:http/http.dart' as http;
import 'package:group_chat_app/core/network/auth_http_client.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasource/remote/profile_remote_datasource.dart';

part 'profile_remote_datasource_provider.g.dart';

@riverpod
ProfileRemoteDataSource profileRemoteDataSource(
  ProfileRemoteDataSourceRef ref,
) {
  final rawClient = http.Client();
  final authClient = AuthHttpClient(
    inner: rawClient,
    tokenProvider: () => ref.read(authSessionProvider)?.accessToken,
  );
  ref.onDispose(authClient.close);
  return ProfileRemoteDatasourceImpl(authClient);
}
