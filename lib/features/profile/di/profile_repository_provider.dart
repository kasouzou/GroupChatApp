import 'package:group_chat_app/features/profile/di/profile_local_datasource_provider.dart';
import 'package:group_chat_app/features/profile/di/profile_remote_datasource_provider.dart';
import 'package:group_chat_app/features/profile/data/repository/profile_repository_impl.dart';
import 'package:group_chat_app/features/profile/domain/profile_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_repository_provider.g.dart';

@riverpod
ProfileRepository profileRepository(ProfileRepositoryRef ref) {
  final local = ref.watch(profileLocalDataSourceProvider);
  final remote = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(local: local, remote: remote);
}
