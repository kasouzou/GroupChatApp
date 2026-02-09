// プロフィールの詳細や編集を行うページです。
import 'package:flutter/material.dart';
import 'package:group_chat_app/pages/user_pages/profile_tab/ui/profile_edit_page.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  // ★ 独自に宣言した状態変数（今は使ってないけど、将来のスイッチ等に！）
  bool _isProfileDetailsPressed = false;

  @override
  Widget build(BuildContext context) {
    // 組み込みのMediaQueryを使って画面の向きを判定（レスポンシブ対応用）
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/image/splashscreen.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color.fromARGB(0, 0, 0, 0).withOpacity(0.2),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              debugPrint('×ボタンが押されました。"done" を持って前の画面へ戻ります[(プロフィール詳細画面)]');
              Navigator.pop(context, 'done');
            },
          ),
          title: const Text(
            'プロフィール詳細',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
        ),
        // body 直下のレイヤーに ShaderMask を配置
        body: ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0),
                Colors.white,
                Colors.white,
                Colors.white.withOpacity(0),
              ],
              stops: const [0.0, 0.05, 0.95, 1.0],
            ).createShader(bounds);
          },
          child: CustomScrollView(
            slivers: [
              // ★ ここが解決策：SliverSafeArea を使って、
              // 上部のAppBarとの干渉を避けつつ、下部の島ナビバー側は突き抜けさせる
              SliverSafeArea(
                top: true,    // ステータスバーとAppBarの余白を確保
                bottom: false, // 下部はマニュアル余白（height: 120）で制御
                sliver: SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10), // AppBarとの間にわずかな隙間
                        const Divider(height: 1, color: Colors.white24),

                        // プロフィール編集
                        _buildSettingsTile(
                          title: 'プロフィールを編集',
                          onTap: () async {
                            debugPrint('--- 今は[ProfileDetailsPage(プロフィール詳細画面)]にいます。 遷移開始: ProfileEditPageへ ---');
                            final result = await Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const ProfileEditPage(),
                                settings: const RouteSettings(name: 'ProfileEditPage'),
                              ),
                            );
                            debugPrint('--- 今は[ProfileDetailsPage(プロフィール詳細画面)]にいます。 ProfileEditPageから戻りました。受け取った結果: $result ---');
                          },
                        ),

                        const Divider(height: 1, thickness: 0.5, color: Colors.white24),
                        
                        // テーマカラー
                        _buildSettingsTile(
                          title: '権限リスト',
                          onTap: () => print(""),
                        ),
                        
                        const Divider(height: 1, thickness: 0.5, color: Colors.white24),
                        
                        // プライバシーポリシー
                        _buildSettingsTile(
                          title: 'プライバシーポリシー',
                          onTap: () => print("プライバシーポリシーへ遷移"),
                        ),

                        const Divider(height: 1, thickness: 0.5, color: Colors.white24),

                        // 退会
                        _buildSettingsTile(
                          title: '退会',
                          onTap: () => print("退会へ遷移"),
                        ),

                        const Divider(height: 1, thickness: 0.5, color: Colors.white24),
                      ],
                    ),
                  ),
                ),
              ),
              // 下部の余白（島ナビバーとの干渉避け）
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🛠️ 体系的な設計：設定タイルの共通化メソッド（独自に定義した関数）
  // 似たようなUIを何個も作るときは、こうして「部品化」するのがエンジニアの鋭い観察眼！
  Widget _buildSettingsTile({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromARGB(214, 0, 0, 0),
            Color.fromARGB(99, 0, 0, 0),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
