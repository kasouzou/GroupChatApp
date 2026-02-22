class ApiConfig {
  // 実運用では --dart-define=CHAT_API_BASE_URL=https://api.example.com で上書きする。
  static const String baseUrl = String.fromEnvironment(
    'CHAT_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
