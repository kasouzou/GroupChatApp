import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed; // 独自に定義したコールバック関数

  const GoogleSignInButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        // 公式ガイドラインに近い、少し薄めのグレーの境界線
        side: const BorderSide(color: Color(0xFF747474), width: 0.5),
        // Googleのボタンは角丸が控えめ（4.0px程度）
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        // 押し心地を良くするための設定
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ボタンの幅をコンテンツ（画像と文字）に合わせる
        children: [
          // ★ 修正ポイント：Iconから本物の画像（独自アセット）へ
          Image.asset(
            'assets/google_sign_in_icons/Android/png@4x/neutral/android_neutral_rd_na@4x.png',
            width: 18, // ガイドラインで推奨されるサイズ感
            height: 18,
            fit: BoxFit.contain, // 比率を維持して収める
            errorBuilder: (context, error, stackTrace) {
              // 万が一、画像の読み込みに失敗した時のためのバックアップ
              return const Icon(Icons.error, size: 18, color: Colors.red);
            },
          ),
          const SizedBox(width: 12), // ロゴとテキストの間の「クリアスペース」
          const Text(
            'Google でサインイン', // ガイドラインに多い表記
            style: TextStyle(
              color: Color(0xFF757575), // 公式推奨のテキスト色（濃いめのグレー）
              fontWeight: FontWeight.w500,
              fontSize: 14,
              fontFamily: 'Roboto', // Google系の標準フォント
            ),
          ),
        ],
      ),
    );
  }
}