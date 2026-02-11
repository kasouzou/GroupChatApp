import 'package:group_chat_app/core/models/user_model.dart';
import 'package:group_chat_app/features/profile/domain/profile_repository.dart';

class UpdateProfileUsecase {
  final ProfileRepository repository;

  UpdateProfileUsecase(this.repository);

  Future<void> call(UserModel user) {
    return repository.updateProfile(user);
  }
}
