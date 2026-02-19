// チャット専用の操作部品:DAO(Data Access Object)
// 「疎結合」にするために、DB全体ではなく「チャットメッセージのSQLiteデータベース」を扱う専用のクラスを切り出す.
// SqliteManager で作成された 'chat_messages' テーブルを操作するぜ！

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:group_chat_app/core/database/sqlite_manager.dart';

part 'chat_dao.g.dart';

// Riverpod should write out of the class.
@riverpod
Future<ChatDao> chatDao(ChatDaoRef ref) async {
  final db = await ref.watch(sqliteManagerProvider.future);
  return ChatDao(db);
}

class ChatDao {
  final Database _db;
  ChatDao(this._db);

  // 💡 1. ローカルに保存（真実の入り口）
  // SqliteManager の onCreate で定義した chat_messages テーブルにデータを突っ込む。
  // sync_status はデフォルトで 0 (未送信) になる設定だ。
  Future<int> insertMessage(Map<String, dynamic> row) async {
    return await _db.insert('chat_messages', row);
  }

  // 💡 2. 未送信メッセージだけを救出
  // ユーザーが「再送ボタン」を押した時や、UIで「未送信」アイコンを出すために使う。
  // 勝手にバックグラウンドでVPSに送信はしない方針なので、主に表示や手動リトライ用だな。
  Future<List<Map<String, dynamic>>> getUnsentMessages() async {
    return await _db.query(
      'chat_messages',
      where: 'sync_status = ?',
      whereArgs: [0], // 0: 未送信
      orderBy: 'created_at ASC', // 古い順に取得して送信順序を守るぜ
    );
  }

  // 💡 3. 同期成功後にステータスを更新
  // サーバーから発行された UUID (id) を保存し、sync_status を 1 (送信済) に書き換える。
  Future<void> updateSyncStatus(int localId, String serverId) async {
    await _db.update(
      'chat_messages',
      {
        'id': serverId,          // サーバー側のUUID（テーブル定義の id カラム）
        'sync_status': 1,        // 1: 送信済
      },
      where: 'local_id = ?',    // 自動採番された local_id をキーに更新
      whereArgs: [localId],
    );
  }

  // 💡 4. 送信失敗を明示的にマークする場合（オプション）
  // もし「単なる未送信(0)」と「エラーで止まった状態」を分けたいならここを使う。
  // 今の方針なら 0 のままでも十分制御できるけどな！
  Future<void> markAsFailed(int localId) async {
    await _db.update(
      'chat_messages',
      {'sync_status': 0}, 
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }
}
