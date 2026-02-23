import 'dart:convert';

import 'package:group_chat_app/core/error/app_exception.dart';
import 'package:http/http.dart' as http;

/// FastAPI標準エラーフォーマットをFlutter側の例外へ変換する。
AppException toAppException(
  http.Response response, {
  required String endpoint,
}) {
  String message = 'Request failed (${response.statusCode})';

  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        message = (error['message'] as String?) ?? message;
      } else if (decoded['detail'] is String) {
        message = decoded['detail'] as String;
      }
    }
  } catch (_) {
    // ignore parse error
  }

  return AppException(
    '$message (status=${response.statusCode}, endpoint=$endpoint)',
    cause: response.body,
  );
}
