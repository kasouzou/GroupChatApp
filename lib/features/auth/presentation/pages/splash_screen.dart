import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:group_chat_app/features/auth/presentation/pages/login_page.dart';
import 'package:group_chat_app/ui/youtube_like_bottom_navigation_bar.dart'; // SystemChromeを使うために必要

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreenPage> {
  @override
  void initState() {
    super.initState();
    // アプリの起動時に画面が自動で次に遷移するよう設定
    // 💡 UI関連の変更はinitStateに移動
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    _navigateToNextScreen();
  }

  // 画面遷移ロジック
  _navigateToNextScreen() async {
    // スプラッシュ画面を少し表示するために2秒間待機
    await Future.delayed(const Duration(seconds: 4));

    // ログイン画面へ。（ログインしていたら表示しないかも。）
    // 後で認証状態に基づいて遷移先を変更するロジックを追加予定
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
        settings: RouteSettings(name: 'LoginPage'), // ← 名前を付ける
      ),
    );
  }

  @override
  void dispose() {
    // 💡 画面が破棄される時に元のUI設定に戻す
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // スプラッシュ画面のステータスバーとナビゲーションバーを非表示にする
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          // AssetBitmap や NetworkImage も選べる
          image: AssetImage('assets/image/splashscreen.png'), 
          // fit: 組み込み。画像をどう画面に収めるか。
          // BoxFit.cover なら、画面いっぱいに（比率を保って）敷き詰めてくれる。
          fit: BoxFit.cover,
          // 画像が明るすぎて文字が見にくい時は、少し暗くしたり色を重ねたりもできる
          colorFilter: ColorFilter.mode(
            const Color.fromARGB(0, 0, 0, 0).withOpacity(0.2), // 20%くらい黒を乗せる
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        // スプラッシュ画面の背景色
        backgroundColor: Colors.transparent, // Containerの背景色を優先させるため透明に設定
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ロゴ画像を表示（角を丸くする）
              // ClipRRect( // ここを追加
              //   borderRadius: BorderRadius.circular(20.0), // ここで角の丸みを設定（例: 20.0）
                // child: 
                Image.asset(
                  'assets/icon/icon.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                    // エラー発生時にコンソール出力
                    print('画像の読み込みに失敗しました: $error');
                    return Icon(
                      Icons.error,
                      size: 100,
                      color: Colors.white, // 自作,
                    ); // 代替表示
                  }
                ),
              // ), // ここを追加
              const SizedBox(height: 20),
              // ロゴの下にテキストを表示
              Text(
                '言論空間',
                style: TextStyle(
                  color: Colors.white, // 自作
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
