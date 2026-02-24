// Flutterの基本ウィジェットを利用するためのインポート
import 'package:flutter/material.dart';
// RiverpodのConsumerStateを使うためのインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 認証セッションを取得するプロバイダのインポート
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
// チャット作成ユースケースのプロバイダを利用するためのインポート
import 'package:group_chat_app/features/new_chat/di/create_chat_usecase_provider.dart';
// 破棄確認ダイアログ表示用ヘルパーのインポート
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';

// グループ作成画面ウィジェット
/// グループ作成画面。
///
/// 責務:
/// - チャット名・権限UI入力
/// - 保存時に CreateChatUsecase を呼ぶ
/// - 作成成功で groupId を前画面へ返却
class MakeChatPage extends ConsumerStatefulWidget {
  // コンストラクタ
  const MakeChatPage({super.key});

  // Stateを生成
  @override
  ConsumerState<MakeChatPage> createState() => _MakeChatPageState();
}

// State実装
class _MakeChatPageState extends ConsumerState<MakeChatPage> {
  // チャット名入力用コントローラ
  final TextEditingController _chatNameController = TextEditingController();

  // 権限をMapで管理（キーで判定して表示）
  final Map<String, bool> _permissions = {
    'add_member': false, // 新規メンバー追加権
    'delete_member': true, // メンバーの削除
    'can_speak': true, // 発言権
    'change_settings': true, // チャット名、アイコンの変更
    'delete_message': false, // 他人のメッセージ削除（追加提案）
    'pin_message': false, // メッセージの固定（追加提案）
  };
  // 保存中フラグ（多重送信防止）
  bool _isSaving = false;

  // 解放処理
  @override
  void dispose() {
    _chatNameController.dispose();
    super.dispose();
  }

  // 描画
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          // 閉じるボタン。破棄確認を表示して戻る
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
        // レイアウトパディング（キーボード対応）
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'チャット名（後からでも変更できます。）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            // チャット名入力欄
            TextField(
              controller: _chatNameController, // 入力コントローラ
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF9195F6).withOpacity(0.6), // 背景色
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

            // 権限チェックボックスのリストを生成
            ..._permissions.keys.map((key) {
              return CheckboxListTile(
                title: Text(_getLabel(key)),
                subtitle: key == 'add_member'
                    ? const Text('(デフォルトではOFFになっています)')
                    : null,
                value: _permissions[key],
                activeColor: const Color(0xFF4D86F7), // チェック色
                onChanged: (bool? value) {
                  setState(() {
                    _permissions[key] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // チェックを左に表示
              );
            }),

            const SizedBox(height: 50),
            // 保存ボタン
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

  // キー名を表示用ラベルへ変換するヘルパー
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

  // 保存ボタン押下時の処理
  Future<void> _onSavePressed() async {
    // 1) 入力チェック
    final name = _chatNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('チャット名を入力してください')));
      return;
    }

    // 2) 保存処理開始（多重送信防止）
    setState(() => _isSaving = true);
    try {
      final currentUser = ref.read(authSessionProvider);
      final creatorUserId = currentUser?.id;
      if (creatorUserId == null || creatorUserId.isEmpty) {
        throw StateError('ログイン状態が無効です。再ログインしてください');
      }
      final usecase = ref.read(createChatUsecaseProvider);

      // 3) UseCase呼び出しでグループを作成
      final groupId = await usecase.call(
        name: name,
        creatorUserId: creatorUserId,
        memberUserIds: const [],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('グループを作成しました。ID: $groupId')));
      Navigator.pop(context, groupId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('作成に失敗しました。エラーの原因: $e')));
    } finally {
      // 4) 状態を元に戻す
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
