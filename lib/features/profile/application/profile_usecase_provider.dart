import 'package:group_chat_app/features/profile/application/profile_usecase.dart';
import 'package:group_chat_app/features/profile/data/repository/profile_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_usecase_provider.g.dart';

@riverpod
ProfileUseCase profileUseCase(ProfileUseCaseRef ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileUseCase(repository);
}
