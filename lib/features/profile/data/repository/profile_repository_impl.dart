import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/data/datasource/local/profile_local_datasource.dart';
import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource.dart';
import 'package:group_chat_app/features/profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileLocalDataSource local;
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl({required this.local, required this.remote});

  @override
  Future<UserModel> fetchUser(String userId) async {
    // 本番運用では、まずRemoteを正として取得しローカルを更新する。
    try {
      final remoteUser = await remote.fetchUser(userId);
      await local.updateProfile(remoteUser);
      return remoteUser;
    } catch (_) {
      // オフライン時はローカルキャッシュにフォールバック。
      final cached = await local.getProfile(userId);
      if (cached == null) rethrow;
      return cached;
    }
  }

  // いわゆる保存メソッドのこと.広く更新である。
  @override
  Future<UserModel> updateProfile(UserModel user) async {
    // 1) サーバー更新
    final serverConfirmedUser = await remote.updateProfile(user);
    // 2) サーバー確定値でローカルキャッシュ更新
    await local.updateProfile(serverConfirmedUser);
    return serverConfirmedUser;
  }

  @override
  Future<String> uploadImage(String filePath) async {
    // 画像のアップロードURL取得はRemoteに委譲。
    return remote.uploadImage(filePath);
  }
}
