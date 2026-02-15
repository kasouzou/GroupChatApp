import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasource/local/profile_local_datasource.dart';
import '../data/datasource/local/profile_local_datasource_impl.dart';
import '../data/datasource/local/profile_dao.dart';  // 追加

part 'profile_local_datasource_provider.g.dart';

@riverpod
ProfileLocalDataSource profileLocalDataSource(ProfileLocalDataSourceRef ref) {
  final daoAsync = ref.watch(profileDaoProvider);
  final dao = daoAsync.maybeWhen(
    data: (dao) => dao,
    orElse: () => throw StateError('ProfileDao not initialized'),
  );
  final impl = ProfileLocalDatasourceImpl(dao);
  ref.onDispose(() => impl.dispose());
  return impl;
}