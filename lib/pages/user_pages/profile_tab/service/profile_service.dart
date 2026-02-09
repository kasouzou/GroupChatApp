import 'dart:async';

import 'package:group_chat_app/common/models/user_model.dart';
import 'package:group_chat_app/pages/user_pages/profile_tab/abstract/profile_abstract.dart';


class ProfileService implements ProfileAbstract {
  // 💡 真実のデータを流し続けるためのコントローラー
  // .broadcast() にすることで、複数の画面で同時に監視できるよ
  //   1. なぜ StreamController を使うのか？
  // ツッコミ！: Firebase（Firestore）なら最初から snapshots() という Stream があるけど、VPS自作の場合は自分で「データの蛇口（Stream）」を作ってあげる必要があるんだ。
  // マクロな視点: これにより、どの画面からでも ProfileService.userStream を見に行けば、常に最新の自分が見える。これが「カプセル化」された設計だよ。
  final _userStreamController = StreamController<UserModel>.broadcast();
  //   2. broadcast() の重要性
  // ツッコミ！: 普通の Stream は1人しか監視できないけど、broadcast にしておかないと「プロフィール画面」と「ホーム画面」の両方で同時に監視したときにエラーになっちゃうよ。

  // 外部（ViewModelなど）はこの Stream を通じて最新情報を知る
  Stream<UserModel> get userStream => _userStreamController.stream;

  // 💡 ツッコミ！: 独自DB（VPS）と通信するためのAPIクライアントが必要だね
  // 本来はここが Dio や http パッケージを使った通信になる
  // final ApiClient _apiClient; 

  /// ユーザー情報を取得して Stream に流す
  @override
  Future<void> fetchAndSyncUser(String userId) async {
    try {
      // 1. VPSからデータを取得（擬似コード）
      // final response = await _apiClient.get('/users/$userId');
      // final latestUser = UserModel.fromMap(response.data);

      // 今はテスト用に擬似データを流すよ
      final latestUser = UserModel(
        id: userId,
        displayName: 'サミュエル・アルトマン',
        photoUrl: '',
        role: 'leader',
        createdAt: DateTime.now(),
      );

      // 2. Streamに最新情報を流す（これを監視している全画面が更新される！）
      _userStreamController.add(latestUser);
    } catch (e) {
      // 3. エラーハンドリング：透明性の高い設計 [cite: 2026-02-09]
      _userStreamController.addError('ユーザー情報の取得に失敗しました: $e');
    }
  }

  /// プロフィールを更新する
  @override
  Future<void> updateProfile(UserModel user) async {
    // 1. VPSへ保存リクエストを送る
    // await _apiClient.put('/users/${user.id}', data: user.toMap());

    // 2. 保存が成功したら、その最新の値をまた Stream に流す
    // これが「一方向データフロー」の鍵！
    _userStreamController.add(user);
  }

  // お片付け（メモリリーク防止）
  @override
  void dispose() {
    _userStreamController.close();
  }
}