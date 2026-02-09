// プロフィール画面の編集の成功をUIに反映するために、ストリームを監視して状態を更新するProfileNotifierの実装です。

import 'package:group_chat_app/pages/user_pages/profile_tab/model/profile_ui_model.dart';
import 'package:group_chat_app/pages/user_pages/profile_tab/service/profile_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_notifier.g.dart';

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  
  @override
  ProfileUiModel build() {
    // 💡 1. サービスの取得
    final service = ref.watch(profileServiceProvider);

    // 💡 2. 監視を開始
    // build()が走るたびに古いsubscriptionは破棄されるよう、下でref.onDisposeを呼ぶ
    _listenToUserChanges(service);

    // 💡 3. 初期状態
    // ProfileServiceから現在のユーザー情報の最新値を同期的に取れるならそれを使うのがベター
    // この最新値を、Streamで受け取るさらに新しい情報で更新し、UIに反映していくのがこのファイルの内容
    return ProfileUiModel.initial(service.currentUser);
  }

  void _listenToUserChanges(ProfileService profileService) {
    final subscription = profileService.userStream.listen((latestUser) {
      // 💡 ツッコミ！: 
      // ストリームからデータが流れてきたら、現在の状態(state)をコピーして更新
      state = state.copyWith(
        user: latestUser,
        isEditing: false, 
        isSaving: false,
        errorMessage: null,
      );
    }, onError: (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: error.toString(),
      );
    });

    // 💡 4. この notifier が破棄される時に「必ず」ストリームを閉じる
    // build()の中で呼ばれるので、依存先が変わるたびにお掃除してくれるよ
    ref.onDispose(() => subscription.cancel());
  }

  // --- startEditing と saveProfile はそのままで完璧！ ---
  void startEditing() {
    state = state.copyWith(
      isEditing: true,
      editingName: state.user.displayName,
      editingPhotoUrl: state.user.photoUrl,
    );
  }

  Future<void> saveProfile(String newName) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    final updatedUser = state.user.copyWith(displayName: newName);

    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateProfile(updatedUser);
      // 成功後の処理（isEditing = falseなど）は Stream がやってくれる！
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: '保存に失敗しました');
    }
  }
}