import 'package:flutter/material.dart';
import 'package:group_chat_app/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:group_chat_app/ui/youtube_like_bottom_navigation_bar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // AuthService を late で初期化
  // late final AuthService _authService;

  // @override
  // void initState() {
  //   super.initState();
  //   _authService = AuthService(); // ここでインスタンス化
  // }

  // Future<void> _handleSignIn() async {
  //   final user = await _authService.signIn();
  //   if (user != null && mounted) {
  //     // ログイン成功時の処理（チャット画面へ遷移など）
  //     print('ログイン成功: ${user.displayName} (ID: ${user.id})');
  //     // ここで Navigator.push を使う！
  //   }
  // }

  _ToYoutubeLikeBottomNavigationBarPage() {
    // ユーザ画面へ。
    // 後で認証状態に基づいて遷移先を変更するロジックを追加予定
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const YoutubeLikeBottomNavigationBar(),
        settings: RouteSettings(name: 'YoutubeLikeBottomNavigationBar'), // ← 名前を付ける
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ログイン / 新規登録', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              '※本アプリは google ログインのみの\nシンプルな構成になっています。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 50),
            // 分離したボタンコンポーネントを呼び出す
            GoogleSignInButton(onPressed: _ToYoutubeLikeBottomNavigationBarPage),
          ],
        ),
      ),
    );
  }
}