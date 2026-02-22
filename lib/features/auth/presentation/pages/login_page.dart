import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/auth/di/google_login_usecase_provider.dart';
import 'package:group_chat_app/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:group_chat_app/ui/youtube_like_bottom_navigation_bar.dart';

/// ログイン画面。
///
/// 責務:
/// - ログイン操作の受付
/// - ローディング/エラーの表示
/// - 成功時にセッション保存してホームへ遷移
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isSigningIn = false;

  void _toYoutubeLikeBottomNavigationBarPage() {
    // ログイン済みユーザーをホーム画面へ遷移
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const YoutubeLikeBottomNavigationBar(),
        settings: const RouteSettings(name: 'YoutubeLikeBottomNavigationBar'),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (_isSigningIn) return;// 条件が true のとき → return を実行して関数終了条件が false のとき → return は実行されず、次の処理へ進む
    setState(() => _isSigningIn = true);

    final useCase = ref.read(googleLoginUseCaseProvider);
    try {
      // UseCase呼び出し。ここでGoogle認証 + API同期が実行される。
      final user = await useCase.signIn();
      if (user == null) return;
      // 全タブ共通で参照する認証セッションを更新。
      ref.read(authSessionProvider.notifier).state = user;
      if (!mounted) return;
      _toYoutubeLikeBottomNavigationBarPage();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ログインに失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ログイン / 新規登録',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '※本アプリは google ログインのみの\nシンプルな構成になっています。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 50),
            GoogleSignInButton(
              onPressed: _isSigningIn ? null : _handleSignIn,
              isLoading: _isSigningIn,
            ),
          ],
        ),
      ),
    );
  }
}

// 処理フロー
// ログイン画面表示
//     ↓
// Googleサインインボタン表示
//     ↓
// ユーザーがボタンをタップ
//     ├─ _handleSignIn() 実行
//     │   ├─ _isSigningIn = true（連続送信防止）
//     │   ├─ googleLoginUseCaseProvider から UseCase取得
//     │   ├─ useCase.signIn() 実行
//     │   │   └─ Googleでログイン → RemoteDataSourceでバックエンド認証
//     │   ├─ user != null → authSessionProvider に保存
//     │   └─ _isSigningIn = false
//     │
//     └─ ログイン成功 → YoutubeLikeBottomNavigationBar へ
//        ログイン失敗 → SnackBar でエラー表示
