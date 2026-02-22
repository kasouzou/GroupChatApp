import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:group_chat_app/features/chat/di/fetch_my_chats_usecase_provider.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_group_summary.dart';
import 'package:group_chat_app/features/chat/presentation/pages/chat_page.dart';

/// 自分が参加しているチャット一覧画面。
///
/// 概要:
/// - UseCase の `watchMyChats()` でチャット一覧ストリームを購読して UI を描画する。
/// - 検索 / ソートは画面側で行い、カードタップで `ChatPage` へ `groupId` と
///   `groupName` を渡して遷移する。
///
/// 重要な責務の分離:
/// - UseCase: データ取得 (DI 経由で注入される `fetchMyChatsUseCaseProvider`)
/// - View: 検索・ソート・カード描画・画面遷移のみ担当
class MyChatsPage extends ConsumerStatefulWidget {
  const MyChatsPage({super.key});

  @override
  ConsumerState<MyChatsPage> createState() => _MyChatsPageState();
}

class _MyChatsPageState extends ConsumerState<MyChatsPage> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedSortIndex = 0;

  // `_searchController` は画面上の検索バー内のテキストを保持する。
  // `_selectedSortIndex` は表示順序(未読順/最新順/人気順)を保持する。

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UseCase から一覧ストリームを購読し、UIは描画責務だけを持つ。
    final useCase = ref.watch(fetchMyChatsUseCaseProvider);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/image/back2.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            // StreamBuilder は UseCase が返すチャット一覧ストリームを購読する。
            // snapshot.data は `List<ChatGroupSummary>` を期待する。
            child: StreamBuilder<List<ChatGroupSummary>>(
              stream: useCase.watchMyChats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // ストリームから受け取った生データに対して
                // 検索・ソート処理を適用して表示用リストを作る。
                final chats = _applySearchAndSort(snapshot.data ?? const []);

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          SearchBar(
                            controller: _searchController,
                            hintText: 'グループ名 / GroupId で検索',
                            leading: const Icon(Icons.search),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildSortTab(0, '未読順'),
                                _buildSortTab(1, '最新順'),
                                _buildSortTab(2, '人気順'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    if (chats.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              '表示できるチャットがありません',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          // 各要素は `ChatGroupSummary` から取り出す。
                          final chat = chats[index];
                          return MyChatCard(
                            groupName: chat.groupName,
                            groupId: chat.groupId,
                            lastMessagePreview: chat.lastMessagePreview,
                            // 相対時刻を表示用に整形して渡す
                            elapsed: _formatElapsed(chat.lastMessageAt),
                            memberCount: chat.memberCount,
                            unreadCount: chat.unreadCount,
                            // カードタップ時の遷移処理:
                            // `ChatPage` に必要な `groupId` と `groupName` を
                            // 引数として渡して `push` する。
                            onMyChatCardTap: () async {
                              await Navigator.of(
                                context,
                                rootNavigator: true,
                              ).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    groupId: chat.groupId,
                                    groupName: chat.groupName,
                                  ),
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
                        }, childCount: chats.length),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<ChatGroupSummary> _applySearchAndSort(List<ChatGroupSummary> chats) {
    // フィルタ/ソートは画面責務として集約し、カード描画を単純化する。
    final keyword = _searchController.text.trim().toLowerCase();

    final filtered = chats.where((chat) {
      if (keyword.isEmpty) return true;
      return chat.groupName.toLowerCase().contains(keyword) ||
          chat.groupId.toLowerCase().contains(keyword) ||
          chat.lastMessagePreview.toLowerCase().contains(keyword);
    }).toList();

    // 選択されているソートタブに応じてソート順を決める
    switch (_selectedSortIndex) {
      case 0:
        filtered.sort((a, b) {
          final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
          if (unreadCompare != 0) return unreadCompare;
          return b.lastMessageAt.compareTo(a.lastMessageAt);
        });
        break;
      case 1:
        filtered.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        break;
      case 2:
        filtered.sort((a, b) {
          final memberCompare = b.memberCount.compareTo(a.memberCount);
          if (memberCompare != 0) return memberCompare;
          return b.lastMessageAt.compareTo(a.lastMessageAt);
        });
        break;
      default:
        filtered.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
        break;
    }

    return filtered;
  }

  Widget _buildSortTab(int index, String label) {
    final isActive = _selectedSortIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSortIndex = index;
          });
        },
        // タブの見た目をアニメーションで切り替える
        child: AnimatedContainer(
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

  String _formatElapsed(int unixMs) {
    // 一覧の視認性を優先した相対時刻表示。
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffSec = ((now - unixMs) / 1000).floor();

    if (diffSec < 60) return '$diffSec秒前';
    final diffMin = (diffSec / 60).floor();
    if (diffMin < 60) return '$diffMin分前';
    final diffHour = (diffMin / 60).floor();
    if (diffHour < 24) return '$diffHour時間前';
    final diffDay = (diffHour / 24).floor();
    return '$diffDay日前';
  }
}

class MyChatCard extends StatelessWidget {
  final String groupName;
  final String groupId;
  final String lastMessagePreview;
  final String elapsed;
  final int memberCount;
  final int unreadCount;

  final VoidCallback? onMyChatCardTap;
  final VoidCallback? onMyChatRenameTap;
  final VoidCallback? onMyChatEditDescriptionTap;
  final VoidCallback? onDetailTap;
  final VoidCallback? onMyChatDeleteTap;

  const MyChatCard({
    super.key,
    required this.groupName,
    required this.groupId,
    required this.lastMessagePreview,
    required this.elapsed,
    required this.memberCount,
    required this.unreadCount,
    required this.onMyChatCardTap,
    required this.onMyChatRenameTap,
    required this.onMyChatEditDescriptionTap,
    required this.onDetailTap,
    required this.onMyChatDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(151, 0, 0, 0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        onTap: onMyChatCardTap,
        borderRadius: BorderRadius.circular(24),
        // カード全体をタップ可能にして、押下で `onMyChatCardTap` を呼ぶ
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.commentDots,
                    size: 24,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'GroupId: $groupId',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lastMessagePreview,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '更新: $elapsed / 参加者: $memberCount / 未読: $unreadCount',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton(
                    color: const Color.fromARGB(162, 255, 255, 255),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    elevation: 8,
                    onSelected: (String result) {
                      switch (result) {
                        case 'rename':
                          onMyChatRenameTap?.call();
                          break;
                        case 'edit_description':
                          onMyChatEditDescriptionTap?.call();
                          break;
                        case 'detail':
                          onDetailTap?.call();
                          break;
                        case 'delete':
                          onMyChatDeleteTap?.call();
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'rename',
                            child: Row(
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
                                  'チャット詳細',
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
