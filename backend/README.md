# Chat Backend (Nginx + FastAPI + PostgreSQL)

## 構成
- `nginx` : 80番で受けて FastAPI へプロキシ
- `fastapi` : チャットAPI本体
- `postgres` : 永続データストア

## 起動
```bash
docker compose up -d --build
```

起動後:
- API ベースURL: `http://localhost:8080`
- ヘルスチェック: `GET http://localhost:8080/health`

## Flutter接続
Flutter起動時にAPI URLとユーザーIDを指定:
```bash
flutter run \
  --dart-define=CHAT_API_BASE_URL=http://localhost:8080 \
  --dart-define=CHAT_USER_ID=user-001
```

## エンドポイント
- `GET /api/v1/users/{user_id}/groups`
  - ユーザー所属グループ一覧
- `GET /api/v1/groups/{group_id}/messages`
  - グループメッセージ一覧
- `POST /api/v1/messages`
  - メッセージ送信

## レスポンス方針
- Flutterの `ChatRemoteDataSourceImpl` が期待するJSON形式に合わせています。
- `created_at_ms` はサーバー確定時刻（UTC epoch ms）です。

## 備考
- 現在はアプリ起動時に最小限のグループ/メンバーをシードします。
- 本番では認証（JWT等）と権限チェックを追加してください。
