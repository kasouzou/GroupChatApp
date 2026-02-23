// プロフィール画面です。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 💡 追加：Riverpodのインポート
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/profile/presentation/providers/profile_notifier.dart';
import 'package:group_chat_app/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:group_chat_app/features/profile/presentation/pages/settings_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  // ★ 1. 状態管理変数（独自変数）
  bool _isSettingsPressed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sessionUser = ref.read(authSessionProvider);
      final userId = sessionUser?.id;
      if (userId == null || userId.isEmpty) return;
      ref.read(profileNotifierProvider.notifier).loadUser(userId);
    });
  }

  // SettingsPageへの遷移メソッド
  Future<void> _openSettings() async {
    debugPrint(
      '--- 今は[profile_page(プロフィール画面)]にいます。 遷移開始: SettingsPageへ (rootNavigator: true(意味：ボトムナビゲーションバーの画面スタックじゃなくてRootNavigatorの画面スタックに積むよ)) ---',
    );
    // rootNavigator: true でボトムバーを隠す世界へ
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => SettingsPage(),
        settings: const RouteSettings(name: 'SettingsPage'),
      ),
    );
    debugPrint(
      '--- 今は[profile_page(プロフィール画面)]にいます。 SettingsPageから戻りました。受け取った結果: $result ---',
    );
  }

  /// 編集画面へ遷移する。未ロードならロードしてから startEditing -> push することで
  /// ProfileEditPage 側で state.user が確実に存在するようにする（引き継ぎの保証）。
  Future<void> _openProfileEdit() async {
    final notifier = ref.read(profileNotifierProvider.notifier);
    final state = ref.read(profileNotifierProvider);

    // userId が空なら（未ロードなら）ここでロードする。userId の取得方法はアプリ次第。
    if (state.user.id.isEmpty) {
      final sessionUser = ref.read(authSessionProvider);
      final userId = sessionUser?.id;
      if (userId == null || userId.isEmpty) return;
      await notifier.loadUser(userId);
    }

    // 編集用フィールドにコピーしておく
    notifier.startEditing();

    // 遷移（rootNavigator を使ってボトムナビゲーションの外に積む設計）
    debugPrint(
      '--- 今は[profile_page(プロフィール画面)]にいます。 遷移開始: プロフィール編集画面へ (rootNavigator: true(意味：ボトムナビゲーションバーの画面スタックじゃなくてRootNavigatorの画面スタックに積むよ)) ---',
    );
    // rootNavigator: true でボトムバーを隠す世界へ
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(),
        settings: const RouteSettings(name: 'ProfileEditPage'),
      ),
    );
    debugPrint(
      '--- 今は[profile_page(プロフィール画面)]にいます。 プロフィール編集画面から戻りました。受け取った結果: $result ---',
    );
  }

  @override
  Widget build(BuildContext context) {
    // 💡 2. キャッシュされた最新のユーザー情報を取得（監視開始）
    // これにより、編集画面で保存が成功すると、この build() が自動で再実行されるぜ
    final profileState = ref.watch(profileNotifierProvider);
    final user = profileState.user;

    // 画面サイズを取得して、横向きかどうかを判定する（マクロな視点）
    // final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
        // AppBar を Scaffold に持たせる（セーフエリアを自動考慮してくれる！）
        appBar: AppBar(
          backgroundColor: Colors.transparent, // 背景画像を透かす
          elevation: 0,
          title: const Text(
            'プロフィール',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          actions: [
            // ★ 2. インタラクティブな設定ボタン
            GestureDetector(
              onTapDown: (_) => setState(() => _isSettingsPressed = true),
              onTapUp: (_) => setState(() => _isSettingsPressed = false),
              onTapCancel: () => setState(() => _isSettingsPressed = false),
              onTap: _openSettings,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Icon(
                    // 三項演算子でアイコンを切り替え
                    _isSettingsPressed
                        ? Icons
                              .settings // 押してる時：塗りつぶし
                        : Icons.settings_outlined, // 離してる時：線
                    key: ValueKey<bool>(_isSettingsPressed),
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
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
              stops: const [0.0, 0.05, 0.95, 1.0], // 横画面でも見やすいよう幅を調整
            ).createShader(bounds);
          },
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // プロフィールヘッダー部分
                        // 横画面でのOverflowを防ぐため、WrapやSingleChildScrollViewを検討する場合もある
                        // --- ここから編集：Container（グラデーション） + Material + InkWell ---
                        Container(
                          decoration: BoxDecoration(
                            // ★ 1. 左から右へのグラデーション（独自のデザイン！）
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft, // 左から
                              end: Alignment.centerRight, // 右へ
                              colors: [
                                Color.fromARGB(215, 0, 6, 117), // 濃い青
                                Color.fromARGB(100, 102, 126, 234), // 薄い青
                              ],
                            ),
                            // 2. Container自体の角も丸くする
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            // ★ 3. 重要：Materialの色は「透明」にする（Containerの色を透かすため）
                            color: Colors.transparent,
                            clipBehavior: Clip.antiAlias,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: _openProfileEdit,
                              splashColor: Colors.white.withOpacity(0.2),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  children: [
                                    // 💡 3. アイコン画像の出し分け
                                    CircleAvatar(
                                      radius: 35,
                                      backgroundImage: user.photoUrl.isNotEmpty
                                          ? NetworkImage(user.photoUrl)
                                                as ImageProvider
                                          : AssetImage(
                                              'assets/image/treatGemini.png',
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // 💡 4. キャッシュされた名前を表示！
                                          Text(
                                            user.displayName.isNotEmpty
                                                ? user.displayName
                                                : '未設定',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'OpenAI社の最高経営責任者',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ), // グラデの上で見えやすいよう少し濃く
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.white24,
                        ),
                        // ここに自己紹介や統計情報などのコンテンツを並べていく
                      ],
                    ),
                  ),
                ),
                // 下部の余白（島ナビバーとの干渉避け）
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
