import 'package:flutter/material.dart';

// メッセージのデータを扱うための簡単なクラス（疎結合を意識！）
class ChatMessage {
  final String name;
  final String text;
  final bool isMe;

  ChatMessage({required this.name, required this.text, required this.isMe});
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 入力欄をコントロールするための変数（独自に宣言した変数）
  final TextEditingController _textController = TextEditingController();
  
  // メッセージを保存しておくリスト（インメモリ）
  final List<ChatMessage> _messages = [
    // 初期表示用のダミーデータ
    ChatMessage(name: '米木波', text: 'あーなるほどねっす', isMe: false),
    ChatMessage(name: 'よねきたけし', text: '波のプレアデスみたいにiPhoneで撮って拡大したら、木星の縞模様が見えるかな？と思ったけどダメだった。てこと😅', isMe: false),
  ];

  // 送信ボタンが押された時の処理
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return; // 空文字は無視

    _textController.clear();
    setState(() {
      // reverse: true なので、リストの先頭に追加すると画面の下に表示されるよ
      _messages.insert(0, ChatMessage(name: '自分', text: text, isMe: true));
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF7494C0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7494C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context, 'done'),
        ),
        title: const Text('３０２号室 (5)', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // メッセージリスト部分
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              reverse: true, // これで最新のメッセージが下に来るようになる！
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(
                  context,
                  name: msg.name,
                  message: msg.text,
                  isMe: msg.isMe,
                  screenWidth: screenWidth,
                );
              },
            ),
          ),
          // 下部の入力エリア
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context,
      {required String name, required String message, required bool isMe, required double screenWidth}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        // 自分のメッセージは右寄せ、相手は左寄せ（レスポンシブ！）
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey),
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Text(name, style: const TextStyle(color: Colors.white, fontSize: 12)),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? const Color(0xFF8DE055) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(15),
                      topRight: const Radius.circular(15),
                      bottomLeft: Radius.circular(isMe ? 15 : 0),
                      bottomRight: Radius.circular(isMe ? 0 : 15),
                    ),
                  ),
                  child: Text(message, style: const TextStyle(color: Colors.black)),
                ),
              ),
              if (isMe) ...[
                const SizedBox(height: 4),
                const Text(
                  '既読',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.grey)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.photo_outlined, color: Colors.grey)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController, // 独自に宣言した変数をセット
                  onSubmitted: _handleSubmitted, // キーボードの「改行/完了」で送信
                  decoration: const InputDecoration(
                    hintText: 'Aa',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _handleSubmitted(_textController.text),
              icon: const Icon(Icons.send, color: Colors.blue), // 送信アイコンに変更
            ),
          ],
        ),
      ),
    );
  }
}
