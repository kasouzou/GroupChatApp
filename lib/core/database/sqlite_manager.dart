// DBとの接続を管理する共通クラスだぜ！必要なテーブルを作成し、そのテーブルインスタンスをリバーポッドで管理する。
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sqlite_manager.g.dart';

@Riverpod(keepAlive: true)
class SqliteManager extends _$SqliteManager {
  @override
  Future<Database> build() async {
    return _initDatabase();
  }
  // chat_messagesテーブルとusersテーブルを持つgroup_chat_app.dbというデータベースを作ってRiverPodでメモリインスタンス（どのクラスからでも呼び出せば参照できる）を作成する。
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    // group_chat_app.db というデータベースを作る
    final path = join(dbPath, 'group_chat_app.db');

    return await openDatabase(
      path,
      version: 2,
      // 💡 監修ツッコミ：テーブル構造を変更した時は version を上げること
      // chat_messages と users テーブルを持つ
      onCreate: (db, version) async {
        // --- 1. チャットメッセージテーブル ---
        // ChatMessageModel の全フィールド + 同期状態を網羅
        await db.execute('''
          CREATE TABLE chat_messages (
            local_id INTEGER PRIMARY KEY AUTOINCREMENT,
            id TEXT UNIQUE,                -- サーバー側のUUID
            group_id TEXT NOT NULL,        -- どの家族か
            sender_id TEXT NOT NULL,       -- 送信者のUID
            role TEXT NOT NULL,            -- 役割(leader/member)
            text TEXT NOT NULL,            -- メッセージ本文
            created_at TEXT NOT NULL,      -- ISO8601 (UTC推奨)
            sync_status INTEGER NOT NULL DEFAULT 0 -- 0:未送信, 1:送信済
          )
        ''');

        // --- 2. ユーザープロフィールテーブル ---
        // UserModel のデータを永続化するためのテーブル
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,           -- Google UID
            display_name TEXT NOT NULL,
            photo_url TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status INTEGER NOT NULL DEFAULT 0 -- 0:未送信, 1:送信済:プロフィールも同期管理が必要なので0とした
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addUpdatedAtColumnIfNeeded(db, 'users');
          // 既存実装で user テーブル名を使っているケースにも対応
          await _addUpdatedAtColumnIfNeeded(db, 'user');
        }
      },
    );
  }

  Future<void> _addUpdatedAtColumnIfNeeded(Database db, String tableName) async {
    final tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    if (tableInfo.isEmpty) return;

    final hasUpdatedAt = tableInfo.any((column) => column['name'] == 'updated_at');
    if (hasUpdatedAt) return;

    await db.execute('ALTER TABLE $tableName ADD COLUMN updated_at TEXT');
    await db.execute(
      'UPDATE $tableName SET updated_at = created_at WHERE updated_at IS NULL',
    );
  }
}
