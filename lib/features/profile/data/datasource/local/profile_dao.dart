import 'package:group_chat_app/core/database/sqlite_manager.dart';
import 'package:group_chat_app/core/models/user_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite/sqflite.dart';

part 'profile_dao.g.dart';

// Riverpod should write out of the class.
@riverpod
Future<ProfileDao> profileDao(ProfileDaoRef ref) async {
  final db = await ref.watch(sqliteManagerProvider.future);
  return ProfileDao(db);
}

class ProfileDao {
  final Database _db;
  ProfileDao(this._db);

  /// 💡 ユーザーの保存または更新 (Upsert)
  Future<void> updateUser(UserModel user) async {
    await _db.insert(
      'user',
      _toMap(user),
      conflictAlgorithm: ConflictAlgorithm.replace, // 既にあれば上書き
    );
  }

  /// 💡 ID指定でユーザーを取得
  Future<UserModel?> getUser(String userId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;
    return _fromMap(maps.first);
  }

  /// 💡 同期ステータスのみを更新（VPS送信成功時などに使用）
  Future<void> updateSyncStatus(String userId, int status) async {
    await _db.update(
      'user',
      {'sync_status': status},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// 💡 マッピング処理（Model -> Map）
  Map<String, dynamic> _toMap(UserModel user) {
    return {
      'id': user.id,
      'display_name': user.displayName,
      'photo_url': user.photoUrl,
      'created_at': user.createdAt.toIso8601String(),
      // syncStatus などのフィールドが UserModel にある場合はここに追加
      'sync_status': 0, 
    };
  }

  /// 💡 マッピング処理（Map -> Model）
  UserModel _fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      displayName: map['display_name'] as String,
      photoUrl: map['photo_url'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}