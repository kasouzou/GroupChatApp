// 抽象化することでProfileSeviceクラスで何を実装するべきなのかを明確にする役割を持ったクラスです。＝　抽象クラス
import 'package:group_chat_app/common/models/user_model.dart';

abstract class ProfileAbstract {
  /// ユーザー情報を取得して Stream に流す
  Future<void> fetchAndSyncUser(String userId);

  /// プロフィールを更新する
  Future<void> updateProfile(UserModel user);

  void dispose(); // リソース解放用メソッド
}