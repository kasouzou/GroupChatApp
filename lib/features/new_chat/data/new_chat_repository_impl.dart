import 'package:group_chat_app/features/new_chat/data/datasource/remote/new_chat_remote_datasource.dart';
import 'package:group_chat_app/features/new_chat/domain/new_chat_repository.dart';

class NewChatRepositoryImpl implements NewChatRepository {
  final NewChatRemoteDataSource remote;

  NewChatRepositoryImpl({required this.remote});

  @override
  Future<String> createChat({
    required String name,
    required String creatorUserId,
    required List<String> memberUserIds,
  }) async {
    return remote.createGroup(
      name: name,
      creatorUserId: creatorUserId,
      memberUserIds: memberUserIds,
    );
  }
}
