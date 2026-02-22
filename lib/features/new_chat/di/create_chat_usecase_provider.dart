import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/new_chat/application/create_chat_usecase.dart';
import 'package:group_chat_app/features/new_chat/di/new_chat_repository_provider.dart';

/// グループ作成UseCaseのDI。
final createChatUsecaseProvider = Provider<CreateChatUsecase>((ref) {
  final repository = ref.watch(newChatRepositoryProvider);
  return CreateChatUsecase(repository);
});
