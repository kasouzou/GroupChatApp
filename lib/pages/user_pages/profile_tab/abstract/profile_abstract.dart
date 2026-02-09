// 抽象化することでProfileSeviceクラスで何を実装するべきなのかを明確にする役割を持ったクラスです。＝　抽象クラス
import 'package:group_chat_app/common/models/user_model.dart';

abstract class ProfileAbstract {
  /// ユーザー情報を取得して Stream に流す
  Future<void> fetchAndSyncUser(String userId);

  /// プロフィールを更新する
  Future<void> updateProfile(UserModel user);

  /// 画像ファイルをアップロードして、公開URLを返す（VPSを実装するまでは擬似エンドポイント）
  Future<String> uploadImage(String filePath);

  void dispose(); // リソース解放用メソッド
}

// ※補足：updateProfile()にuploadImage()を含めない理由
// updateProfile の仕事は、あくまで「ユーザーのプロフィール情報を更新すること」だよね。
// 一方で uploadImage は「ファイルをストレージに投げてURLをもらってくること」だ。
// もし updateProfile の中で画像のアップロード処理まで書き始めると、
// その関数は**「画像も上げるし、DBも更新する」という欲張りセット**になっちゃう。
// そうすると、コードがどんどん肥大化して、後で読み返したときに「この関数、結局何やってんの？」ってなるわけ。