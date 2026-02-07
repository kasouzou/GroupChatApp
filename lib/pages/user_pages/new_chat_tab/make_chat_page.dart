import 'package:flutter/material.dart';
import 'package:genron/pages/user_pages/common_parts/show_discard_dialog.dart';

class MakeChatPage extends StatefulWidget {
  const MakeChatPage({super.key});

  @override
  State<MakeChatPage> createState() => _MakeChatPageState();
}

class _MakeChatPageState extends State<MakeChatPage> {
  // ▼ 独自に宣言した変数（状態管理用）
  final TextEditingController _chatNameController = TextEditingController();
  
  // 権限の状態をMapで管理（疎結合で拡張しやすい！）
  final Map<String, bool> _permissions = {
    'add_member': false,    // 新規メンバー追加権
    'delete_member': true,  // メンバーの削除
    'can_speak': true,      // 発言権
    'change_settings': true,// チャット名、アイコンの変更
    'delete_message': false,// 他人のメッセージ削除（追加提案）
    'pin_message': false,   // メッセージの固定（追加提案）
  };

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
      body: SingleChildScrollView( // ★ レスポンシブ対策：キーボードが出ても溢れない
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
                subtitle: key == 'add_member' ? const Text('(デフォルトではOFFになっています)') : null,
                value: _permissions[key],
                activeColor: const Color(0xFF4D86F7), // 保存ボタンに近い青
                onChanged: (bool? value) {
                  setState(() {
                    _permissions[key] = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading, // チェックボックスを左側に
              );
            }),
            
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  // 保存処理のロジックをここに書く
                  debugPrint('チャット名: ${_chatNameController.text}');
                  debugPrint('権限設定: $_permissions');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4D86F7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text('保存', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
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
      case 'add_member': return '新規メンバー追加権';
      case 'delete_member': return 'メンバーの削除';
      case 'can_speak': return '発言権';
      case 'change_settings': return 'チャット名、アイコンの変更';
      case 'delete_message': return '不適切な発言の削除（管理者以外も可にするか）';
      case 'pin_message': return '大事なメッセージを固定する権限';
      default: return key;
    }
  }
}