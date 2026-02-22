// JSON形式の文字列をDart オブジェクトにデコードするためのインポート
import 'dart:convert';

// ユーザーモデルをインポート（APIレスポンスをこのモデルに変換）
import 'package:group_chat_app/core/models/user_model.dart';
// API の基本URL やエンドポイント情報を含むの設定ファイルをインポート
import 'package:group_chat_app/core/network/api_config.dart';
// AuthRemoteDataSource インターフェースをインポート（このクラスが実装する）
import 'package:group_chat_app/features/auth/data/datasource/remote/auth_remote_datasource.dart';
// HTTP通信用のClientをインポート（エイリアス 'http' として利用）
import 'package:http/http.dart' as http;

/// FastAPI の /api/v1/auth/google-login エンドポイントと通信するリモートデータソース実装。
/// Google認証後のトークン情報をバックエンドに送信してユーザー情報を取得する役割を担う。
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // HTTP通信を行うClientインスタンスを保持（DIで注入される）
  // プライベート（_）なので外部からは直接アクセスできない
  final http.Client _client;

  // コンストラクタ：HTTPクライアントをDIで受け取り、フィールドに保存する
  AuthRemoteDataSourceImpl(this._client);

  // インターフェースで定義されたメソッドをオーバーライド
  @override
  // 非同期処理（APIサーバーとの通信）で、最終的にUserModel を返す
  Future<UserModel> loginWithGoogleToken({
    // Google認証でのユーザーID
    required String id,
    // Google認証でのユーザー表示名
    required String displayName,
    // Google認証でのユーザープロフィール画像URL
    required String photoUrl,
  }) async {
    // ApiConfig.baseUrl（例：http://localhost:8000）とエンドポイントを組み合わせてURI を生成
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/google-login');
    // HTTPの POST リクエストを送信（Google認証情報をJSONボディに含める）
    final response = await _client.post(
      // リクエスト先のURI
      uri,
      // リクエストヘッダー：Content-Type を JSON として指定
      headers: const {'Content-Type': 'application/json'},
      // リクエストボディ：Google認証情報を JSON エンコードして送信
      body: jsonEncode({
        // Google の一意のユーザーID
        'id': id,
        // ユーザーの表示名
        'display_name': displayName,
        // ユーザーのプロフィール写真URL
        'photo_url': photoUrl,
      }),
    );

    // ステータスコードをチェック：200-299 は成功、それ以外はエラー
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // 失敗時は詳細情報とともに例外をスロー
      throw Exception(
        'Auth API failed: status=${response.statusCode} body=${response.body}',
      );
    }

    // レスポンスボディの JSON 文字列をDart のMap に変換
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    // レスポンスの Map からUserModel を生成して返す
    // fromMap コンストラクタでJSON をユーザーモデルに変換
    return UserModel.fromMap(body);
  }
}
