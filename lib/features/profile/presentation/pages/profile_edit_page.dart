// プロフィールの編集ページです。
import 'package:flutter/material.dart';
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/profile/presentation/providers/profile_notifier.dart';
import 'package:group_chat_app/features/profile/presentation/pages/widgets/profile_avatar_section.dart';
import 'package:group_chat_app/features/profile/presentation/pages/widgets/profile_text_field.dart';

// 💡 1. ConsumerStatefulWidget に変更
class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

// 💡 2. ConsumerState に変更
class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Controller は最初に空で作っておき、load -> startEditing 後に初期値を入れる。
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();

    // UI が描画された後にロード（ProfilePage が既にロード済みなら即座に startEditing する）
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final notifier = ref.read(profileNotifierProvider.notifier);

      // 1) 安全策：state.user が未ロードなら loadUser する（ProfilePage 経由でロード済なら skip）
      final current = ref.read(profileNotifierProvider).user;
      if (current.id.isEmpty) {
        final sessionUser = ref.read(authSessionProvider);
        final userId = sessionUser?.id;
        if (userId == null || userId.isEmpty) return;
        await notifier.loadUser(userId);
        if (!mounted) return;
      }

      // 2) load が終わった（もしくは既にロード済み）ので編集状態に移行
      notifier.startEditing();

      // 3) Notifier の editingName を初期値として controller にセット
      final editingName = ref.read(profileNotifierProvider).editingName;
      _nameController.text = editingName;
    });

    // Provider の editingName が後で変わったときに controller を追従させる（例：外部で編集名が更新された）
    ref.listen<String>(profileNotifierProvider.select((s) => s.editingName), (
      previous,
      next,
    ) {
      // ユーザーが直接入力中にテキストを上書きすると UX が悪いので、
      // controller.text と一致する場合は更新しない（無駄なカーソルジャンプを防ぐ）
      if (_nameController.text != next) {
        _nameController.text = next;
        // カーソルを末尾に戻す（入力中のジャンプを最小化）
        _nameController.selection = TextSelection.collapsed(
          offset: _nameController.text.length,
        );
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 stateから現在の「編集中URL」を取得する
    final editingPhotoUrl = ref.watch(
      profileNotifierProvider.select((s) => s.editingPhotoUrl),
    );

    // 💡 保存中かどうかを監視（ボタンの無効化やグルグル表示に使う）
    final isSaving = ref.watch(
      profileNotifierProvider.select((s) => s.isSaving),
    );

    // エラー通知は副作用として listen で扱う（build 内で呼ぶのは OK）
    ref.listen<String?>(profileNotifierProvider.select((s) => s.errorMessage), (
      previous,
      next,
    ) {
      if (next != null) {
        // ScaffoldMessenger を使って SnackBar を表示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next), backgroundColor: Colors.redAccent),
          );
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/image/splashscreen.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color.fromARGB(0, 0, 0, 0).withOpacity(0.2),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.close,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: () async {
              final shouldDiscard = await showDiscardDialog(context);
              if (shouldDiscard != true) {
                return;
              }
              // 編集をキャンセルして元の state（編集前のユーザープロフィールの状態） に戻す
              ref.read(profileNotifierProvider.notifier).cancelEditing();

              // もし画面が破棄されてたら何もしない。
              if (!mounted) return;

              debugPrint('×ボタンが押されました。"done" を持って前の画面へ戻ります[(プロフィール編集画面)]');
              Navigator.pop(context, 'cancel');
            },
          ),
          title: const Text(
            'プロフィール編集',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0),
                Colors.white,
                Colors.white,
                Colors.white.withOpacity(0),
              ],
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds);
          },
          child: CustomScrollView(
            slivers: [
              SliverSafeArea(
                top: true,
                bottom: false,
                sliver: SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Divider(height: 1, color: Colors.white24),
                          const SizedBox(height: 16),
                          ProfileAvatarSection(
                            editingPhotoUrl: editingPhotoUrl,
                            isSaving: isSaving,
                            onTap: () {
                              // 画像選択（ローカル保存のみ。アップロードは save 時に UseCase が行う）
                              ref
                                  .read(profileNotifierProvider.notifier)
                                  .pickImageFromGallery();
                            },
                          ),
                          const SizedBox(height: 16),
                          ProfileTextField(
                            label: '表示名',
                            controller: _nameController,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '表示名を入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildSaveButton(isSaving), // 💡 状態を渡す
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // 💡 保存処理のロジックを分離
  // 保存処理はここに集約（UI -> Notifier）
  Future<void> _onSavePressed() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // Notifierを読み込む
    final notifier = ref.read(profileNotifierProvider.notifier);

    // 1. 💡 実行前に、今のテキストフィールドの内容を Notifier に同期させる！
    // こうしないと、キーボードで打った最新の名前が Notifier の state に反映されないぜ。
    notifier.changeEditingName(_nameController.text);

    // 2. 💡 保存処理を実行（引数なしでOKなように Notifier を作ったからな！）
    // 💡  Notifier を呼んで VPS に保存！
    await notifier.saveProfile();

    // 3. 💡 エラーがなければ画面を閉じる
    // （ここでの ref.read は「保存完了後」の最新状態を確認しているから正しいぜ）
    // ③ 非同期処理後の mounted チェック
    // await の後に context を使うときは、必ず if (mounted) をチェックするのが Flutter プログラミングの鉄則だ。
    // 保存中にユーザーが無理やり画面を閉じちゃった場合にクラッシュするのを防げるぜ。
    //  1. まず「画面がまだ存在するか」をチェック。存在しないなら何もしない。
    if (!mounted) return;

    // 2. 画面が存在するなら、エラーがないか確認して pop する
    final error = ref.read(profileNotifierProvider).errorMessage;
    if (error == null) {
      Navigator.pop(context, 'saved');
    }
  }

  Widget _buildSaveButton(bool isSaving) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : _onSavePressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: isSaving
              ? Colors.grey
              : const Color.fromARGB(230, 30, 144, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isSaving
            ? const Text('保存中...')
            : const Text(
                '変更を保存する',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
      ),
    );
  }
}
