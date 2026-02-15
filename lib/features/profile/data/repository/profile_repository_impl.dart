import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/data/datasource/local/profile_local_datasource.dart';
import 'package:group_chat_app/features/profile/data/datasource/remote/profile_remote_datasource.dart';
import 'package:group_chat_app/features/profile/domain/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {

  final ProfileLocalDataSource local;
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl({
    required this.local,
    required this.remote,
  });

  @override
  Future<UserModel> fetchUser(String userId) async {
    // このFetchUserはSSOT原則により、ローカルDBを取得する。リモートには取りに行かない。ローカルDBを最新に保つのは別のクラス。
    final user = await local.getProfile(userId);
    if (user == null) throw Exception('User not found');

    return user;
  }

  // いわゆる保存メソッドのこと.広く更新である。　
  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final serverConfirmedUser = await remote.updateProfile(user); // VPS送信
    await local.updateProfile(serverConfirmedUser); // サーバー確定値をSQLite保存
    return serverConfirmedUser;
  }

  @override
  Future<String> uploadImage(String filePath) async {
    // ここでVPSにURLをとりに行ったりする。
    await Future.delayed(const Duration(seconds: 2));
    return 'https://picsum.photos/200';
  }
}
