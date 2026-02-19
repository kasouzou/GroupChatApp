import 'package:group_chat_app/features/chat/application/send_message_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat notifier.g.dart';

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {

  /// メッセージ送信（UseCase にトランザクションを委譲）
  Future<void> sendMessage() async {
    // 1. まず「送信中」という状態にしてUIを更新
    state = state.copyWith(isLoading: true);

    try {
      // 2. Application層（UseCase）を呼ぶ
      // インスタンスはDI（Riverpodのref.read等）で取得
      final useCase = ref.read(sendMessageUseCaseProvider);
      await useCase.sendMessage();

      // 3. 成功したら「成功状態」に更新
      // これを検知してUI（Widget）が勝手にリビルドされる！
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
