import 'dart:async';

import 'package:http/http.dart' as http;

/// Authorizationヘッダーを自動付与するHTTPクライアント。
///
/// - ログイン前は tokenProvider が null を返すのでヘッダー未付与。
/// - ログイン後は `Bearer <token>` を付与してAPI認可を通す。
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final FutureOr<String?> Function() _tokenProvider;

  AuthHttpClient({
    required http.Client inner,
    required FutureOr<String?> Function() tokenProvider,
  }) : _inner = inner,
       _tokenProvider = tokenProvider;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _tokenProvider();
    if (token != null && token.trim().isNotEmpty) {
      request.headers.putIfAbsent('Authorization', () => 'Bearer $token');
    }
    request.headers.putIfAbsent('Accept', () => 'application/json');
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
