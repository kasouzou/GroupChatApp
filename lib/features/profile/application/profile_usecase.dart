import 'dart:async';

import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/domain/profile_repository.dart';

class ProfileUseCase {

  final ProfileRepository repository;

  ProfileUseCase(this.repository);

  Future<UserModel> loadUser(String userId) async {
    final user = await repository.fetchUser(userId);
    return user;
  }

  Future<UserModel> saveProfile({
    required UserModel originalUser,
    required String editingName,
    required String editingPhotoPath,
  }) async {

    String finalPhotoUrl = originalUser.photoUrl;

    // ① ローカルパスならアップロード
    if (!editingPhotoPath.startsWith("http")) {
      finalPhotoUrl = await repository.uploadImage(editingPhotoPath);
    }

    // ② 新しいUserを生成
    final updatedUser = originalUser.copyWith(
      displayName: editingName,
      photoUrl: finalPhotoUrl,
    );

    // ③ ローカルDB保存
    await repository.updateProfile(updatedUser);

    // ④ VPS送信（本来は別メソッドに分離しても良い）
    await repository.updateProfile(updatedUser);

    return updatedUser;
  }
}
