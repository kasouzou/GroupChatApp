import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:genron/pages/user_pages/profile_tab/profile_page.dart';
import 'package:genron/pages/user_pages/new_chat_tab/new_chat_page.dart';
import 'package:genron/pages/user_pages/my_chats_tab/my_chats_page.dart';

// なるほど — 見た目が黒くなるのはよくあるハマりで、原因はだいたいこのどれか：
// BottomNavigationBar を包む Material（内部的に使われるもの）が デフォルトで暗い色を描画している
// Scaffold がボトム領域を覆っていて 透過が効いていない（extendBody が無い）
// Material3 の surfaceTintColor / テーマが干渉して、透明にしても暗めのオーバーレイが乗る

// ▼ user-defined（自分で定義する StatefulWidget）
class YoutubeLikeBottomNavigationBar extends StatefulWidget {
  const YoutubeLikeBottomNavigationBar({super.key});

  @override
  State<YoutubeLikeBottomNavigationBar> createState() => _YoutubeLikeBottomNavigationBarState();
}

// ▼ user-defined（自分の State クラス）
class _YoutubeLikeBottomNavigationBarState extends State<YoutubeLikeBottomNavigationBar> {
  // ▼ user-defined: 今選ばれてるタブ index
  int selectedTabIndex = 0;

  // ▼ user-defined: 各タブ用の NavigatorState を外部から操作するための GlobalKey
  final List<GlobalKey<NavigatorState>> navigatorKeys = List.generate(
    3, // タブ数（必要なら増やす）
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      // outer background（user-defined）: 画面全体に薄い白を重ねる例
      decoration: const BoxDecoration(
        color: Color.fromARGB(33, 255, 0, 0),
      ),
      child: Scaffold(
        // ★ 重要: extendBody を true にして、body が bottomNavigationBar の背後まで伸びるようにする
        extendBody: true,

        // 既にやってるけど念押し：Scaffold の背景は透明にしておく
        backgroundColor: Colors.transparent,

        body: IndexedStack(
          index: selectedTabIndex,
          children: [
            _buildTabNavigator(0, const MyChatsPage()),
            _buildTabNavigator(1, const NewChatPage()),
            _buildTabNavigator(2, const ProfilePage()),
          ],
        ),
        // ★ bottomNavigationBarを Padding で包んで浮かせよう！
        // ★ BottomNavigationBar を Material でラップして内部 Material の色/影を潰す

        bottomNavigationBar: 
          Padding(
          // EdgeInsets.fromLTRB(左, 上, 右, 下): 独自に数値を決めて隙間を作る
          // 下に少し隙間（30.0）を作ることで「浮いている」感じを出すよ！
          padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 10.0),
          child: Material(
            color: Colors.transparent, // Material自体の色を透明に（これが効かないと黒っぽさが残る）
            // color: const Color.fromARGB(0, 255, 255, 255),
            elevation: 0, // Material の影を消す（念のため）BottomNavigationBar を包む Material（内部的に使われるもの）が デフォルトで暗い色を描画している
            child: ClipRRect( // ClipRRect: 子要素を角丸に切り抜く組み込みウィジェット
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25.0), // 左上の角丸（独自の値）
                topRight: Radius.circular(25.0), // 右上の角丸（独自の値）
                bottomLeft: Radius.circular(25.0), // 左下の角丸（独自の値）
                bottomRight: Radius.circular(25.0), // 右下の角丸（独自の値）
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  // ★ 波紋エフェクト（指紋のような跡）を根絶する設定
                  
                  // 1. 波紋の生成エンジン自体を無効化（Material 3等の残像対策に最強）
                  splashFactory: NoSplash.splashFactory,
                  
                  // 2. タップ中・ホバー中の背景色をすべて透明化
                  splashColor: Colors.transparent,    // 広がる波紋の色
                  highlightColor: Colors.transparent, // 押し続けている時の色
                  hoverColor: Colors.transparent,     // マウスを乗せた時の色（Web/Desktop用）

                  // ※ 視覚的な跡を消す分、BottomNavigationBarの enableFeedback: true で
                  // 指への振動フィードバックを返すと、操作感がさらに洗練されるよ！(設定済み)
                ),
                child: BottomNavigationBar(
                  // バー自体色
                  backgroundColor: const Color.fromARGB(193, 0, 0, 0),
                  elevation: 0, // アイコンの下の影を消す
                  type: BottomNavigationBarType
                      .fixed, // アイテムがシフトして見た目が変わるのを抑える（安定）
                  enableFeedback: true, // タップ時child: Theme(の振動フィードバックだけ残すなら true
                  // mouseCursor: SystemMouseCursors.click, // Webやデスクトップを意識するなら
                  selectedItemColor: const Color.fromARGB(255, 255, 183, 0),
                  unselectedItemColor: const Color.fromARGB(255, 255, 255, 255),
                  currentIndex: selectedTabIndex,
                  onTap: _onTapBottomNavItem,
                  items: const [
                    BottomNavigationBarItem(
                      icon: FaIcon(
                        FontAwesomeIcons.commentDots, // ★ 吹き出し＋ドット。これぞチャット！
                        size: 30, // FAアイコンは少し大きく見えるので調整
                      ),// 未選択時: アウトライン
                      activeIcon: FaIcon(
                        FontAwesomeIcons.solidCommentDots, // ★ 選択時は塗りつぶし
                        size: 30,
                      ),    // 選択時: 塗りつぶし (Filled)
                      label: "チャット"
                    ),
                    BottomNavigationBarItem(
                      // 未選択時：枠線のみ（Outlined）
                      icon: Icon(
                        Icons.group_add_outlined,
                        size: 28, // Material IconsはFAより少しシュッとしているので28-30付近で調整
                      ),
                      // 選択時：塗りつぶし（Filled）
                      activeIcon: Icon(
                        Icons.group_add, // デフォルトで塗りつぶし版になるよ
                        size: 28,
                      ),                      
                      label: "ルーム作成", // 短く「ルーム作成」にすると、横画面でも文字が溢れ（Overflow）にくいよ
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(
                        Icons.person_outline,
                        size:36,
                      ),
                      activeIcon: Icon(
                        Icons.person,
                        size:36,
                      ), // 選択時: 塗りつぶし (Filled)
                      label: "プロフィール"
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int tabIndex, Widget rootPage) {
    return Navigator(
      key: navigatorKeys[tabIndex],
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (_) => rootPage,
      ),
    );
  }

  void _onTapBottomNavItem(int tappedTabIndex) {
    if (tappedTabIndex == selectedTabIndex) {
      final navState = navigatorKeys[tappedTabIndex].currentState;
      if (navState != null) {
        navState.popUntil((route) => route.isFirst);
      }
    } else {
      setState(() {
        selectedTabIndex = tappedTabIndex;
      });
    }
  }
}
