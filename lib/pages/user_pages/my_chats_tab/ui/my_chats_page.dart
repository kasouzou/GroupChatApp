// 自分の所属しているチャットをリストで表示するページです。

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:group_chat_app/pages/user_pages/my_chats_tab/ui/chat_page.dart';

// 状態を持つために StatefulWidget に変更！
class MyChatsPage extends StatefulWidget {
  const MyChatsPage({super.key});

  @override
  State<MyChatsPage> createState() => _MyChatsPageState();
}

class _MyChatsPageState extends State<MyChatsPage> {
  final int _myChatCount = 25;

  final TextEditingController _searchController = TextEditingController();

  // ★ 1. 現在どのソートが選ばれているかを管理する変数（user-defined）
  // 初期値は「未読順」にするために 0 をセット
  int _selectedSortIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          // AssetBitmap や NetworkImage も選べる
          image: AssetImage('assets/image/back2.png'),
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
        backgroundColor: Colors.transparent,
        // 【重要】Saf渋谷eArea の bottom: false は「島」の下の余白を消すため
        body: ShaderMask(
          shaderCallback: (Rect bounds) {
            // LinearGradient: 組み込み。上下方向の透明度グラデーションを作る。
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0), // 上端：消える（ノッチ付近）
                Colors.white, // 少し下：見える
                Colors.white, // 下の方：見える
                Colors.white.withOpacity(0), // 下端：消える（島ナビバー付近）
              ],
              // stops: 独自の値。0.1(10%)くらいまでボカすと自然だよ。
              stops: const [0.0, 0.1, 0.9, 1.0],
            ).createShader(bounds);
          },
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomScrollView(
                // CustomScrollView: 組み込み。複数のスクロールパーツを一つにまとめる
                slivers: [
                  // 1. 上半分のパーツ（SearchBarやチップス）を「スクロールするリストの一部」にする
                  SliverToBoxAdapter(
                    // SliverToBoxAdapter: 組み込み。普通のWidgetをSliver（スクロール用）に変換する
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        SearchBar(
                          controller: _searchController,
                          hintText: '自分のチャット検索',
                          leading: const Icon(Icons.search),
                        ),

                        const SizedBox(height: 16), // 検索バーとの間隔
                        // ★ ここに並び替えトグルを配置！
                        // ★ 2. タップで動くようにしたトグルコンテナ
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // index 0: 未読順
                              _buildSortTab(0, "未読順"),
                              // index 1: 最新順
                              _buildSortTab(1, "最新順"),
                              // index 2: 人気順
                              _buildSortTab(2, "人気順"),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // 2. メインのリスト部分
                  // ListView.builder の代わりに SliverList を使うのがマクロ視点の正解！
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return MyChatCard(
                          myChatTitle: 'チャット$index',
                          parentCommitTitle: 'parent commit',
                          parentCommitId: 'abc123',
                          elapsed: '1時間前',
                          onMyChatCardTap: () async {
                            print('チャット$index がタップされました');
                            // rootNavigator: true でボトムバーを隠す世界へ
                            final result =
                                await Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ChatPage(),
                                    settings: const RouteSettings(
                                      name: 'ChatPage',
                                    ),
                                  ),
                                );
                          },
                          onMyChatRenameTap: () {},
                          onMyChatEditDescriptionTap: () {},
                          onDetailTap: () {},
                          onMyChatDeleteTap: () {},
                        );
                      },
                      childCount: _myChatCount, // 表示する数（独自変数）
                    ),
                  ),

                  // 3. 一番下に「島」の分だけの余白を作る（スクロールしきれるように）
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ★ 4. タップ検知と再描画を行うヘルパー関数
  Widget _buildSortTab(int index, String label) {
    // 今このボタンが選ばれているかどうか
    final bool isActive = _selectedSortIndex == index;

    return Expanded(
      child: GestureDetector(
        // タップされたら index を更新して setState！
        onTap: () {
          setState(() {
            _selectedSortIndex = index;
          });
          // ここで「サーバーにデータを再リクエスト」する関数を呼ぶのがマクロ視点の正解
          print("$label が選択されました");
        },
        child: AnimatedContainer(
          // AnimatedContainer にすると、色の変化が 0.2秒かけて「ヌルッ」と動く
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  )
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

/// 1つのチャットグループを表示するカードWidget
class MyChatCard extends StatelessWidget {
  // チャットグループ名
  final dynamic myChatTitle;

  // 親コミットID
  final String parentCommitId;

  // 親コミットタイトル
  final String parentCommitTitle;

  // 経過時間表示
  final String elapsed;

  // 各種操作時のコールバック
  final VoidCallback? onMyChatCardTap;
  final VoidCallback? onMyChatRenameTap;
  final VoidCallback? onMyChatEditDescriptionTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onMyChatDeleteTap;

  // コンストラクタ
  const MyChatCard({
    super.key,
    required this.myChatTitle,
    required this.parentCommitId,
    required this.parentCommitTitle,
    required this.elapsed,
    required this.onMyChatCardTap,
    required this.onMyChatRenameTap,
    required this.onMyChatEditDescriptionTap,
    required this.onDetailTap,
    required this.onMyChatDeleteTap,
  });

  /// カードUIの構築
  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(151, 0, 0, 0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(46)),

      // タップ可能にするためInkWellで包む
      child: InkWell(
        onTap: onMyChatCardTap,
        borderRadius: BorderRadius.circular(12),

        // 内側の余白
        child: Padding(
          padding: const EdgeInsets.all(16.0),

          // 縦方向に並べる
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上段（アイコン＋テキスト）
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // チャットグループを表すアイコン
                  FaIcon(
                    FontAwesomeIcons.commentDots,
                    size: 30,
                    color: const Color.fromARGB(255, 255, 255, 255),
                  ),
                  const SizedBox(width: 16),

                  // テキスト部分を広げる
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // チャットグループ名
                        Text(
                          myChatTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // 親コミットID
                        Text(
                          '派生元コミットID:$parentCommitId',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 親コミットタイトル
                        Text(
                          '派生元コミットタイトル: $parentCommitTitle',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // 更新時間
                        Text(
                          '更新日時: $elapsed',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                ],
              ),

              // 右下のメニュー部分
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 三点リーダーのポップアップメニュー
                  PopupMenuButton(
                    color: const Color.fromARGB(162, 255, 255, 255),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 8,

                    // 選択されたメニューに応じた処理
                    onSelected: (String result) {
                      switch (result) {
                        case 'rename':
                          onMyChatRenameTap!();
                          break;
                        case 'edit_description':
                          onMyChatEditDescriptionTap!();
                          break;
                        case 'detail':
                          onDetailTap!();
                          break;
                        case 'delete':
                          onMyChatDeleteTap!();
                          break;
                      }
                    },

                    // メニュー項目の定義
                    itemBuilder: (BuildContext content) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.drive_file_rename_outline),
                                Text(
                                  '名前の変更',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuItem<String>(
                            value: 'edit_description',
                            child: Row(
                              children: [
                                Icon(Icons.edit_note),
                                Text(
                                  '説明の編集',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuItem<String>(
                            value: 'detail',
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded),
                                Text(
                                  'チャットグループの詳細',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuDivider(),

                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_outlined,
                                  color: Colors.red,
                                ),
                                Text(
                                  '削除',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
