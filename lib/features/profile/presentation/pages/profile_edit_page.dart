// プロフィールの編集ページです。
import 'package:flutter/material.dart';
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileNotifierProvider.notifier).startEditing();
    });

    final editingName = ref.read(profileNotifierProvider).editingName;
    _nameController = TextEditingController(text: editingName);
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 stateから現在の「編集中URL」を取得する
    final editingPhotoUrl = ref.watch(profileNotifierProvider.select((s) => s.editingPhotoUrl));

    // 💡 5. 保存中かどうかを監視（ボタンの無効化やグルグル表示に使う）
    final isSaving = ref.watch(profileNotifierProvider.select((s) => s.isSaving));

    // 💡 6. エラーが発生したらスナックバーを出す（副作用の監視）
    ref.listen(profileNotifierProvider.select((s) => s.errorMessage), (previous, next) {
      if (next != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next), backgroundColor: Colors.redAccent),
        );
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
            icon: const Icon(Icons.close, color: Color.fromARGB(255, 255, 255, 255)),
            onPressed: () async {
              final shouldDiscard = await showDiscardDialog(context);
              if (shouldDiscard != true) {
                return;
              }
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
                              ref.read(profileNotifierProvider.notifier).pickAndUploadImage();
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
                          _buildSaveButton(isSaving),// 💡 状態を渡す
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // 💡 保存処理のロジックを分離
  Future<void> _onSavePressed() async{
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    // Notifierを読み込む
    final notifier = ref.read(profileNotifierProvider.notifier);

    // 💡  Notifier を呼んで VPS に保存！
    await notifier.saveProfile(
      newName: _nameController.text,
    );
    // 💡 9. エラーがなければ画面を閉じる
    final error = ref.read(profileNotifierProvider).errorMessage;
    if (error == null && mounted) {
      Navigator.pop(context, 'saved');
    }
  }

  Widget _buildSaveButton(bool isSaving){
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSaving ? null : _onSavePressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: isSaving ? Colors.grey : const Color.fromARGB(230, 30, 144, 255),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
