import 'dart:async';

import 'package:group_chat_app/features/chat/data/datasource/local/chat_local_datasource_impl.dart';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_group_summary.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_status.dart';
import 'package:group_chat_app/features/chat/domain/entities/send_message_response.dart';
import 'package:uuid/uuid.dart';

class ChatRepositoryImpl implements ChatRepository {
  // ローカル保存の実体。未接続でも動かせるよう nullable にしている。
  final ChatLocalDataSourceImpl? local;
  // 疑似サーバーIDを作るための UUID 生成器。
  final _uuid = const Uuid();
  // グループごとのメッセージ一覧をメモリ保持する簡易ストア。
  final _messagesByGroup = <String, List<ChatMessageModel>>{};
  // グループごとの購読ストリーム。（GroupIdごとにストリーム本体があり、そのストリーム本体にはリスト形式のChatMessageModel型のデータが流れている）
  final _watchControllers = <String, StreamController<List<ChatMessageModel>>>{};

  // 一覧画面向けのサマリー配信ストリーム
  final _myChatsController = StreamController<List<ChatGroupSummary>>.broadcast();
  // groupId と UI 表示名の対応（将来は API/DB から取得する）
  final _groupNamesById = <String, String>{
    'family_group_001': '家族グループ',
    'friends_group_001': '友だちグループ',
    'project_group_001': 'プロジェクトA',
  };

  // local の更新通知を受け取る購読。
  StreamSubscription<ChatMessageModel>? _localSubscription;
  // 初回のローカルキャッシュ取り込み（1回だけ実行）
  Future<void>? _hydrateFuture;

  ChatRepositoryImpl({this.local}) {
    _startHydrationIfNeeded();
    // local 側で保存されたメッセージを repository 側のメモリにも反映する。
    _localSubscription = local?.watchMessages().listen(_upsertAndBroadcast);
  }

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    // 先にメモリへ反映して UI を即更新（楽観的更新）。
    _upsertAndBroadcast(message);
    if (local != null) {
      // local があれば永続化も実行。
      await local!.saveMessage(message);
    }
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages(String groupId) {
    // グループ単位でストリームを使い分ける。
    final controller = _watchControllers.putIfAbsent(
      groupId,
      () => StreamController<List<ChatMessageModel>>.broadcast(),
    );

    // 初回監視時に空箱だけ作成。中身は初期ハイドレーション/増分で埋まる。
    _messagesByGroup.putIfAbsent(groupId, () => <ChatMessageModel>[]);
    _ensureGroupMetadata(groupId);
    _startHydrationIfNeeded();
    // リスナー接続完了後に現在値を流す。
    Timer.run(() => controller.add(List.unmodifiable(_messagesByGroup[groupId]!)));
    return controller.stream;
  }

  @override
  Stream<List<ChatGroupSummary>> watchMyChats() {
    _startHydrationIfNeeded();
    // 監視開始直後に最新サマリーを即配信。
    Timer.run(_emitChatSummaries);
    return _myChatsController.stream;
  }

  @override
  Future<SendMessageResponse> sendMessage(ChatMessageModel message) async {
    // ここは疑似リモート送信。実通信の代わりに遅延だけ入れる。
    await Future.delayed(const Duration(milliseconds: 150));
    return SendMessageResponse(
      // サーバー採番IDとサーバー時刻を返す想定。
      serverId: _uuid.v4(),
      serverSentAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> dispose() async {
    // 購読とストリームを閉じてリソースリークを防ぐ。
    await _localSubscription?.cancel();
    for (final controller in _watchControllers.values) {
      await controller.close();
    }
    await _myChatsController.close();
  }

  void _upsertAndBroadcast(ChatMessageModel message) {
    // localId をキーに「更新 or 追加」を行う。
    // 意味: 「もし message.groupId という部屋が Map の中になかったら、
    // 右側の関数 () => <ChatMessageModel>[] を実行して新しい空のリストをその部屋に作れ。
    // あったら、そのままその部屋のリストを返せ。何もしない。」
    // コードの全行解説は→https://www.notion.so/2026-1-28-2f68b8225642805a9a82c15189ab7826?source=copy_link#3038b822564280838bb9d138e5172b66
    final messages = _messagesByGroup.putIfAbsent(message.groupId, () => <ChatMessageModel>[]);
    _ensureGroupMetadata(message.groupId);
    final index = messages.indexWhere((m) => m.localId == message.localId);
    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }

    // 表示順を安定させるため作成時刻でソート。
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final controller = _watchControllers[message.groupId];
    if (controller != null && !controller.isClosed) {
      // 外部から不意に変更されないよう unmodifiable で通知。
      controller.add(List.unmodifiable(messages));
    }

    _emitChatSummaries();
  }

  List<ChatMessageModel> _mockInitialMessages(String groupId) {
    // 監視開始時の初期表示用ダミーメッセージ。
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      ChatMessageModel(
        localId: 'mock-$groupId-1',
        groupId: groupId,
        senderId: 'system',
        serverId: 'server-mock-$groupId-1',
        role: 'member',
        status: MessageStatus.sent,
        content: TextContent('Welcome to the chat'),
        createdAt: now - 60000,
      ),
      ChatMessageModel(
        localId: 'mock-$groupId-2',
        groupId: groupId,
        senderId: 'system',
        serverId: 'server-mock-$groupId-2',
        role: 'member',
        status: MessageStatus.sent,
        content: TextContent('This is mock history data'),
        createdAt: now - 30000,
      ),
    ];
  }

  void _seedMockGroups() {
    // 将来はAPI/DB取得に置き換える想定の初期データ。
    if (_messagesByGroup.isNotEmpty) return;

    for (final groupId in _groupNamesById.keys) {
      _messagesByGroup[groupId] = _mockInitialMessages(groupId);
    }
  }

  void _ensureGroupMetadata(String groupId) {
    // groupName未登録でもUIが壊れないようフォールバック名を補完。
    _groupNamesById.putIfAbsent(groupId, () => 'グループ $groupId');
  }

  void _emitChatSummaries() {
    if (_myChatsController.isClosed) return;
    // 不変リストで公開し、外部からの破壊的変更を防ぐ。
    _myChatsController.add(List.unmodifiable(_buildChatSummaries()));
  }

  List<ChatGroupSummary> _buildChatSummaries() {
    // Message集合から一覧表示用のSummaryへ射影する。
    final summaries = <ChatGroupSummary>[];

    for (final entry in _messagesByGroup.entries) {
      final groupId = entry.key;
      final messages = entry.value;
      if (messages.isEmpty) continue;

      final latest = messages.last;
      summaries.add(
        ChatGroupSummary(
          groupId: groupId,
          groupName: _groupNamesById[groupId] ?? 'グループ $groupId',
          lastMessagePreview: _messagePreview(latest.content),
          lastMessageAt: latest.createdAt,
          unreadCount: messages.where((m) => m.status != MessageStatus.sent).length,
          memberCount: _mockMemberCount(groupId),
        ),
      );
    }

    summaries.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return summaries;
  }

  int _mockMemberCount(String groupId) {
    // 表示用の仮ロジック。将来はグループメンバー情報から算出する。
    if (groupId.startsWith('family')) return 5;
    if (groupId.startsWith('friends')) return 8;
    if (groupId.startsWith('project')) return 6;
    return 3;
  }

  String _messagePreview(MessageContent content) {
    return switch (content) {
      TextContent(:final text) => text,
      ImageContent(:final fileName) => '[画像] $fileName',
    };
  }

  void _startHydrationIfNeeded() {
    _hydrateFuture ??= _hydrateFromLocalCache();
  }

  Future<void> _hydrateFromLocalCache() async {
    // 将来は remote endpoint からの初期同期もここに統合する。
    if (local == null) {
      _seedMockGroups();
      _emitChatSummaries();
      _broadcastAllGroups();
      return;
    }

    final localMessages = await local!.getAllMessages();
    if (localMessages.isEmpty) {
      // 開発中はデータ0件時にモックでUI確認可能にする。
      _seedMockGroups();
      _emitChatSummaries();
      _broadcastAllGroups();
      return;
    }

    _messagesByGroup.clear();
    for (final message in localMessages) {
      final bucket = _messagesByGroup.putIfAbsent(
        message.groupId,
        () => <ChatMessageModel>[],
      );
      bucket.add(message);
      _ensureGroupMetadata(message.groupId);
    }

    for (final messages in _messagesByGroup.values) {
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    _emitChatSummaries();
    _broadcastAllGroups();
  }

  void _broadcastAllGroups() {
    for (final entry in _watchControllers.entries) {
      final controller = entry.value;
      if (controller.isClosed) continue;
      final messages = _messagesByGroup[entry.key] ?? const <ChatMessageModel>[];
      controller.add(List.unmodifiable(messages));
    }
  }
}
