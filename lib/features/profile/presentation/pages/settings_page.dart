import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/di/auth_remote_datasource_provider.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/auth/di/google_login_usecase_provider.dart';
import 'package:group_chat_app/features/auth/presentation/pages/login_page.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _isSigningOut = false;

  @override
  Widget build(BuildContext context) {
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
              debugPrint(
                '×ボタンが押されました。"done" を持って前の画面へ戻ります[SettingsPage(設定画面)]',
              );
              Navigator.pop(context, 'done');
            },
          ),
          title: const Text(
            '設定',
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
                top: true, // ステータスバーとAppBarの余白を確保
                bottom: false, // 下部はマニュアル余白（height: 120）で制御
                sliver: SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10), // AppBarとの間にわずかな隙間
                        const Divider(height: 1, color: Colors.white24),

                        // 通知設定
                        _buildSettingsTile(
                          title: '通知設定',
                          onTap: () => print("通知設定へ遷移"),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white24,
                        ),

                        // テーマカラー
                        _buildSettingsTile(
                          title: 'テーマカラー',
                          onTap: () => print("テーマカラーへ遷移"),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white24,
                        ),

                        // プライバシーポリシー
                        _buildSettingsTile(
                          title: 'プライバシーポリシー',
                          onTap: () => print("プライバシーポリシーへ遷移"),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white24,
                        ),

                        // 利用規約
                        _buildSettingsTile(
                          title: '利用規約',
                          onTap: () => print("利用規約へ遷移"),
                        ),

                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white24,
                        ),

                        _buildSettingsTile(
                          title: _isSigningOut ? 'ログアウト中...' : 'ログアウト',
                          onTap: _isSigningOut ? null : _onSignOutTap,
                          leadingIcon: Icons.logout,
                          showChevron: false,
                        ),

                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 下部の余白（島ナビバーとの干渉避け）
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
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
    required VoidCallback? onTap,
    IconData? leadingIcon,
    bool showChevron = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color.fromARGB(214, 0, 0, 0), Color.fromARGB(99, 0, 0, 0)],
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
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                ],
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
                if (showChevron)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                    size: 28,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSignOutTap() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    setState(() => _isSigningOut = true);
    try {
      final session = ref.read(authSessionProvider);
      final token = session?.accessToken;
      if (token != null && token.isNotEmpty) {
        final remote = ref.read(authRemoteDataSourceProvider);
        await remote.logout(accessToken: token);
      }

      final useCase = ref.read(googleLoginUseCaseProvider);
      await useCase.signOut();
      ref.read(authSessionProvider.notifier).state = null;

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: const RouteSettings(name: 'LoginPage'),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ログアウトに失敗しました: $e')));
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }
}
