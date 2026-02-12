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
    //本来はここでVPSから取り寄せるコードを書く
    final latestUser = UserModel(
      id: userId,
      displayName: '米木歩',
      photoUrl: 'assets/icon/icon.png',
      createdAt: DateTime.now(),
    );
    return latestUser;
  }

  // いわゆる保存メソッドのこと広く更新である。　
  @override
  Future<void> updateProfile(UserModel user) async {
    await local.updateProfile(user); // SQLite保存
    await remote.updateProfile(user); // VPS送信
  }

  @override
  Future<String> uploadImage(String filePath) async {
    // ここでVPSにURLをとりに行ったりする。
    await Future.delayed(const Duration(seconds: 2));
    return 'https://picsum.photos/200';
  }
}
