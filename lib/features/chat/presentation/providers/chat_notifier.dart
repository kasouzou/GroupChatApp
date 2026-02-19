// lib/features/chat/presentation/chat_notifier.dart

import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  // @override
  // ChatUiState build() {
  //   // 初期状態を返す（groupId などが state に入っている想定）
  //   return ChatUiState.initial();
  // }

  /// メッセージ送信
  /// UI側の「送信ボタン」から呼ばれる。引数にメッセージ本文（content）をもらう想定
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. UIの状態を更新（必要ならボタンを無効化するなど）
    // ※UseCase内部で「Pending保存」が行われるので、
    //   ここではテキストフィールドを空にするなどの処理がメインになるぜ！
    
    try {
      // 2. UseCase を取得
      final useCase = ref.read(sendMessageUseCaseProvider);

      // 3. 必要な情報をかき集めて実行！
      // state の中に現在表示中の groupId や、自分の senderId が入っている想定だぜ
      await useCase.execute(
        state.groupId,
        state.currentUserId,
        state.currentUserRole,
        content, // ここで値オブジェクトに包む！
      );

      // 4. 成功時のUI処理（入力欄をクリアするなど）
      state = state.copyWith(errorMessage: null);
      
    } catch (e) {
      // 5. エラーがあれば通知（失敗時のDB保存自体は UseCase がやってくれている）
      state = state.copyWith(errorMessage: e.toString());
    }
  }
}

// 「Notifier は『司令塔』、UseCase は『実行部隊』。この関係が綺麗に構築できたな！ 
//あとは UI 側のテキストフィールドから ref.read(chatNotifierProvider.notifier).sendMessage(controller.text) と呼ぶだけだ。」