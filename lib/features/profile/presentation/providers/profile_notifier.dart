import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/di/profile_usecase_provider.dart';
import 'package:group_chat_app/features/profile/presentation/models/profile_ui_model.dart';

part 'profile_notifier.g.dart';

@Riverpod(keepAlive: true) // Providerを破棄しない（必要ならautoDisposeを外す）
class ProfileNotifier extends _$ProfileNotifier {
  bool _loaded = false;

  @override
  ProfileUiModel build() {
    // 初期は空ユーザー（loadUser が呼ばれるまでのプレースホルダ）
    return ProfileUiModel.initial(UserModel.empty());
  }

  /// UI から明示的に呼ぶ。ProfilePage の initState で呼ぶ想定
  Future<void> loadUser(String userId) async {
    if (_loaded) return;
    _loaded = true;

    state = state.copyWith(isSaving: true, errorMessage: null);
    final useCase = ref.read(profileUseCaseProvider);

    try {
      // UseCase 側で local/db から取得する実装を想定
      final user = await useCase.loadUser(userId);

      // Presentation が「真実の値」を保持する
      state = state.copyWith(
        user: user,
        editingName: user.displayName,
        editingPhotoUrl: user.photoUrl,
        isSaving: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  /// 編集モード開始（ProfileEditPage が呼ぶ）
  /// state.user が既に存在している前提（loadUser を先に呼ぶ）
  void startEditing() {
    final current = state.user;
    state = state.copyWith(
      isEditing: true,
      editingName: current.displayName,
      editingPhotoUrl: current.photoUrl,
      errorMessage: null,
    );
  }

  void changeEditingName(String v) => state = state.copyWith(editingName: v);
  void changeEditingPhotoPath(String p) => state = state.copyWith(editingPhotoUrl: p);

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    );
    if (cropped == null) return;

    changeEditingPhotoPath(cropped.path); // ローカルパスを編集用に保持
  }

  /// 保存（UseCase にトランザクションを委譲）
  Future<void> saveProfile() async {
    final editingName = state.editingName;
    final editingPhotoPath = state.editingPhotoUrl;
    final original = state.user;

    state = state.copyWith(isSaving: true, errorMessage: null);

    final useCase = ref.read(profileUseCaseProvider);

    try {
      final updatedUser = await useCase.saveProfile(
        originalUser: original,
        editingName: editingName,
        editingPhotoPath: editingPhotoPath,
      );

      // 成功したら Presentation の state を確定させる
      state = state.copyWith(
        user: updatedUser,
        isSaving: false,
        isEditing: false,
        editingName: updatedUser.displayName,
        editingPhotoUrl: updatedUser.photoUrl,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  /// 編集破棄
  void cancelEditing() {
    final u = state.user;
    state = state.copyWith(
      isEditing: false,
      editingName: u.displayName,
      editingPhotoUrl: u.photoUrl,
      errorMessage: null,
    );
  }
}
