import 'package:group_chat_app/features/chat/di/send_message_usecase_provider.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

/// チャット画面のUIの状態を管理するクラス
/// グループIDやユーザー情報、メッセージ送信の状態などを保持します
class ChatUiState {
  /// チャットが行われるグループID
  final String groupId;

  /// 現在ログインしているユーザーのID
  final String currentUserId;

  /// 現在のユーザーがグループ内で持つ役割（admin/member など）
  final String currentUserRole;

  /// メッセージ送信中かどうかを示すフラグ
  final bool isSending;

  /// エラーが発生した場合のメッセージ
  final String? errorMessage;

  const ChatUiState({
    required this.groupId,
    required this.currentUserId,
    required this.currentUserRole,
    this.isSending = false,
    this.errorMessage,
  });

  /// 初期状態を生成するファクトリコンストラクタ
  /// テスト用のデフォルト値を返します
  factory ChatUiState.initial() {
    return const ChatUiState(
      groupId: '',
      currentUserId: '',
      currentUserRole: 'member',
    );
  }

  /// 状態を部分的に更新するメソッド
  /// clearError: true の場合、エラーメッセージをクリアします
  ChatUiState copyWith({
    String? groupId,
    String? currentUserId,
    String? currentUserRole,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatUiState(
      groupId: groupId ?? this.groupId,
      currentUserId: currentUserId ?? this.currentUserId,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Riverpod のプロバイダーを使用してチャット状態を管理するNotifier
/// UI側から呼ばれて状態を更新し、その変更をUI側に通知します
@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  /// 初期状態を構築します
  /// keepAlive: true なので、ナビゲーションで画面を移動してもメモリに保持されます
  @override
  ChatUiState build() {
    return ChatUiState.initial();
  }

  /// チャット画面で必要なグループやユーザーの情報を設定します
  /// この情報はメッセージ送信時に使用されます
  void setChatContext({
    required String groupId,
    required String currentUserId,
    required String currentUserRole,
  }) {
    state = state.copyWith(// この「state」とは何でしょうか？ 根本から理解したいです。→https://www.notion.so/2026-1-28-2f68b8225642805a9a82c15189ab7826?source=copy_link#30f8b8225642800f8fd0e0ec92db6be5
      groupId: groupId,
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
      clearError: true,
    );
  }

  /// メッセージを送信する非同期処理
  /// 空のテキストや連続送信を防ぐチェック、エラーハンドリングを含みます
  Future<void> sendMessage(String text) async {
    /// テキストの前後の空白を削除
    final trimmed = text.trim();

    /// 空のテキストか送信中の場合は処理を中止
    if (trimmed.isEmpty || state.isSending) return;

    /// 送信中状態に更新してエラーをクリア
    state = state.copyWith(isSending: true, clearError: true);

    /// メッセージ送信のユースケースを取得
    final useCase = ref.read(sendMessageUseCaseProvider);

    try {
      /// ユースケースを実行してメッセージを送信
      await useCase.execute(
        state.groupId,
        state.currentUserId,
        state.currentUserRole,
        TextContent(trimmed),
      );

      /// 送信完了時に送信中フラグをオフにしてエラーをクリア
      state = state.copyWith(isSending: false, clearError: true);
    } catch (e) {
      /// エラー発生時はエラーメッセージを設定して送信中フラグをオフに
      state = state.copyWith(isSending: false, errorMessage: e.toString());
    }
  }
}
