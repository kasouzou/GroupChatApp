import 'package:group_chat_app/features/profile/domain/profile_repository.dart';

class UploadAvatarUsecase {
  final ProfileRepository repository;

  UploadAvatarUsecase(this.repository);

  Future<String> call(String filePath) {
    return repository.uploadImage(filePath);
  }
}
