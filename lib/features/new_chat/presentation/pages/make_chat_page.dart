import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/new_chat/di/create_chat_usecase_provider.dart';
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';

/// グループ作成画面。
///
/// 責務:
/// - チャット名・権限UI入力
/// - 保存時に CreateChatUsecase を呼ぶ
/// - 作成成功で groupId を前画面へ返却
class MakeChatPage extends ConsumerStatefulWidget {
  const MakeChatPage({super.key});

  @override
  ConsumerState<MakeChatPage> createState() => _MakeChatPageState();
}

class _MakeChatPageState extends ConsumerState<MakeChatPage> {
  // ▼ 独自に宣言した変数（状態管理用）
  final TextEditingController _chatNameController = TextEditingController();

  // 権限の状態をMapで管理（疎結合で拡張しやすい！）
  final Map<String, bool> _permissions = {
    'add_member': false, // 新規メンバー追加権
    'delete_member': true, // メンバーの削除
    'can_speak': true, // 発言権
    'change_settings': true, // チャット名、アイコンの変更
    'delete_message': false, // 他人のメッセージ削除（追加提案）
    'pin_message': false, // メッセージの固定（追加提案）
  };
  bool _isSaving = false;

  @override
  void dispose() {
    _chatNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () async {
            final shouldDiscard = await showDiscardDialog(context);
            if (shouldDiscard != true) {
              return;
            }
            debugPrint('×ボタンが押されました。編集を破棄して戻ります。(チャット作成画面)');
            Navigator.pop(context, 'cancel');
          },
        ),
        title: const Text('チャット作成画面', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        // ★ レスポンシブ対策：キーボードが出ても溢れない
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'チャット名（後からでも変更できます。）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _chatNameController, // 組み込みのコントローラー
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF9195F6).withOpacity(0.6), // ラフの色に近い紫
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'メンバーに与える権限（後からでも変更できます）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),

            // 権限リストの生成
            ..._permissions.keys.map((key) {
              return CheckboxListTile(
                title: Text(_getLabel(key)),
                subtitle: key == 'add_member'
                    ? const Text('(デフォルトではOFFになっています)')
                    : null,
                value: _permissions[key],
                activeColor: const Color(0xFF4D86F7), // 保存ボタンに近い青
                onChanged: (bool? value) {
                  setState(() {
                    _permissions[key] = value ?? false;
                  });
                },
                controlAffinity:
                    ListTileControlAffinity.leading, // チェックボックスを左側に
              );
            }),

            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving
                      ? Colors.grey
                      : const Color(0xFF4D86F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  _isSaving ? '保存中...' : '保存',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // キー名を表示用テキストに変換する独自関数
  String _getLabel(String key) {
    switch (key) {
      case 'add_member':
        return '新規メンバー追加権';
      case 'delete_member':
        return 'メンバーの削除';
      case 'can_speak':
        return '発言権';
      case 'change_settings':
        return 'チャット名、アイコンの変更';
      case 'delete_message':
        return '不適切な発言の削除（管理者以外も可にするか）';
      case 'pin_message':
        return '大事なメッセージを固定する権限';
      default:
        return key;
    }
  }

  Future<void> _onSavePressed() async {
    // 1) 入力チェック
    final name = _chatNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('チャット名を入力してください')));
      return;
    }

    // 2) 保存開始（多重送信防止）
    setState(() => _isSaving = true);
    try {
      final currentUser = ref.read(authSessionProvider);
      const fallbackUserId = String.fromEnvironment(
        'CHAT_USER_ID',
        defaultValue: 'user-001',
      );
      final creatorUserId = currentUser?.id ?? fallbackUserId;
      final usecase = ref.read(createChatUsecaseProvider);

      // 3) UseCase実行 -> APIでグループ作成
      final groupId = await usecase.call(
        name: name,
        creatorUserId: creatorUserId,
        memberUserIds: const [],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('作成しました: $groupId')));
      Navigator.pop(context, groupId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('作成に失敗しました: $e')));
    } finally {
      // 4) 保存状態を戻す
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
