import 'package:flutter/material.dart';

/// ユーザー情報を管理するエンティティクラス
@immutable // このクラスのインスタンスは作成後に変更されないことを保証する
class UserModel {
  // 1. 基本データフィールド
  final String id;           // Google UIDなどの一意の識別子
  final String displayName;  // 表示名
  final String photoUrl;     // アイコン画像のURL
  final String role;         // 役割: "leader" または "member"
  final DateTime createdAt;  // 作成日時

  const UserModel({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.createdAt,
  });

  // --- 便利機能（ヘルパーメソッド） ---

  // 💡 ツッコミ！: 権限チェックを文字列比較で何度も書くのは非効率。
  // こうやって getter を作っておけば、将来役割が増えてもここを直すだけで済む（疎結合！）
  bool get isLeader => role == 'leader';
  bool get isMember => role == 'member';

  // --- シリアライズ（DBとのやり取り用） ---

  /// Map（JSON）から UserModel を作成する「工場」メソッド
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      displayName: map['display_name'] ?? 'ゲスト',
      photoUrl: map['photo_url'] ?? '',
      role: map['role'] ?? 'member', // デフォルトはメンバーにしておくと安全
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  /// UserModel を Map（JSON）に変換するメソッド（DB保存用）
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'display_name': displayName,
      'photo_url': photoUrl,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // 💡 ツッコミ！: 前に話した「一部分だけ変えた新しいモデル」を作るためのメソッド
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? role,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }

  // UserModel.empty() と呼んだ瞬間に、IDも名前も空っぽの「仮のユーザー」を生成し、
  // ProfileNotifierがエラーを出さずに「とりあえず空のデータで画面を準備しておくか」と納得させるためのファクトリーメソッド。
  factory UserModel.empty() {
    return UserModel(
      id: '',
      displayName: '',
      photoUrl: '',
      role: 'member',
      createdAt: DateTime.now(),  
    );
  }
}