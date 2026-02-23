// グループ招待コード発行時の情報を表すエンティティ
/// 招待コード発行結果。
class GroupInviteInfo {
  // 対象グループのID
  final String groupId;
  // 発行された招待コード（短い識別子）
  final String inviteCode;
  // 招待にアクセスするためのURL（QRなどで共有する想定）
  final String inviteUrl;
  // 招待コードの有効期限日時
  final DateTime expiresAt;

  // コンストラクタ（全フィールド必須）
  const GroupInviteInfo({
    required this.groupId,
    required this.inviteCode,
    required this.inviteUrl,
    required this.expiresAt,
  });
}
