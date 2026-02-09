// import 'package:google_sign_in/google_sign_in.dart';

// class GoogleLoginLogic {
//   // 組み込みクラス GoogleSignIn のインスタンスを独自に宣言
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email'],
//   );

//   // 現在ログインしているユーザー情報を取得するゲッター
//   GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

//   // ログイン処理
//   Future<GoogleSignInAccount?> signIn() async {
//     try {
//       // Google のサインイン画面を呼び出す組み込みメソッド
//       final GoogleSignInAccount? account = await _googleSignIn.signIn();
//       return account;
//     } catch (error) {
//       print('ログインエラー: $error');
//       return null;
//     }
//   }

//   // ログアウト処理
//   Future<void> signOut() => _googleSignIn.signOut();
// }