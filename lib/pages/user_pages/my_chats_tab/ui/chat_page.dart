import 'package:flutter/material.dart';
import 'package:group_chat_app/pages/user_pages/my_chats_tab/model/chat_message_model.dart';
import 'package:group_chat_app/pages/user_pages/my_chats_tab/services/chat_service.dart';
import 'package:uuid/uuid.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // 入力欄をコントロールするための変数（独自に宣言した変数）
  final TextEditingController _textController = TextEditingController();

  // ChatServiceを使えるようにインスタンス化
  late ChatService _chatService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(); // ここで誕生
  }

  @override
  void dispose() {
    _chatService.dispose(); // ここで死ぬ（お片付け）
    super.dispose();
  }

  // 仮の自分の情報（実際はGoogleログインから取得する）
  final String _myGoogleUid = Uuid().v4();
  final String _currentGroupId = 'family_group_001';

  // 送信ボタンが押された時に呼ばれる関数
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    final String content = _textController.text;
    _textController.clear();

    // ChatServiceにメッセージ送信を依頼
    // UIは「送信した」という事実だけを投げればOK（疎結合！）
    _chatService.sendMessage(
      _currentGroupId,
      _myGoogleUid, 
      content
    );
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
          // StreamBuilderを使って、バックエンド（モック）の更新を監視する
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.watchMessages(_currentGroupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting){
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("メッセージがありません", style: TextStyle(color: Colors.white)),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  reverse: true, // 新しいメッセージが下に来るように
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    // senderIdが自分のGoogle UIDと同じなら「自分」と判定
                    final bool isMe = message.senderId == _myGoogleUid;

                    return _buildMessageBubble(
                      context, 
                      name: isMe ? '自分' : '家族メンバー', 
                      message: message.text, 
                      isMe: isMe, 
                      screenWidth: screenWidth
                    );
                  }
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
