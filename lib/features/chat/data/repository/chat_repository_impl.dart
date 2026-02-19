import 'dart:async';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:uuid/uuid.dart';


class ChatRepositoryImpl implements ChatRepository {
  
  // データの変更を通知するためのコントローラー（Streamの出口）
  final _controller = StreamController<List<ChatMessageModel>>.broadcast();

  // メモリ開放を忘れない！
  @override
  void dispose() {
    _controller.close();
  }

  
  @override
  Future<void> saveMessage(ChatMessageModel message) {
    
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
