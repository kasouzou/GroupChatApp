class ApiConfig {
  // Flutter 側のAPI接続先。
  // ローカル開発: デフォルト値(http://localhost:8080)
  // 本番運用: --dart-define=CHAT_API_BASE_URL=https://your-domain を指定して上書きする。
  static const String baseUrl = String.fromEnvironment(
    'CHAT_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
