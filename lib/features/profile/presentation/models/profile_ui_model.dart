import 'package:group_chat_app/core/models/user_model.dart';

class ProfileUiModel {
  // 1. DBから取得した「正解」のデータ（表示モードで使用）
  final UserModel user;

  // 2. 編集中の「仮」のデータ（編集モードで使用）
  // ユーザーがテキストフィールドに入力している最中の値を保持するよ
  final String editingName;
  final String editingPhotoUrl;

  // 3. モード管理フラグ
  final bool isEditing; // trueなら編集画面、falseなら表示画面
  final bool isSaving;  // 保存ボタン押下後のグルグル（Loading）状態

  final String? errorMessage;

  ProfileUiModel({
    required this.user,
    required this.editingName,
    required this.editingPhotoUrl,
    this.isEditing = false,
    this.isSaving = false,
    this.errorMessage,
  });

  // 💡 ツッコミ！: 編集を開始する時に、現在のユーザー情報を「仮データ」にコピーする関数
  factory ProfileUiModel.initial(UserModel user) {
    return ProfileUiModel(
      user: user,
      editingName: user.displayName,
      editingPhotoUrl: user.photoUrl,
      // errorMessage はデフォルトで null なので書かなくてOK
    );
  }

  // 疎結合を保つための copyWith
  ProfileUiModel copyWith({
    UserModel? user,
    String? editingName,
    String? editingPhotoUrl,
    bool? isEditing,
    bool? isSaving,
    String? errorMessage,
  }) {
    return ProfileUiModel(
      user: user ?? this.user,
      editingName: editingName ?? this.editingName,
      editingPhotoUrl: editingPhotoUrl ?? this.editingPhotoUrl,
      isEditing: isEditing ?? this.isEditing,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}