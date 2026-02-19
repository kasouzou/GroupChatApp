import 'package:group_chat_app/features/chat/di/send_message_usecase_provider.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_notifier.g.dart';

class ChatUiState {
  final String groupId;
  final String currentUserId;
  final String currentUserRole;
  final bool isSending;
  final String? errorMessage;

  const ChatUiState({
    required this.groupId,
    required this.currentUserId,
    required this.currentUserRole,
    this.isSending = false,
    this.errorMessage,
  });

  factory ChatUiState.initial() {
    return const ChatUiState(
      groupId: 'family_group_001',
      currentUserId: 'mock-user',
      currentUserRole: 'member',
    );
  }

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

@Riverpod(keepAlive: true)
class ChatNotifier extends _$ChatNotifier {
  @override
  ChatUiState build() {
    return ChatUiState.initial();
  }

  void setChatContext({
    required String groupId,
    required String currentUserId,
    required String currentUserRole,
  }) {
    state = state.copyWith(
      groupId: groupId,
      currentUserId: currentUserId,
      currentUserRole: currentUserRole,
      clearError: true,
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    state = state.copyWith(isSending: true, clearError: true);
    final useCase = ref.read(sendMessageUseCaseProvider);

    try {
      await useCase.execute(
        state.groupId,
        state.currentUserId,
        state.currentUserRole,
        TextContent(trimmed),
      );
      state = state.copyWith(isSending: false, clearError: true);
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: e.toString(),
      );
    }
  }
}
