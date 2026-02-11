import 'dart:async';
import 'package:group_chat_app/pages/user_pages/my_chats_tab/abstract/chat_abstract.dart';
import 'package:group_chat_app/pages/user_pages/my_chats_tab/model/chat_message_model.dart';
import 'package:uuid/uuid.dart';


class ChatService implements ChatAbstract {
  // 仮想のDB（メモリ上に保存）
  // 初期値としてダミーデータを用意しておくことにしたよ。
  final List<ChatMessageModel> _messages = [
    ChatMessageModel(
      id: const Uuid().v4(),
      groupId: 'family_group_001',
      senderId: 'user_father', // お父さん
      role: 'leader',
      message: '今日の夕飯は何かな？',
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    ChatMessageModel(
      id: const Uuid().v4(),
      groupId: 'family_group_001',
      senderId: 'user_mother', // お母さん
      role: 'member',
      message: '今日はハンバーグよ！',
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    ChatMessageModel(
      id: const Uuid().v4(),
      groupId: 'family_group_001',
      senderId: 'user_sister', // 妹
      role: 'member',
      message: 'わーい！楽しみ！',
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];
  
  // データの変更を通知するためのコントローラー（Streamの出口）
  final _controller = StreamController<List<ChatMessageModel>>.broadcast();

  // メモリ開放を忘れない！
  @override
  void dispose() {
    print('ChatServiceを片付けます！');
    _controller.close();
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages(String groupId) {
    // ★ 監視が始まった瞬間に、現在のリスト（初期値入り）を川に流す
    // Timer.runを使うことで、リスナーが準備できてからデータを流せるよ
    Timer.run(() {
      _controller.add(List.from(_messages.reversed));
    });
    return _controller.stream;
  }

  @override
  Future<void> sendMessage(String groupId, String senderId, String text) async {
    final uuid = Uuid().v4();
    // 新しいメッセージ（レコード）を作成
    final newMessage = ChatMessageModel(
      id: uuid, // ここでUUIDを生成！
      groupId: groupId,
      senderId: senderId,
      role: 'member',
      message: text,
      createdAt: DateTime.now(),
    );

    _messages.add(newMessage);
    
    // DBが更新されたので、接続中の全てのUIに「新しいリストだよ！」と通知する
    // これが「複数の携帯で同期」されるロジックの肝になるよ
    _controller.add(List.from(_messages.reversed)); 
  }
}