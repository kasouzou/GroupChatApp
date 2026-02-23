// Flutterの基本ウィジェットを利用するためのインポート
import 'package:flutter/material.dart';
// メンバー追加ページのインポート
import 'package:group_chat_app/features/new_chat/presentation/pages/add_member_page.dart';
// チャット作成ページのインポート
import 'package:group_chat_app/features/new_chat/presentation/pages/make_chat_page.dart';

// 新規チャット作成やメンバー追加のハブとなるページ
class NewChatPage extends StatelessWidget {
  // コンストラクタ
  const NewChatPage({super.key});

  // 描画
  @override
  Widget build(BuildContext context) {
    // 画面情報を取得してレイアウトを切り替える
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final screenShortSide = mediaQuery.size.shortestSide;

    return Scaffold(
      appBar: AppBar(title: const Text('チャット作成＆メンバー追加')),
      body: SafeArea(
        // LayoutBuilderを使って親（画面）の最大高さを取得する
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                // コンテンツの最小高さを画面の高さ(constraints.maxHeight)に設定
                // これにより、CenterやMainAxisAlignment.centerが画面全体に対して機能する
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Center(
                    child: Flex(
                      // 横向きなら横並び、縦向きなら縦並びにする
                      direction: isLandscape ? Axis.horizontal : Axis.vertical,
                      mainAxisAlignment: MainAxisAlignment.center, // 垂直・水平方向の中央
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // チャット作成ボタン
                        _buildHubButton(
                          context: context,
                          label: 'チャット作成',
                          icon: Icons.add_comment,
                          destination: const MakeChatPage(),
                          routeName: 'MakeChatPage',
                          screenShortSide: screenShortSide,
                          isLandscape: isLandscape,
                        ),
                        // 縦・横に応じて適切な間隔を空ける
                        SizedBox(
                          width: isLandscape ? 40 : 0,
                          height: isLandscape ? 0 : 40,
                        ),
                        // メンバー追加ボタン
                        _buildHubButton(
                          context: context,
                          label: 'メンバー追加',
                          icon: Icons.group_add,
                          destination: const AddMemberPage(),
                          routeName: 'AddMembersPage',
                          screenShortSide: screenShortSide,
                          isLandscape: isLandscape,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ハブ画面で使う大きめのボタンウィジェットを生成するヘルパー
  Widget _buildHubButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Widget destination,
    required String routeName,
    required double screenShortSide,
    required bool isLandscape,
  }) {
    // 縦画面(Portrait)の時は少し大きめ(0.45)に設定して目立たせる
    final double buttonSize = isLandscape
        ? screenShortSide * 0.35
        : screenShortSide * 0.45;

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150, minHeight: 150),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 56, 210, 25),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), // 角丸デザイン
            ),
            elevation: 8, // 影を強くして立体感を出す
          ),
          onPressed: () async {
            // ボタン押下で目的の画面へ遷移する
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => destination,
                settings: RouteSettings(name: routeName),
              ),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // アイコン表示
              Icon(icon, size: buttonSize * 0.35),
              const SizedBox(height: 16),
              // ラベル表示
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: (buttonSize * 0.11).clamp(14.0, 22.0),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
