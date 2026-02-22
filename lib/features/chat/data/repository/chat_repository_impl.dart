import 'dart:async';
import 'dart:developer' as developer;

import 'package:group_chat_app/features/chat/data/datasource/local/chat_local_datasource_impl.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_datasource.dart';
import 'package:group_chat_app/features/chat/data/datasource/remote/chat_remote_payloads.dart';
import 'package:group_chat_app/features/chat/domain/chat_repository.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_group_summary.dart';
import 'package:group_chat_app/features/chat/domain/entities/chat_message_model.dart';
import 'package:group_chat_app/features/chat/domain/entities/message_content.dart';
import 'package:group_chat_app/features/chat/domain/entities/send_message_response.dart';

/// ChatRepository の実装。
/// 役割:
/// 1) LocalキャッシュとRemoteデータの統合
/// 2) UI向けStream(一覧/メッセージ)の配信
/// 3) 送信時のRemote委譲
///
/// データフロー（起動時）:
/// - _startHydrationIfNeeded()
///   -> local.getAllMessages() で即時表示可能なキャッシュを復元
///   -> remote.fetchMyChats() でグループ一覧を同期
///   -> groupごとに remote.fetchMessages() で本文同期
///   -> StreamController へ通知してUI更新
///
/// データフロー（送信時）:
/// - saveMessage() でローカル即時反映（楽観的UI）
/// - sendMessage() でサーバー確定値を取得
/// - 確定値を再保存して表示を整合させる
class ChatRepositoryImpl implements ChatRepository {
  final ChatLocalDataSourceImpl? local;
  final ChatRemoteDataSource remote;
  final String currentUserId;

  final _messagesByGroup = <String, List<ChatMessageModel>>{};
  final _watchControllers =
      <String, StreamController<List<ChatMessageModel>>>{};
  final _myChatsController =
      StreamController<List<ChatGroupSummary>>.broadcast();
  final _groupNamesById = <String, String>{};
  final _remoteSummaryByGroup = <String, ChatGroupSummary>{};

  StreamSubscription<ChatMessageModel>? _localSubscription;
  Future<void>? _hydrateFuture;
  Timer? _myChatsPollingTimer;
  final _groupPollingTimers = <String, Timer>{};

  static const _myChatsPollingInterval = Duration(seconds: 5);
  static const _messagesPollingInterval = Duration(seconds: 3);

  ChatRepositoryImpl({
    required this.remote,
    required this.currentUserId,
    this.local,
  }) {
    // 初回のみ: local + remote から初期データを構築する。
    _startHydrationIfNeeded();
    // localへの新規保存イベントを購読し、UIへ増分反映する。
    _localSubscription = local?.watchMessages().listen(_upsertAndBroadcast);
  }

  @override
  Future<void> saveMessage(ChatMessageModel message) async {
    _upsertAndBroadcast(message);
    if (local != null) {
      await local!.saveMessage(message);
    }
  }

  @override
  Stream<List<ChatMessageModel>> watchMessages(String groupId) {
    final controller = _watchControllers.putIfAbsent(
      groupId,
      () => StreamController<List<ChatMessageModel>>.broadcast(),
    );

    _messagesByGroup.putIfAbsent(groupId, () => <ChatMessageModel>[]);
    _ensureGroupMetadata(groupId);
    _startHydrationIfNeeded();
    _startGroupPollingIfNeeded(groupId);

    Timer.run(() {
      final snapshot = _messagesByGroup[groupId] ?? const <ChatMessageModel>[];
      controller.add(List.unmodifiable(snapshot));
    });

    return controller.stream;
  }

  @override
  Stream<List<ChatGroupSummary>> watchMyChats() {
    _startHydrationIfNeeded();
    _startMyChatsPollingIfNeeded();
    Timer.run(_emitChatSummaries);
    return _myChatsController.stream;
  }

  @override
  Future<SendMessageResponse> sendMessage(ChatMessageModel message) async {
    final result = await remote.sendMessage(
      RemoteSendMessageRequest(
        localId: message.localId,
        groupId: message.groupId,
        senderId: message.senderId,
        role: message.role,
        content: message.content,
        createdAt: message.createdAt,
      ),
    );

    return SendMessageResponse(
      serverId: result.serverId,
      serverSentAtMs: result.serverSentAtMs,
    );
  }

  Future<void> dispose() async {
    // Provider破棄時にタイマー・購読・ストリームを確実に解放する。
    await _localSubscription?.cancel();
    _myChatsPollingTimer?.cancel();
    for (final timer in _groupPollingTimers.values) {
      timer.cancel();
    }
    for (final controller in _watchControllers.values) {
      await controller.close();
    }
    await _myChatsController.close();
  }

  void _upsertAndBroadcast(ChatMessageModel message) {
    // 同一メッセージ判定:
    // - localId一致（ローカル生成ID）
    // - serverId一致（サーバー確定ID）
    // のどちらかで同一とみなす。
    final messages = _messagesByGroup.putIfAbsent(
      message.groupId,
      () => <ChatMessageModel>[],
    );
    _ensureGroupMetadata(message.groupId);

    final index = messages.indexWhere((m) {
      if (m.localId == message.localId) return true;
      return m.serverId != null &&
          message.serverId != null &&
          m.serverId == message.serverId;
    });

    if (index >= 0) {
      messages[index] = message;
    } else {
      messages.add(message);
    }

    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final controller = _watchControllers[message.groupId];
    if (controller != null && !controller.isClosed) {
      controller.add(List.unmodifiable(messages));
    }

    _emitChatSummaries();
  }

  void _startHydrationIfNeeded() {
    _hydrateFuture ??= _hydrateFromSources();
  }

  Future<void> _hydrateFromSources() async {
    try {
      if (local != null) {
        // 1) ローカルキャッシュを先に読み込む（起動直後の表示を速くする）。
        final localMessages = await local!.getAllMessages();
        for (final message in localMessages) {
          final messages = _messagesByGroup.putIfAbsent(
            message.groupId,
            () => <ChatMessageModel>[],
          );
          messages.add(message);
          _ensureGroupMetadata(message.groupId);
        }
        for (final messages in _messagesByGroup.values) {
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
      }

      // 2) リモート最新値で上書き同期する。
      await _syncMyChatsFromRemote();
      await Future.wait(_messagesByGroup.keys.map(_syncMessagesFromRemote));

      _broadcastAllGroups();
      _emitChatSummaries();
    } catch (e, st) {
      // 起動時同期で一部失敗してもUIを止めない（可用性優先）。
      developer.log('chat hydrate failed', error: e, stackTrace: st);
      _broadcastAllGroups();
      _emitChatSummaries();
    }
  }

  void _startMyChatsPollingIfNeeded() {
    if (_myChatsPollingTimer != null) return;

    // 一覧は一定間隔でリフレッシュ。
    _myChatsPollingTimer = Timer.periodic(_myChatsPollingInterval, (_) async {
      await _syncMyChatsFromRemote();
    });
  }

  void _startGroupPollingIfNeeded(String groupId) {
    if (_groupPollingTimers.containsKey(groupId)) return;

    // 各グループメッセージをポーリングで同期（将来はWebSocket化を想定）。
    final timer = Timer.periodic(_messagesPollingInterval, (_) async {
      await _syncMessagesFromRemote(groupId);
    });
    _groupPollingTimers[groupId] = timer;

    unawaited(_syncMessagesFromRemote(groupId));
  }

  Future<void> _syncMyChatsFromRemote() async {
    try {
      final remoteGroups = await remote.fetchMyChats(currentUserId);
      final summaries = remoteGroups
          .map(ChatRemoteMapper.toGroupSummary)
          .toList();

      // 最新サマリーを丸ごと差し替え（SSOTはRemote）。
      _remoteSummaryByGroup
        ..clear()
        ..addEntries(summaries.map((s) => MapEntry(s.groupId, s)));

      for (final summary in summaries) {
        _groupNamesById[summary.groupId] = summary.groupName;
        _messagesByGroup.putIfAbsent(
          summary.groupId,
          () => <ChatMessageModel>[],
        );
      }

      _emitChatSummaries();
    } catch (e, st) {
      // 一覧同期失敗時は直前状態を維持しつつログのみ残す。
      developer.log('sync my chats failed', error: e, stackTrace: st);
    }
  }

  Future<void> _syncMessagesFromRemote(String groupId) async {
    try {
      final remoteMessages = await remote.fetchMessages(groupId);
      final mapped = remoteMessages.map(ChatRemoteMapper.toMessage).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // 競合回避のため現状はRemote優先で置き換える。
      _messagesByGroup[groupId] = mapped;
      _ensureGroupMetadata(groupId);

      final controller = _watchControllers[groupId];
      if (controller != null && !controller.isClosed) {
        controller.add(List.unmodifiable(mapped));
      }

      _emitChatSummaries();
    } catch (e, st) {
      developer.log(
        'sync messages failed group=$groupId',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _broadcastAllGroups() {
    for (final entry in _watchControllers.entries) {
      final controller = entry.value;
      if (controller.isClosed) continue;
      final messages =
          _messagesByGroup[entry.key] ?? const <ChatMessageModel>[];
      controller.add(List.unmodifiable(messages));
    }
  }

  void _ensureGroupMetadata(String groupId) {
    _groupNamesById.putIfAbsent(groupId, () => 'グループ $groupId');
  }

  void _emitChatSummaries() {
    if (_myChatsController.isClosed) return;
    _myChatsController.add(List.unmodifiable(_buildChatSummaries()));
  }

  List<ChatGroupSummary> _buildChatSummaries() {
    final summaries = <ChatGroupSummary>[];
    final allGroupIds = <String>{
      ..._messagesByGroup.keys,
      ..._remoteSummaryByGroup.keys,
    };

    for (final groupId in allGroupIds) {
      final remoteSummary = _remoteSummaryByGroup[groupId];
      final messages = _messagesByGroup[groupId] ?? const <ChatMessageModel>[];
      final latest = messages.isNotEmpty ? messages.last : null;

      summaries.add(
        ChatGroupSummary(
          groupId: groupId,
          groupName:
              remoteSummary?.groupName ??
              _groupNamesById[groupId] ??
              'グループ $groupId',
          lastMessagePreview:
              remoteSummary?.lastMessagePreview ??
              (latest != null ? _messagePreview(latest.content) : ''),
          lastMessageAt: remoteSummary?.lastMessageAt ?? latest?.createdAt ?? 0,
          unreadCount: remoteSummary?.unreadCount ?? 0,
          memberCount: remoteSummary?.memberCount ?? 1,
        ),
      );
    }

    summaries.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return summaries;
  }

  String _messagePreview(MessageContent content) {
    return switch (content) {
      TextContent(:final text) => text,
      ImageContent(:final fileName) => '[画像] $fileName',
    };
  }
}
