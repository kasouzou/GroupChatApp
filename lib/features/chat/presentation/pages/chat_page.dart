import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/chat/di/chat_repository_provider.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:group_chat_app/features/chat/presentation/providers/chat_notifier.dart';

/// 単一グループのチャット画面。
/// 呼び出し元から受け取った groupId/groupName を表示・送信に利用する。
class ChatPage extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;
  final String? currentUserId;

  const ChatPage({
    super.key,
    required this.groupId,
    required this.groupName,
    this.currentUserId,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _textController = TextEditingController();

  // 仮の自分の情報（実際はGoogleログインから取得する）
  late final String _myGoogleUid;
  late final String _currentGroupId;

  @override
  void initState() {
    super.initState();
    // 画面生成時に確定したコンテキストを保持する（認証セッション優先）。
    final sessionUser = ref.read(authSessionProvider);
    const fallbackUserId = String.fromEnvironment(
      'CHAT_USER_ID',
      defaultValue: 'user-001',
    );
    _myGoogleUid = widget.currentUserId ?? sessionUser?.id ?? fallbackUserId;// widget.currentUserId → 画面遷移時に渡されたユーザーID（優先度1） sessionUser?.id → 認証セッションから取得したユーザーID（優先度2） fallbackUserId → 環境変数から取得したユーザーID（優先度3、どれもなければ 'user-001'）どれも可用性（堅牢性）のためです。記事→https://www.notion.so/2026-1-28-2f68b8225642805a9a82c15189ab7826?source=copy_link#30f8b82256428035b574c5deeebe72c4
    _currentGroupId = widget.groupId;

    // 送信処理が参照する状態をNotifierへ反映。
    // 「今のフレームの描画（ビルド）が全部終わった直後に、1回だけこの処理をやってね！」というFlutterの仕組みを利用して、initState内でref.readする形にしています。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatNotifierProvider.notifier)
          .setChatContext(
            groupId: _currentGroupId,
            currentUserId: _myGoogleUid,
            currentUserRole: 'member',
          );
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final repository = ref.watch(chatRepositoryProvider);
    final chatState = ref.watch(chatNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF7494C0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7494C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context, 'done'),
        ),
        title: Text(
          widget.groupName,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: repository.watchMessages(_currentGroupId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? const <ChatMessageModel>[];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'メッセージがありません',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == _myGoogleUid;

                    return _buildMessageBubble(
                      context,
                      name: isMe ? '自分' : '家族メンバー',
                      message: _messageToText(message.content),
                      isMe: isMe,
                      screenWidth: screenWidth,
                    );
                  },
                );
              },
            ),
          ),
          if (chatState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                chatState.errorMessage!,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          _buildInputArea(chatState.isSending),
        ],
      ),
    );
  }

  String _messageToText(MessageContent content) {
    return switch (content) {
      TextContent(:final text) => text,
      ImageContent(:final fileName) => '[画像] $fileName',
    };
  }

  Widget _buildMessageBubble(
    BuildContext context, {
    required String name,
    required String message,
    required bool isMe,
    required double screenWidth,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.grey),
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
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
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.black),
                  ),
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

  Widget _buildInputArea(bool isSending) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add, color: Colors.grey),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.photo_outlined, color: Colors.grey),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  enabled: !isSending,
                  onSubmitted: _sendMessage,
                  decoration: const InputDecoration(
                    hintText: 'Aa',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: isSending
                  ? null
                  : () => _sendMessage(_textController.text),
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();
    await ref.read(chatNotifierProvider.notifier).sendMessage(text);
  }
}
