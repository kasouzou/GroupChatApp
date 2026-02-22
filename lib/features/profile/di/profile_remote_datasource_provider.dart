import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasource/remote/profile_remote_datasource.dart';

part 'profile_remote_datasource_provider.g.dart';

@riverpod
ProfileRemoteDataSource profileRemoteDataSource(
  ProfileRemoteDataSourceRef ref,
) {
  // ref.onDispose(() => impl.dispose());
  return ProfileRemoteDatasourceImpl();
}
