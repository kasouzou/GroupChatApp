import 'dart:async';

import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/domain/profile_repository.dart';

class ProfileUseCase {

  final ProfileRepository repository;

  ProfileUseCase(this.repository);

  Future<UserModel> loadUser(String userId) async {
    // ここのFetchUser()はローカルを読みに行く
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

    // ③ プロフィール更新。
    // ※プロフィール更新の流れはローカル保存成功ならVPS保存→VPS保存成功ならローカルの更新日時をサーバータイムに更新して終了と言う流れだがここではそれを抽象化してざっくりプロフィール更新としている。
    await repository.updateProfile(updatedUser);

    return updatedUser;
  }
}
