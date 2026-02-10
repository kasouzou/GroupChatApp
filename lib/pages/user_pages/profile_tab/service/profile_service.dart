import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:group_chat_app/common/models/user_model.dart';
import 'package:group_chat_app/pages/user_pages/profile_tab/abstract/profile_abstract.dart';

part 'profile_service.g.dart';
// 💡 2. Provider（特定のインスタンスを保持しているメモリ上の住所（キャッシュ））の定義はクラスの「外」に置くのがルール！
// profileService↓は自動生成されるprofileServiceProvderの設計図で、これをもとに実際のProvider＝特定のインスタンスを保持しているメモリ上の住所（キャッシュ））が生成され、このインスタンスがアプリ内で共有して使い回されることでメモリを節約します。
@riverpod
ProfileService profileService(ProfileServiceRef ref) {
  final service = ProfileService();
  
  // 💡 3. メモリリーク防止！ 
  // Providerが破棄される時に自動で dispose を呼ぶように予約しておく
  ref.onDispose(() => service.dispose());
  
  return service;
}

class ProfileService implements ProfileAbstract {
  // 💡 1. 「バケツ」を用意する（最新のユーザー情報の値をメモリにキャッシュしておく）
  UserModel _currentUser = UserModel.empty();// 最初は empty

  // 💡 2. 外部から「今の最新値」をサッと取れるようにする
  UserModel get currentUser => _currentUser;

  // 💡 真実のデータを流し続けるためのコントローラー
  // .broadcast() にすることで、複数の画面で同時に監視できるよ
  //   1. なぜ StreamController を使うのか？
  // ツッコミ！: Firebase（Firestore）なら最初から snapshots() という Stream があるけど、VPS自作の場合は自分で「データの蛇口（Stream）」を作ってあげる必要があるんだ。
  // マクロな視点: これにより、どの画面からでも ProfileService.userStream を見に行けば、常に最新の自分が見える。これが「カプセル化」された設計だよ。
    //   2. broadcast() の重要性
  // ツッコミ！: 普通の Stream は1人しか監視できないけど、broadcast にしておかないと「プロフィール画面」と「ホーム画面」の両方で同時に監視したときにエラーになっちゃうよ。
  final _userStreamController = StreamController<UserModel>.broadcast();


  // 外部（ViewModelなど）はこの Stream を通じて最新情報を知る
  Stream<UserModel> get userStream => _userStreamController.stream;

  // 💡 ツッコミ！: 独自DB（VPS）と通信するためのAPIクライアントが必要だね
  // 本来はここが Dio や http パッケージを使った通信になる
  // final ApiClient _apiClient; 

  // 💡 3. コンストラクタで初期値をセット（FirebaseAuthを活用！）
  // ProfileService() {
  //   // 仮説を排除し、事実（Firebaseの現在の状態）を確認する
  //   final firebaseUser = FirebaseAuth.instance.currentUser;
  //   if (firebaseUser != null) {
  //     _currentUser = UserModel(
  //       id: firebaseUser.uid,
  //       displayName: firebaseUser.displayName ?? '',
  //       photoUrl: firebaseUser.photoURL ?? '',
  //       role: 'user', // デフォルト値
  //       createdAt: DateTime.now(),
  //     );
  //   }
  // }

  /// ユーザー情報を取得して Stream に流す
  @override
  Future<void> fetchAndSyncUser(String userId) async {
    try {
      // 1. VPSからデータを取得（擬似コード）
      // final response = await _apiClient.get('/users/$userId');
      // final latestUser = UserModel.fromMap(response.data);

      // 今はテスト用にVPSから以下のデータが渡ってきたと仮定して擬似データを流すよ
      final latestUser = UserModel(
        id: userId,
        displayName: '米木歩',
        photoUrl: 'assets/icon/icon.png',
        createdAt: DateTime.now(),
      );

      // 💡 4. Streamに流すだけじゃなく、バケツ（_currentUser）も更新する！
      _currentUser = latestUser;

      // 2. Streamに最新情報を流す（これを監視している全画面が更新される！）
      _userStreamController.add(latestUser);
    } catch (e) {
      // 3. エラーハンドリング：透明性の高い設計 [cite: 2026-02-09]
      _userStreamController.addError('ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// プロフィールを更新する（プロフィール画像は別でUploadImageメソッドとして下記に切り出し。）
  @override
  Future<void> updateProfile(UserModel user) async {
    // 1. VPSへ保存リクエストを送る
    // await _apiClient.put('/users/${user.id}', data: user.toMap());

    // 💡 5. 保存成功時もバケツを更新！
    _currentUser = user;
    
    // 2. 保存が成功したら、その最新の値をまた Stream に流す
    // これが「一方向データフロー」の鍵！
    _userStreamController.add(user);
  }

  /// 画像ファイルをアップロードして、公開URLを返す（擬似エンドポイント）
  @override
  Future<String> uploadImage(String filePath) async {
    // 💡 ツッコミ！: 本来はここで MultipartFile を作って Dio とかで VPS に POST するんだ。
    // final formData = FormData.fromMap({
    //   'file': await MultipartFile.fromFile(filePath),
    // });
    // final response = await _apiClient.post('/upload', data: formData);
    // return response.data['url'];

    // 今は擬似的に2秒待機して、ダミーのURLを返すよ
    await Future.delayed(const Duration(seconds: 2));
    
    // 成功した体で、適当な画像URLを返す
    return 'https://picsum.photos/200'; 
  }

  // お片付け（メモリリーク防止）
  @override
  void dispose() {
    _userStreamController.close();
  }
}