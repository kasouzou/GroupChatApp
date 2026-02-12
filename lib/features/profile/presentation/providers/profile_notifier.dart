// プロフィール画面の編集の成功をUIに反映するために、ストリームを監視して状態を更新するProfileNotifierの実装です。

import 'dart:ui';
import 'package:group_chat_app/features/profile/application/profile_usecase.dart';
import 'package:group_chat_app/features/profile/application/profile_usecase_provider.dart';
import 'package:group_chat_app/features/profile/presentation/models/profile_ui_model.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'profile_notifier.g.dart';

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  
  @override
  ProfileUiModel build() {
    // 💡 1. サービスの取得
    final profileUseCase = ref.watch(profileUseCaseProvider);

    // 💡 2. 監視を開始
    // build()が走るたびに古いsubscriptionは破棄されるよう、下でref.onDisposeを呼ぶ
    _listenToUserChanges(profileUseCase);

    // 💡 3. 初期状態
    // ProfileServiceから現在のユーザー情報の最新値を同期的に取れるならそれを使うのがベター
    // この最新値を、Streamで受け取るさらに新しい情報で更新し、UIに反映していくのがこのファイルの内容
    return ProfileUiModel.initial(profileUseCase.currentUser);
  }

  void _listenToUserChanges(ProfileUseCase profileUseCase) {
    final subscription = profileUseCase.userStream.listen((latestUser) {
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

  //ユーザーからプロフィールの編集があった際にVPSに変更を保存するメソッド
  Future<void> saveProfile({
    String? newName, 
    // 今後 role とか他のフィールドが増えてもここに追加すればOK！
    }
    ) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    // 💡 state.user.copyWith を使って、変更がある場所だけ上書きした新しいUserを作る
    final updatedUser = state.user.copyWith(
      displayName: newName ?? state.user.displayName, // もし左側（newName）が null だったら、右側の値を採用してね！
      photoUrl: state.editingPhotoUrl, // 💡 ここが重要！:// 💡 編集中URLがあればそれを、なければ元の画像アップロード直後の新しい画像、もしくは startEditing でコピーされた「今の画像」を引き継ぎ保存。
    );

    try {
      final profileUseCase = ref.read(profileUseCaseProvider);
      await profileUseCase.updateProfile(updatedUser);
      // ツッコミ！: 成功したら Service 側の Stream が最新の updatedUser を流してくれるから、
      // ここで state = ... を書かなくても、自動的に build() が走って画面が更新される。これが最強。
    } catch (e) {


      
      state = state.copyWith(isSaving: false, errorMessage: '保存に失敗しました');
    }
  }

  /// 💡 改造：画像を選択 -> 切り抜き -> アップロード
  Future<void> pickAndUploadImage() async {
    final picker = ImagePicker();
    // 1. ギャラリーから画像を選択
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return; // キャンセルされたら何もしない

    // 💡 2. 画像を正方形に切り抜く (丸いアイコン用)
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 1:1固定
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '画像を切り抜く',
          toolbarColor: const Color(0xFF000675),
          toolbarWidgetColor: const Color.fromARGB(255, 255, 255, 255),
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, // アスペクト比を固定
        ),
        IOSUiSettings(
          title: '画像を切り抜く',
        ),
      ],
    );

    if (croppedFile == null) return;


    // 2. アップロード中状態にする
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final profileUseCase = ref.read(profileUseCaseProvider);
      // 💡 切り抜かれたファイルパスをサービスに渡す
      final uploadedUrl = await profileUseCase.uploadImage(croppedFile.path);
      
      // 4. UI状態（編集中のURL）を更新
      // ここではまだDBには保存せず、メモリ上の「編集中」として保持する
      state = state.copyWith(
        editingPhotoUrl: uploadedUrl, 
        isSaving: false
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: '画像のアップロードに失敗しました');
    }
  }
}