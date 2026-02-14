import 'dart:async';

import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/data/datasource/local/profile_dao.dart';
import 'package:group_chat_app/features/profile/data/datasource/local/profile_local_datasource.dart';

// sqlite/profile_local_datasource_impl.dart
class ProfileLocalDatasourceImpl implements ProfileLocalDataSource {
  late final ProfileDao _dao; // 💡 DBを直接持たず、DAOを介す
  final _controller = StreamController<UserModel>.broadcast();

  @override
  Future<void> updateProfile(UserModel user) async {
    await _dao.updateUser(user);
    _controller.add(user); // ここで購読者に通知
  }
  
  @override
  Stream<UserModel> watchProfile(String userId) {
    // 初回値を流す
    _dao.getUser(userId).then((u) { if (u!=null) _controller.add(u); });
    return _controller.stream;
  }

  @override
  Future<UserModel?> getProfile(String userId) => _dao.getUser(userId);

  void dispose() => _controller.close();
}