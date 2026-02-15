import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/datasource/local/profile_local_datasource.dart';
import '../data/datasource/local/profile_local_datasource_impl.dart';

part 'profile_local_datasource_provider.g.dart';

@riverpod
ProfileLocalDataSource profileLocalDataSource(ProfileLocalDataSourceRef ref) {
  return ProfileLocalDatasourceImpl();
  // もし dispose が必要なら ref.onDispose(() => impl.dispose());
}