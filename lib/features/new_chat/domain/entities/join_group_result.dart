// 招待コードでグループ参加したときの結果を表すエンティティ
/// 招待コードによる参加結果。
class JoinGroupResult {
  // 参加したグループのID
  final String groupId;
  // 参加したグループの表示名
  final String groupName;
  // 参加が成功したかどうかを示すフラグ
  final bool joined;

  // コンストラクタ（不変オブジェクトとして定義）
  const JoinGroupResult({
    // グループIDを必須とする
    required this.groupId,
    // グループ名を必須とする
    required this.groupName,
    // 参加結果フラグを必須とする
    required this.joined,
  });
}
