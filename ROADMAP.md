# GroupChatApp - リリース用AABファイル作成までのロードマップ

**目標**: Google Play Storeにリリース可能なAABファイル（Android App Bundle）の作成

**作成日**: 2026年2月22日  
**更新日**: 2026年2月22日（あなたの疑問に基づいて詳細化）
**想定期間**: 6～8週間（段階的な開発）

---

## 📖 **詳細版ロードマップ（推奨）**

**このファイルが長い場合は、以下の詳細版をお読みください:**

👉 **[DETAILED_ROADMAP.md](DETAILED_ROADMAP.md)** - あなたの質問に基づいた詳細で長いロードマップ

詳細版では以下をカバーしています:
- ✅ あなたの3つの質問への詳細な回答
- ✅ 実装優先順位チャート（何から始めるか）
- ✅ 各フェーズの詳細チェックリスト
- ✅ 実装スケジュール例（6週間）
- ✅ よくある質問 (FAQ)
- ✅ 参考資料・リンク集

---

## 🎯 **あなたの主な質問への直接的な答え**

### Q1: ローカルで実験してからXserverVPS上で構築するのか？

**A: YES。以下の順序が正解です:**

```
Step 1: ローカルで完全検証 (現在ここ)
  ↓
Step 2: VPSにデプロイ して同じ設定を再現
  ↓
Step 3: VPS本番環境で全機能テスト
  ↓
Step 4: フロント側をVPS URLに切り替え
```

**理由**:
- ローカル環境でバグを事前に潰すことが時間短縮の鍵
- VPS側でのデプロイエラーを最小化
- ロールバック対応が簡単

---

### Q2: その前にFirebaseAuthでGoogleログイン周りを固めるのか？

**A: 部分的YES。以下の3段階が理想的です:**

```
段階1: ローカルで Firebase Auth + Google Sign-In 動作確認 (1週間)
  ├─ デバッグ署名 (debug.keystore) で動作確認
  ├─ Firebase console で Auth のテスト
  └─ Flutterアプリ上でログイン/ログアウト成功確認

段階2: バックエンド整備 (1週間)
  ├─ ローカル FastAPI で Google Token 検証ロジック実装
  ├─ `/api/v1/auth/google-login` エンドポイント完成
  └─ ユーザー登録・セッション管理の動作確認

段階3: VPS上で Firebase Auth + API 連携 (1週間)
  ├─ VPS FastAPI を本番 Firebase と連携
  ├─ HTTPS 上での Token 送受信検証
  └─ 本番署名キーでの再テスト
```

**現在の状況から見ると:**
- Google Sign-In の基本実装は完了している（pubspec.yaml から確認）
- local firebase-admin 設定が必要かもしれません

---

### Q3: 色々疑問があり、どこから手を付けるべきなのか？

**A: 以下の優先順位が最適です:**

```
🚨 優先度 = 高
├─ ① Firebase Auth ローカル検証 (3日)
│   └─ デバッグで本当に動くか確認
│
├─ ② ローカルバックエンド PostgreSQL 接続確認 (3日)
│   └─ Docker で DB に実際にデータ保存されるか確認
│
└─ ③ ローカル API ←→ Flutter 完全連携テスト (3日)
    └─ データベースの情報がアプリに表示される確認

💼 優先度 = 中
├─ ④ VPS 構築 + デプロイ (1週間)
├─ ⑤ 本番 Firebase 設定 (3日)
└─ ⑥ HTTPS/SSL (3日)

🎨 優先度 = 低（テスト・リリース）
├─ ⑦ テスト & QA (3日)
├─ ⑧ Play Console 登録 (3日)
└─ ⑨ AAB ビルド & リリース (3日)
```

**理由**: 
- ローカルで完全に動く仕組みが無いと、VPSでも失敗する
- API と DB の連携が失敗すると、フロント側のデバッグが困難になる
- VPSはあくまで「動くものを稼働させる場所」に過ぎない

---

## 📊 **全体像（優先順位順）**

```
フェーズ1: ローカル開発環境の完全検証 (1.5週間) ⭐ START HERE
  ├─ ① Firebase Auth + Google Sign-In デバッグ署名で動作確認
  ├─ ② ローカルDocker バックエンド + PostgreSQL 完全連携テスト
  ├─ ③ ローカルFlutterアプリ ←→ API の データフロー確認
  └─ ④ ローカル環境でのユーザー認証フロー完全テスト

フェーズ2: バックエンド本番化 (2週間)
  ├─ ⑤ XserverVPS上にバックエンド構築（ローカル設定を再現）
  ├─ ⑥ HTTPS/SSL設定 + ドメイン設定
  ├─ ⑦ VPS上の PostgreSQL セットアップ + マイグレーション
  └─ ⑧ VPS API検証（curl でテスト）

フェーズ3: フロント本番化 (1.5週間)
  ├─ ⑨ Firebase 本番プロジェクト設定（リリース署名キー登録）
  ├─ ⑩ APIエンドポイント URL を ローカル → VPS 本番URL に切り替え
  ├─ ⑪ Cloud Storage セットアップ（プロフィール画像保存）
  └─ ⑫ 本番署名キーでのログイン・メッセージ送受信 完全テスト

フェーズ4: テスト + ビルド (1.5週間)
  ├─ ⑬ アプリ全機能の完全ローカルテスト（チェックリスト実施）
  ├─ ⑭ Firebase Testing Lab でテスト配布（複数実機テスト）
  ├─ ⑮ リリース用署名キー確認 + APK署名テスト
  └─ ⑯ 本番AAB ビルド（署名付き、最終確認）

フェーズ5: Google Play ストア リリース (1週間)
  ├─ ⑰ Google Play Console デベロッパーアカウント作成
  ├─ ⑱ アプリストア情報入力（スクリーンショット・説明）
  ├─ ⑲ プライバシーポリシー作成 + 登録
  └─ ⑳ AAB アップロード → レビュー待機 → リリース
```

---

## 🔧 **フェーズ1: ローカル開発環境の完全検証（1.5週間）** ⭐ 最初はここから！

### ① Firebase Auth + Google Sign-In デバッグ署名で動作確認

**目的**: デバッグ環境（debug.keystore）で、Google Sign-Inが完全に動作することを確認

**現在の状況確認**:
```bash
# デバッグキーストアが存在するか確認
ls -la ~/.android/debug.keystore

# その SHA-1 フィンガープリント取得
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey
# パスワード: android

# output:
# Certificate fingerprints:
#   SHA1: XX:XX:XX:...  ← これをコピーメモ
```

**Firebase コンソール側での設定**:
```
1. Firebase Console https://console.firebase.google.com/ にログイン

2. 既存プロジェクト確認（または新規作成）
   プロジェクト名: GroupChatApp (任意)

3. 「プロジェクト設定」→ 「統合」→ 「Android」
   
4. 新規 Android アプリを登録
   - Android パッケージ名: com.example.group_chat_app
   - app ニックネーム: GroupChatApp Debug
   - デバッグ用シニング証明書SHA-1: ↑上記でコピーしたSHA-1
   
5. google-services.json ダウンロード
   android/app/ に配置
   
6. Firebase コンソール → Authentication → Google
   → 「有効にする」をON
```

**flutter プロジェクト側での確認**:
```bash
# 1. Firebase が pubspec.yaml に記載されているか確認
grep -n "firebase" pubspec.yaml

# 出力例:
# - firebase_core
# - firebase_auth
# - google_sign_in

# 上記がない場合、以下で追加
flutter pub add firebase_core firebase_auth

# 2. ローカル実機でテスト
cd /home/kasouzou/lab/GroupChatApp/group_chat_app

# デバッグでAndroid実機/エミュレータを接続してテスト
flutter run -v --dart-define=CHAT_API_BASE_URL=http://10.0.2.2:8080

# 3. 画面に「Google でサインイン」ボタンが表示され、タップできるか確認
#    → ボタンをタップ → Google 認証画面が出現
#    → ユーザーを選択 → ホーム画面に遷移
```

**確認チェックリスト（これが全部 OK なら、次へ）**:
```
- [ ] SHA-1 フィンガープリント取得完了
- [ ] Firebase console にAndroid app 登録完了
- [ ] google-services.json を android/app/ に配置
- [ ] firebase_auth, firebase_core が pubspec.yaml に記載
- [ ] flutter pub get 実行済み
- [ ] ローカル実機で「Google でサインイン」ボタン表示確認
- [ ] ボタンタップ → Google認証 → 成功 → ホーム画面 遷移完了
- [ ] ログアウト・再ログインも確認OK
```

**トラブルシューティング**:
```bash
# エラー: "developer_error"（SHA-1が違う）
#   → SHA-1 コピーミス確認、Firebase console に再登録

# エラー: "google-services.json not found"
#   → android/app/google-services.json の存在確認、パス確認

# エラー: "FirebaseApp initialization failed"
#   → flutter clean && flutter pub get を再実行

# テレメトリ表示されない場合
#   → デバッグログ確認: flutter run -v
```

---

### ② ローカルDocker バックエンド + PostgreSQL 完全連携テスト

**目的**: バックエンド（FastAPI）がローカル PostgreSQL に正しく接続し、データが保存・取得できることを確認

**前提条件**:
- Docker Desktop インストール済み
- backend/docker-compose.yml が完成している

**セットアップ手順**:
```bash
# 1. 既に起動しているコンテナを停止・クリア
cd /home/kasouzou/lab/GroupChatApp/group_chat_app/backend
docker-compose down -v  # -v で volume も削除（リセット）

# 2. 新規起動
docker-compose up -d --build

# 実行確認
docker-compose ps
# STATUS: Up (all 3 running)

# 3. ヘルスチェック（FastAPI）
curl http://localhost:8080/health
# Expected: {"status": "ok"} または {"healthy": true}

# 4. PostgreSQL 接続確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "\dt"
# List of relations でテーブル一覧表示される

# 5. API エンドポイントテスト（詳細は次章）
```

**バックエンド API エンドポイント動作確認**:
```bash
# ① ユーザー認証テスト
curl -X POST http://localhost:8080/api/v1/auth/google-login \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-user-001",
    "displayName": "Test User",
    "photoUrl": "https://example.com/photo.jpg",
    "email": "test@example.com"
  }'

# Expected:
# {
#   "id": "test-user-001",
#   "displayName": "Test User",
#   "photoUrl": "https://example.com/photo.jpg",
#   "email": "test@example.com",
#   "created_at": 1708600000000
# }

# ② ユーザー情報取得テスト
curl http://localhost:8080/api/v1/users/test-user-001

# Expected:
# {
#   "id": "test-user-001",
#   "displayName": "Test User",
#   ...
# }

# ③ グループ作成テスト
curl -X POST http://localhost:8080/api/v1/groups \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Group",
    "creator_user_id": "test-user-001"
  }'

# Expected:
# {
#   "id": "group-xxx",
#   "name": "Test Group",
#   ...
# }

# ④ メッセージ送信テスト
curl -X POST http://localhost:8080/api/v1/messages \
  -H "Content-Type: application/json" \
  -d '{
    "group_id": "group-xxx",
    "sender_id": "test-user-001",
    "content": {"type": "text", "text": "Hello from API test"},
    "created_at": 1708600000000
  }'
```

**PostgreSQL 内部でのデータ確認**:
```bash
# ユーザーテーブル確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "SELECT * FROM users;"

# グループテーブル確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "SELECT * FROM groups;"

# メッセージテーブル確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "SELECT * FROM messages;"
```

**確認チェックリスト**:
```
- [ ] docker-compose up 実行後、3つのコンテナ (nginx, fastapi, postgres) が起動
- [ ] curl /health → 200 応答
- [ ] POST /api/v1/auth/google-login → 新規ユーザー登録＆DB保存確認
- [ ] GET /api/v1/users/{user_id} → ユーザー情報正しく取得
- [ ] POST /api/v1/groups → グループ作成＆DB保存確認
- [ ] POST /api/v1/messages → メッセージ送信＆DB保存確認
- [ ] psql でテーブル直接確認 → データが見える
```

**トラブルシューティング**:
```bash
# ポート8080がすでに使用中の場合
lsof -i :8080
kill -9 <PID>  # または docker-compose で port を変更

# PostgreSQL 接続できない
docker-compose logs postgres
# または
docker-compose exec postgres psql -U postgres -d postgres

# FastAPI ログで詳細確認
docker-compose logs -f fastapi
```

---

### ③ ローカルFlutterアプリ ←→ API の データフロー確認

**目的**: FlutterアプリがローカルAPIと通信し、リアルタイムでデータ表示される確認

**セットアップ**:
```bash
# 1. バックエンド起動済みか確認（前セクション）
docker-compose ps

# 2. Android エミュレータ起動
# または 実機を USB 接続

# 3. Flutter アプリ実行
cd /home/kasouzou/lab/GroupChatApp/group_chat_app

flutter run \
  --dart-define=CHAT_API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=CHAT_USER_ID=test-user-001 \
  -v

# ※ 10.0.2.2 = Android エミュレータからホスト PC にアクセスするエイリアス
# ※ 実機の場合は http://<your-pc-ip>:8080 に置き換え
```

**ユーザー流動テスト**:
```
1. アプリ起動 → スプラッシュスクリーン（4秒）
   ↓
2. ログイン画面 → 「Google でサインイン」ボタン表示
   ↓
3. ボタンタップ
   ↓
4. Google 認証完了
   ↓
5. バックエンド /api/v1/auth/google-login に POST
   ↓
6. ユーザーが DB に登録
   ↓
7. ホーム画面（チャット一覧）に遷移
```

**データが実際に表示されるか確認**:
```
【チャット一覧画面】
- ログイン直後、プリセットされたチャットグループが表示される？
- グループ名が表示されているか？
- メンバー数が表示されているか？
- 最新メッセージが表示されているか？

【チャット画面で送受信テスト】
- メッセージ入力 → 送信ボタンタップ
  - バックエンド /api/v1/messages に POST されるか？
  - DB に MESSAGE レコード が保存されるか？
  - 画面上に自分のメッセージが表示されるか？
  
- 別の実機・エミュレータから同じグループを開く
  - メッセージが相互に見えるか？
  - リアルタイム更新（ポーリング）が動作するか？

【オフライン→オンライン復帰テスト】
- 機内モード ON → メッセージ送信（ローカルキャッシュに保存される）
- 機内モード OFF → メッセージが実際に送信されるか？
```

**ログレベルを上げて詳細デバッグ**:
```bash
# HTTP リクエスト・レスポンスをログ出力
flutter run -v 2>&1 | grep -E "POST|GET|PUT|DELETE|http"

# または lib/main.dart の RemoteDataSource で以下を追加
// final response = await http.post(...);
// debugPrint('Request: $uri');
// debugPrint('Response: ${response.statusCode} ${response.body}');
```

**確認チェックリスト**:
```
- [ ] アプリ起動 → スプラッシュ → ログイン画面 → Google 認証
- [ ] Google 認証成功 → ホーム画面（チャット一覧）遷移
- [ ] チャットグループがリストに表示
- [ ] グループをタップ → チャット画面開く
- [ ] メッセージ入力 → 送信 → 画面上に表示
- [ ] curl で手動送信したメッセージが画面に現れるか確認
- [ ] 複数実機で送受信 → リアルタイム更新確認
- [ ] オフライン送信 → オンライン復帰 → 送信完了確認
```

**トラブルシューティング**:
```bash
# エラー: "Connection refused" 
# → バックエンドが起動していない確認
docker-compose ps

# エラー: "API URL が間違っている"
# → --dart-define で正しい URL 指定されているか確認
flutter run -v | grep CHAT_API_BASE_URL

# エラー: "デバッグ署名エラー"
# → キャッシュクリア + 再ビルド
flutter clean && flutter pub get && flutter run
```

---

### ④ ローカル環境でのユーザー認証フロー完全テスト

**目的**: 認証・セッション管理が完全に機能することを確認（アプリ再起動後の自動ログイン含む）

**テストシナリオ①: 新規ログイン→セッション保存**:
```
1. アプリ起動 → ログイン画面
2. 「Google でサインイン」 → 認証
3. Riverpod authSessionProvider に User が保存されるか確認
   - ホーム画面でユーザー名が表示されるか？
   - プロフィール画像が表示されるか？
```

**テストシナリオ②: アプリ再起動後の自動ログイン**:
```
1. ホーム画面で「アプリ再起動」（ホットリスタート Not OK、完全再起動）
   flutter clean && flutter run

2. スプラッシュスクリーン → 自動的にホーム画面に遷移するか？
   （ログイン画面を経由しないか？）

3. このとき、バックエンド側で attemptLightweightAuthentication() が実行され、
   前回のセッション情報が復元されるはず
```

**テストシナリオ③: ログアウト**:
```
1. ホーム画面 → プロフィール・設定画面
2. 「ログアウト」ボタン
3. authSessionProvider から User が削除されるか？
4. ログイン画面に遷移するか？
5. 再度 Google でサインインできるか？
```

**トークン検証テスト（詳細）**:
```bash
# Firebase ID Token がバックエンドで正しく検証されるか確認

# Step 1: ローカル実機でログイン
# → フロント側で google_sign_in.authentication.idToken を取得

# Step 2: バックエンド API call で Token 送信
curl -X POST http://localhost:8080/api/v1/auth/google-login \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <idToken>" \
  -d '{...}'

# Step 3: バックエンド側で Token 検証
# backend/app/services/auth_service.py で Firebase Admin SDK を使用して
# Token を decode & 署名検証する処理が機能しているか確認

# ログで確認
docker-compose logs fastapi | grep -i "token\|auth\|error"
```

**セッション管理テスト**:
```bash
# SQLite/PostgreSQL に Session テーブルが作成されているか確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "
  SELECT table_name FROM information_schema.tables 
  WHERE table_schema='public' AND table_name LIKE '%session%';
"

# Session レコードが実際に保存されているか確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "
  SELECT * FROM user_sessions LIMIT 5;
"
```

**確認チェックリスト**:
```
- [ ] ローカルで「Google でサインイン」成功
- [ ] authSessionProvider に User が保存される
- [ ] ホーム画面にユーザー情報表示
- [ ] アプリ再起動 → スプラッシュ → 自動ログイン → ホーム画面
- [ ] ログアウト機能動作
- [ ] ログアウト後、再度ログイン可能
- [ ] バックエンド Token 検証 ログに error なし
- [ ] Session テーブル＆レコード確認
- [ ] 複数タブ・複数実機での Session 管理が正しく動作

🎉 ここまで OK なら、フェーズ1 完了！VPS 構築に進める
```

## 📱 **フェーズ2: バックエンド本番化（2週間）**

### ⑤ XserverVPS上にバックエンド構築

**目的**: 24時間稼働するバックエンドサーバーの構築（ローカル設定を VPS で再現）

**前提条件**:
- XserverVPS 契約済み（推奨: 2GB メモリ以上）
- SSH 接続可能
- ローカルで docker-compose が動作していることを確認

**ステップバイステップ**:

```bash
# 1. VPS へ SSH 接続
ssh root@<VPS の IP アドレス>
# パスワードまたは SSH キー認証

# 2. システムアップデート
apt update && apt upgrade -y

# 3. Docker + Docker Compose インストール
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Compose 別途インストール
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

docker-compose --version  # 確認

# 4. Git インストール（プロジェクトクローン用）
apt install -y git

# 5. プロジェクトクローン
cd /opt/  # または任意のディレクトリ
git clone https://github.com/<your-username>/GroupChatApp.git
cd GroupChatApp/group_chat_app/backend

# 6. 環境変数設定（本番用）
cat > .env << 'EOF'
# PostgreSQL
POSTGRES_USER=chat_admin
POSTGRES_PASSWORD=<生成して記入: openssl rand -base64 16>
POSTGRES_DB=chat_db
DATABASE_URL=postgresql://chat_admin:<password>@postgres:5432/chat_db

# API
API_ENV=production
API_PORT=8000

# Firebase (後で詳細設定)
FIREBASE_PROJECT_ID=your-firebase-project
EOF

# 7. ローカルと同じ Docker 設定を確認
cat docker-compose.yml

# 8. Docker コンテナ起動
docker-compose up -d --build

# 起動確認
docker-compose ps
# All 3 containers running?

# 9. ローカルでのテスト時と同じ API テスト実行
curl http://localhost:8080/health
# Expected: {"status": "ok"}

# 10. ログ確認（エラーがないか）
docker-compose logs -f fastapi
# Ctrl+C で終了
```

**ファイアウォール設定（重要）**:
```bash
# ポート 8080 をインターネットからアクセス可能に（Nginx 経由）
# ※ 直接 8080 は外部公開しない（8080 は内部のみ）

# Nginx 経由でアクセス可能か確認（後の HTTPS セクションで詳細）
curl http://<VPS-IP>:80/health
```

**確認チェックリスト**:
```
- [ ] SSH VPS 接続成功
- [ ] Docker インストール完了
- [ ] プロジェクトクローン完了
- [ ] .env ファイル作成完了（パスワード設定）
- [ ] docker-compose up で 3 コンテナ起動
- [ ] curl http://localhost:8080/health → 200
- [ ] docker-compose logs で error なし
- [ ] curl http://<VPS-IP>:8080/health でもアクセス可能（Nginx 経由）

💡 トラブル: VPS の RAM/CPU が足りない場合
   - Docker ログ確認: docker-compose logs
   - コンテナ再起動: docker-compose restart
   - メモリ確認: free -h / docker stats
```

**参考**:
- [XserverVPS - Docker利用ガイド](https://www.xserver.ne.jp/manual/man_vps.html)
- [Docker Compose デプロイ](https://docs.docker.com/compose/production/)

---

### ⑥ HTTPS/SSL 設定 + ドメイン設定

**目的**: HTTPS 通信を有効化し、安全に API 通信可能に

**ドメイン取得**:
```
1. お名前.com, Xserver, GoDaddy などでドメイン取得
   例: group-chat-api.example.com
   
2. VPS IP アドレスに A レコード登録
   DNS 設定画面 → A レコード → <VPS-IP>
```

**Let's Encrypt で SSL 証明書取得**:
```bash
# VPS 上で以下を実行

# 1. Certbot インストール
apt install -y certbot python3-certbot-nginx

# 2. SSL 証明書生成
certbot certonly --standalone -d group-chat-api.example.com

# パスワード入力 → メールアドレス → 約款同意

# 証明書生成場所:
# /etc/letsencrypt/live/group-chat-api.example.com/fullchain.pem
# /etc/letsencrypt/live/group-chat-api.example.com/privkey.pem

# 3. 自動更新設定
certbot renew --dry-run  # テスト実行
# cron に自動登録されます
```

**Nginx 設定**:
```bash
# 1. Nginx 設定ファイル作成
cat > /path/to/nginx.conf << 'EOF'
server {
    listen 80;
    server_name group-chat-api.example.com;
    return 301 https://$server_name$request_uri;  # HTTP → HTTPS リダイレクト
}

server {
    listen 443 ssl http2;
    server_name group-chat-api.example.com;
    
    ssl_certificate /etc/letsencrypt/live/group-chat-api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/group-chat-api.example.com/privkey.pem;
    
    # SSL セキュリティ設定（推奨）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 2. Nginx を Docker で起動する場合
cat > docker-compose.yml << 'EOF'
...
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - /etc/letsencrypt:/etc/letsencrypt  # SSL 証明書マウント
    depends_on:
      - fastapi
...
EOF

# 3. Nginx 再起動
docker-compose restart nginx
```

**HTTPS 動作確認**:
```bash
# ブラウザまたは curl で確認
curl https://group-chat-api.example.com/health -v

# Expected:
# HTTP/2 200
# {"status": "ok"}
```

**確認チェックリスト**:
```
- [ ] ドメイン取得 & DNS 登録完了
- [ ] VPS A レコード → IP 登録完了
- [ ] Let's Encrypt SSL 証明書取得完了
- [ ] Nginx 設定更新 & 再起動完了
- [ ] curl https://domain/health → 200
- [ ] HTTPS 接続時、ブラウザ警告なし
- [ ] 自動更新設定確認
```

---

### ⑦ VPS 上の PostgreSQL セットアップ + マイグレーション

**目的**: VPS 上で DB が正しく初期化され、スキーマが作成されることを確認

```bash
# 1. VPS 上で DB マイグレーション実行
cd /opt/GroupChatApp/group_chat_app/backend

# Docker Compose 経由で FastAPI コンテナ内で実行
docker-compose exec fastapi python -m alembic upgrade head

# 出力例:
# INFO [alembic.runtime.migration] Context impl PostgresqlImpl with table alembic_version
# INFO [alembic.runtime.migration] Will assume transactional DDL. True
# INFO [alembic.runtime.migration] Running upgrade  -> 001_initial, Create ...

# 2. テーブル確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "\dt"

# 3. プリセットデータ挿入（ローカルで動作していた初期化スクリプトがあれば）
docker-compose exec fastapi python -m scripts.seed_initial_data
```

**確認チェックリスト**:
```
- [ ] alembic upgrade 実行完了（エラーなし）
- [ ] テーブル作成確認（users, groups, messages など）
- [ ] 初期データ挿入確認（必要に応じて）
```

---

### ⑧ VPS API 検証（curl でテスト）

**目的**: VPS バックエンドが完全に動作することを確認

```bash
# VPS 上から、または ローカル PC から HTTPS API テスト

# 1. ヘルスチェック
curl https://group-chat-api.example.com/health

# 2. ユーザー認証テスト
curl -X POST https://group-chat-api.example.com/api/v1/auth/google-login \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-vps-user",
    "displayName": "VPS Test User",
    "photoUrl": "https://example.com/photo.jpg"
  }'

# 3. ユーザー情報取得
curl https://group-chat-api.example.com/api/v1/users/test-vps-user

# 4. グループ作成
curl -X POST https://group-chat-api.example.com/api/v1/groups \
  -H "Content-Type: application/json" \
  -d '{
    "name": "VPS Test Group",
    "creator_user_id": "test-vps-user"
  }'

# 5. VPS PostgreSQL にデータが保存されたか確認
docker-compose exec postgres psql -U chat_admin -d chat_db -c "
  SELECT * FROM users WHERE id = 'test-vps-user';
"
```

**確認チェックリスト**:
```
- [ ] HTTPS /health → 200
- [ ] HTTPS POST /auth/google-login → 200, ユーザー登録
- [ ] GET /users/{id} → ユーザー情報返却
- [ ] POST /groups → グループ作成
- [ ] VPS DB に実際にデータ保存確認
```

**トラブルシューティング**:
```bash
# エラー: "Connection refused"
docker-compose ps
docker-compose logs -f fastapi

# エラー: "SSL certificate verify failed"
# Let's Encrypt 証明書確認
ls -la /etc/letsencrypt/live/group-chat-api.example.com/

# エラー: "502 Bad Gateway"
# Nginx ログ確認
docker-compose logs nginx
```

---

### ⑤ HTTPS/SSL設定 + ドメイン

**目的**: HTTPS通信で安全にAPI呼び出し

**手順**:
```bash
# 1. ドメイン取得（例: お名前.com / Xserver）
#    group-chat.example.com のような新規ドメイン or サブドメイン

# 2. VPS上で Let's Encrypt 設定
sudo apt update && sudo apt install certbot python3-certbot-nginx -y

# 3. Nginxのhttps設定
cat > /path/to/nginx/default.conf << EOF
server {
    listen 80;
    server_name group-chat.example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name group-chat.example.com;
    
    ssl_certificate /etc/letsencrypt/live/group-chat.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/group-chat.example.com/privkey.pem;
    
    location / {
        proxy_pass http://fastapi:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# 4. Nginxリロード
docker-compose exec nginx nginx -s reload

# 5. 定期更新設定
sudo certbot renew --dry-run
```

**確認項目**:
- [ ] `https://group-chat.example.com/health` → 200
- [ ] ブラウザで警告なくアクセス可能

**参考**:
- [Let's Encrypt + Nginx](https://certbot.eff.org/instructions?ws=nginx&os=ubuntu-20.04)

---

### ⑥ バックエンドテスト + API検証

**目的**: 本番環境でAPIの全機能が正常動作することを確認

**テスト項目**:
```bash
# ①認証テスト
curl -X POST https://group-chat.example.com/api/v1/auth/google-login \
  -H "Content-Type: application/json" \
  -d '{
    "id": "test-user-001",
    "displayName": "Test User",
    "photoUrl": "https://example.com/photo.jpg"
  }'

# ②グループ作成テスト
curl -X POST https://group-chat.example.com/api/v1/groups \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Group",
    "creator_user_id": "test-user-001",
    "member_user_ids": ["test-user-001", "test-user-002"]
  }'

# ③メッセージ送信テスト
curl -X POST https://group-chat.example.com/api/v1/messages \
  -H "Content-Type: application/json" \
  -d '{
    "local_id": "msg-001",
    "group_id": "group-001",
    "sender_id": "test-user-001",
    "role": "member",
    "content": {"type": "text", "text": "Hello"},
    "created_at": 1708600000000
  }'
```

**確認項目**:
- [ ] すべてのエンドポイントが正常応答
- [ ] DB保存確認: `docker-compose exec postgres psql -U chat_admin -d chat_db`
- [ ] エラーレスポンス適切か確認

---

## 🔐 **フェーズ3: フロント本番化（2週間）**

### ⑦ Firebase Authenticationセットアップ

**目的**: Firebase経由でのGoogle認証統合

**手順**:
```
1. Firebaseコンソール → Authentication → Google有効化

2. Flutterアプリへ firebase_auth 統合
   
   pubspec.yaml に追加:
   ```yaml
   firebase_auth: ^4.0.0
   firebase_core: ^2.0.0
   ```
   
   $ flutter pub get

3. main.dart で Firebase初期化
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'firebase_options.dart';
   
   Future<void> main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(
       options: DefaultFirebaseOptions.currentPlatform,
     );
     runApp(const MyApp());
   }
   ```

4. Google Sign-In から Firebase Auth へ移行
   - lib/features/auth/data/datasource/remote/auth_remote_datasource_impl.dart
     を更新してFirebaseAuthを使用

5. ID Tokenをバックエンドへ送信
   ```dart
   final user = await FirebaseAuth.instance.currentUser;
   final idToken = await user?.getIdToken();
   
   // API呼び出しにHeaderで含める
   final response = await http.post(
     Uri.parse('$baseUrl/api/v1/auth/verify-token'),
     headers: {'Authorization': 'Bearer $idToken'},
   );
   ```
```

**確認項目**:
- [ ] Firebase認証有効化完了
- [ ] ローカルでGoogle Sign-In動作確認
- [ ] IDTokenバックエンド送信成功

**参考**:
- [Firebase Auth for Flutter](https://firebase.flutter.dev/docs/auth/overview)

---

### ⑧ APIエンドポイント本番URL化

**目的**: ローカル開発URLから本番URLへ切り替え

**手順**:
```dart
// lib/core/config/app_config.dart を新規作成

class AppConfig {
  static const String _apiBaseUrl = String.fromEnvironment(
    'CHAT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080', // ローカル開発用デフォルト
  );
  
  static String get apiBaseUrl => _apiBaseUrl;
}

// 使用例: lib/features/chat/data/datasource/remote/chat_remote_datasource_impl.dart
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final String _baseUrl = AppConfig.apiBaseUrl;
  // ...
}
```

**ビルド時の指定**:
```bash
# ローカル開発
flutter run

# ステージング環境テスト
flutter run \
  --dart-define=CHAT_API_BASE_URL=https://staging-api.example.com

# 本番環境
flutter run \
  --dart-define=CHAT_API_BASE_URL=https://group-chat.example.com
```

**確認項目**:
- [ ] ローカル開発・ステージング・本番の3環境で動作確認
- [ ] APIエンドポイント正しく呼び出されているかログで確認

---

### ⑨ Cloud Storageセットアップ（プロフィール画像保存）

**目的**: ユーザープロフィール画像をクラウドに保存

**手順**:
```
1. Firebase console → Cloud Storage → バケット作成
   リージョン: asia-northeast1（日本）

2. セキュリティルール設定
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /profile-images/{uid}/{fileName} {
         allow read: if request.auth != null;
         allow write: if request.auth != null && request.auth.uid == uid;
       }
     }
   }
   ```

3. バックエンドでCloud Storage APIを使用
   backend/requirements.txt に追加:
   ```
   firebase-admin==6.0.0
   ```
   
   backend/app/services/storage_service.py を作成:
   ```python
   import firebase_admin
   from firebase_admin import credentials, storage
   
   def upload_profile_image(user_id: str, image_bytes: bytes) -> str:
       bucket = storage.bucket()
       blob = bucket.blob(f'profile-images/{user_id}/avatar.jpg')
       blob.upload_from_string(image_bytes, content_type='image/jpeg')
       blob.make_public()
       return blob.public_url
   ```

4. APIエンドポイント更新
   `PUT /api/v1/users/{user_id}` でprofile_imageアップロード対応
```

**確認項目**:
- [ ] Cloud Storageバケット作成完了
- [ ] ローカルテストで画像アップロード・ダウンロード成功
- [ ] バックエンド・フロント両方で画像URLが利用可能

---

## 🧪 **フェーズ4: テスト + ビルド（1.5週間）**

### ⑩ アプリローカルテスト（すべての機能）

**目的**: リリース前の最終品質確認

**テストチェックリスト**:
```
【認証】
- [ ] Google Sign-In でログイン可能
- [ ] Firebase認証と連携成功
- [ ] ログアウト機能動作
- [ ] セッション復元機能動作（スプラッシュ画面）

【チャット機能】
- [ ] チャット一覧表示
- [ ] グループ検索機能
- [ ] メッセージ送受信
- [ ] 複数ユーザーでメッセージ相互確認
- [ ] オフライン・オンライン切り替え動作
- [ ] スクロール・キャッシュ動作

【プロフィール】
- [ ] プロフィール情報表示
- [ ] プロフィール編集
- [ ] 画像アップロード・表示
- [ ] 設定画面表示

【メンバー招待】
- [ ] QRコード表示・スキャン
- [ ] 招待コード共有

【UI/UX】
- [ ] 画面遷移スムーズ
- [ ] ローディング表示適切
- [ ] エラー時メッセージ表示
- [ ] 縦横画面回転対応
```

**テスト実機**:
- Android実機 (Android 10 以上推奨)
- 複数デバイス間でメッセージ確認

**テストツール**:
```bash
# パフォーマンス確認
flutter run --profile

# 本番ビルドテスト
flutter run --release
```

---

### ⑪ Firebase Testingでテスト配布

**目的**: 内部テスト・外部テスター向けの配布テスト

**手順**:
```
1. Google Play Console → テスト → 内部テスト
   
2. APK生成（テスト用）
   ```bash
   flutter build apk --release
   # build/app/outputs/apk/release/app-release.apk
   ```

3. Firebase Console → App Distribution
   → APKアップロード
   → テスター招待（メールアドレス）

4. テスター側:
   - Android デバイスで受け取ったリンク開く
   - Firebase Testing Lab からダウンロード
   - インストール・テスト実施
   - フィードバック

5. フィードバック反映
   - バグ修正
   - UI調整
   - パフォーマンス改善
```

**確認項目**:
- [ ] APKビルド成功
- [ ] Firebase App Distribution アップロード成功
- [ ] テスター 最低 5名以上のフィードバック取得
- [ ] 重大バグなし

---

### ⑫ リリース用署名キー作成

**目的**: Google Play Store向けの署名設定

**手順**:
```bash
# 1. リリース用署名キーファイル生成（既に③で作成済みなら確認）
ls -la ~/group_chat_app.jks

# 2. キーストア情報を android/key.properties に記録
cat > android/key.properties << EOF
storePassword=<jksのパスワード>
keyPassword=<キーのパスワード>
keyAlias=group_chat_app
storeFile=../group_chat_app.jks
EOF

# 3. android/app/build.gradle で署名設定
# （既に設定されているか確認）

# 4. 署名テスト
flutter build apk --release
# build/app/outputs/apk/release/app-release.apk 生成確認
```

**確認項目**:
- [ ] key.properties 作成完了
- [ ] build.gradle に署名設定記載
- [ ] リリース用APK ビルド成功

**セキュリティ**:
```bash
# key.properties を .gitignore に追加
echo "android/key.properties" >> .gitignore
git add .gitignore && git commit -m "Add key.properties to gitignore"
```

---

## 📤 **フェーズ5: リリース準備（1.5週間）**

### ⑬ Google Playコンソール登録

**目的**: Google Play Storeでのアプリ公開準備

**手順**:
```
1. Google Play Console にアクセス
   https://play.google.com/console/

2. デベロッパーアカウント作成（初回のみ）
   - 氏名、メールアドレス
   - 登録料: $25 (一度きり)

3. 新規アプリ作成
   - アプリ名: 言論空間 (Group Chat App)
   - プラットフォーム: Android
   - アプリの種類: アプリ

4. アプリの基本情報入力
   - パッケージ名: com.example.group_chat_app （本番用に変更推奨）
   - アプリのカテゴリ: ソーシャル
   - メールアドレス: サポート用

5. アプリの署名
   - 「Play アプリ署名を使用する」を選択
   - 初期版は Google Play が署名を管理
```

**確認項目**:
- [ ] Google Play Console アカウント作成
- [ ] アプリ基本情報入力
- [ ] パッケージ名確定

**参考**:
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)

---

### ⑭ スクリーンショット + 説明文作成

**目的**: ユーザーが Google Play Storeで見るマーケティング情報

**必要な資料**:
```
【スクリーンショット】
- 最低 2枚、最大 8枚推奨
- サイズ: 1080 x 1920 px (9:16)
- 言語: 日本語

推奨内容:
1. ログイン画面
2. チャット一覧
3. チャット画面（メッセージ送受信）
4. プロフィール画面
5. メンバー招待（QRコード）

【アプリの説明】
- 短い説明: "シンプルで使いやすいグループチャットアプリ"
- 詳細説明:
  - グループチャット機能
  - リアルタイムメッセージ
  - プロフィール管理
  - メンバー招待（QRコード）
  - オフライン対応
  
【プライバシーポリシー】
- 次セクション参照

【キーワード】
- チャット
- グループチャット
- メッセージング
- コミュニケーション
```

**Google Play Consoleへの入力**:
```
1. Google Play Console → アプリ → ストアの掲載情報

2. 「メイン ストアの掲載情報」
   - アプリ名
   - 短い説明
   - フル説明
   - スクリーンショット (5枚推奨)
   - 特集画像 (1080 x 440 px)
   - アイコン (512 x 512 px)

3. 「コンテンツの種類」
   - アプリの対象: 全年齢
   - コンテンツレーティング: 標準

4. 「保存して続行」
```

---

### ⑮ プライバシーポリシー作成

**目的**: ユーザー情報取得・利用に関する法的透明性

**必須事項**:
```
1. 個人情報の収集
   - Google ログイン: ユーザーID, 名前, プロフィール写真
   - メッセージ: チャット内容, タイムスタンプ
   - デバイス情報: OSバージョン, デバイスID

2. 個人情報の利用目的
   - ユーザー認証
   - チャット機能の提供
   - サーバーログ記録
   - サービス改善

3. 個人情報の保管
   - Google Firebase
   - XserverVPS (PostgreSQL)
   - 保管期間: ユーザーがデータ削除まで

4. 第三者への提供
   - 原則提供なし
   - 法的要求時を除く

5. セキュリティ
   - HTTPS通信
   - Firebase認証
   - DB暗号化（推奨）

6. 個人情報の削除
   - ユーザーが アカウント削除時にすべてのデータ削除

サンプルテンプレート:
- https://www.privacypolicygenerator.info/
- https://www.iubenda.com/
```

**Google Play Consoleへの登録**:
```
1. Googleサイト（例: https://www.example.com/privacy）でホスティング

2. Google Play Console → ユーザーとアクセス権限の管理
   → コンテンツ等級評定 → プライバシーポリシーURL入力
```

---

### ⑯ AABファイルビルド + アップロード

**目的**: Google Play Store向けリリースビルド

**手順**:
```bash
# 1. AAB（Android App Bundle）ビルド
flutter build appbundle --release

# 生成場所: build/app/outputs/bundle/release/app-release.aab
# ファイルサイズ確認
ls -lh build/app/outputs/bundle/release/app-release.aab

# 2. Google Play Console へアップロード
#    Console → テスト → 内部テスト → APKを作成
#    もしくは
#    Console → リリース → 新しいリリース → AABアップロード

# 3. AAB検証
#    - 署名確認
#    - リソース確認
#    - パーミッション確認

# 4. ストアリスティング確認
#    - スクリーンショット
#    - 説明文
#    - プライバシーポリシー
#    - コンテンツ等級

# 5. 「リリースレビュー用に送信」をクリック
#    ※ 自動レビューで 1-3日待機

# 6. 承認後 → 「本番環境にリリース」で全ユーザーに公開
```

**AABビルド時の注意**:
```
1. リリース署名キー確認
   - android/key.properties 存在確認
   - keytool でSHA情報確認

2. アプリバージョン確認
   pubspec.yaml:
   ```yaml
   version: 1.0.0+1  # 1.0.0 は表示版, +1 はビルド番号
   ```

3. Android SDK バージョン確認
   android/app/build.gradle:
   ```gradle
   targetSdkVersion: 34  # 最新推奨
   minSdkVersion: 21     # Android 5.0以上
   ```

4. パーミッション確認
   AndroidManifest.xml で必要なパーミッション追加:
   ```xml
   <uses-permission android:name="android.permission.CAMERA" />
   <uses-permission android:name="android.permission.INTERNET" />
   ```
```

**AABアップロード完了後の流れ**:
```
1. Google自動レビュー (1-3日)
   ├─ セキュリティチェック
   ├─ コンテンツチェック
   └─ パフォーマンステスト

2. 承認 ✓
   ├─ "リリース承認済み" と表示
   └─ "本番環境にリリース" ボタン有効化

3. 本番リリース
   ├─ ボタンをクリック
   ├─ 一部ユーザーに段階的公開 (推奨 5%)
   └─ 問題なければ 100% に拡大

4. Google Play Store に表示
   - インストール可能状態に
   - ユーザーからの評価・レビュー受け付け開始
```

**確認項目**:
- [ ] AAB ファイル生成成功
- [ ] Google Play Console へのアップロード成功
- [ ] 自動レビュー承認取得
- [ ] 本番リリース完了
- [ ] Google Play Store で検索可能か確認

---

## 📋 **重要な決定事項（最初にクリアすること）**

| 項目 | 選択肢 | 推奨 | 理由 |
|------|--------|------|------|
| **認証** | Firebase Auth vs 独自認証 | Firebase Auth | スケーラビリティ・セキュリティ |
| **API URL** | `example.com` vs IP直接 | ドメイン | SSL/HTTPS対応・保守性 |
| **バックエンド** | VPS vs PaaS | VPS (Xserver) | コスト・カスタマイズ性 |
| **DB** | PostgreSQL vs Firebase | PostgreSQL | 複雑なクエリ対応・コスト |
| **ストレージ** | Cloud Storage vs S3 | Cloud Storage | Firebase統合・管理簡単 |
| **バージョン** | 1.0.0 | 1.0.0 | 初回リリースは1.0.0 推奨 |
| **段階公開** | 5% → 25% → 100% | Yes | バグ早期発見・ロールバック対応 |

---

## ⏱️ **実装スケジュール（推奨）**

```
週1：フェーズ1 (Google Cloud + Firebase初期設定)
  - 月: ① Google Cloud + Firebase
  - 火～木: ② ローカルバックエンド検証
  - 金: ③ Google Sign-In本番設定

週2：フェーズ2前半 (VPS構築)
  - 月～水: ④ XserverVPS構築
  - 木～金: ⑤ HTTPS/SSL

週3：フェーズ2後半 + フェーズ3前半
  - 月～火: ⑥ バックエンドテスト
  - 水～金: ⑦⑧⑨ フロント本番化

週4：フェーズ3後半 + フェーズ4前半
  - 月～水: ⑩ ローカルテスト
  - 木～金: ⑪ Firebase Testing

週5：フェーズ4後半 + フェーズ5前半
  - 月～火: ⑫ 署名キー確認
  - 水～金: ⑬⑭⑮ Play Console + マーケティング資料

週6：フェーズ5後半
  - 月: ⑯ AABビルド + アップロード
  - 火～金: レビュー待機 + 最終調整

（期間: 6週間 ＝ 約1.5ヶ月）
```

---

## 🚀 **ラッチの直前チェック**

リリース前に以下を必ず確認:

```
【技術検証】
- [ ] 本番URLでAPIすべてが正常動作
- [ ] オフラインキャッシュが機能
- [ ] 複数ユーザー間でメッセージ相互確認
- [ ] エラーハンドリング適切 (networkエラー等)
- [ ] ログアウト後ログイン再度可能

【パフォーマンス】
- [ ] メッセージ50+件でもスクロール滑らか
- [ ] 画像アップロード 10MB 以内で完了
- [ ] バッテリー消費 (Profile で確認)
- [ ] メモリリーク なし

【ユーザビリティ】
- [ ] 日本語すべて正しく表示
- [ ] タッチ操作 全て レスポンシブ
- [ ] 画面回転で状態保持
- [ ] デバイス戻るボタン / ジェスチャ対応

【セキュリティ】
- [ ] Googleログイン tokenはHTTPSのみ送信
- [ ] プロフィール画像は暗号化保存
- [ ] DBパスワード環境変数化
- [ ] google-services.json に本番値

【リリース情報】
- [ ] version 確定 (1.0.0)
- [ ] プライバシーポリシー URL確定
- [ ] スクリーンショット 5枚以上
- [ ] app name / description 日本語OK
```

---

## 💡 **その後の運用**

AABリリース後:

```
【Day 1-7: 初期段階 (5%ユーザー)】
- [ ] crashlytics でエラー監視
- [ ] ユーザーレビュー確認
- [ ] Analytics で使用状況追跡

【Week 2: 段階拡大 (25%ユーザー)】
- [ ] バグなければ拡大
- [ ] 重大バグあれば pause

【Week 3+: 本公開 (100%ユーザー)】
- [ ] フル公開
- [ ] 継続的な改善・機能追加

【継続的改善】
1. ユーザーフィードバック集約
2. アナリティクス分析
3. マイナーアップデート (1.0.1, 1.0.2...)
4. メジャー機能追加 (1.1.0, 2.0.0...)
```

---

## 📚 **参考資料**

**Google Play関連**:
- [Google Play Console ヘルプ](https://support.google.com/googleplay/android-developer)
- [Androidアプリリリースガイド](https://developer.android.com/studio/publish)
- [AAB (Android App Bundle) ドキュメント](https://developer.android.com/guide/app-bundle)

**Firebase関連**:
- [Firebase Auth + Google Sign-In](https://firebase.flutter.dev/docs/auth/overview)
- [Cloud Storage](https://firebase.flutter.dev/docs/storage/overview)
- [App Distribution](https://firebase.google.com/docs/app-distribution)

**セキュリティ**:
- [OWASP Mobile Security](https://owasp.org/www-mobile/)
- [Androidセキュリティ & プライバシー](https://developer.android.com/privacy-and-security)

**バックエンド**:
- [FastAPI チュートリアル](https://fastapi.tiangolo.com/)
- [PostgreSQL ドキュメント](https://www.postgresql.org/docs/)
- [XserverVPS マニュアル](https://www.xserver.ne.jp/manual/)

---

**最後に**: このロードマップは一般的なベストプラクティスに基づいています。  
プロジェクト固有の状況に応じてカスタマイズしてください。  
各フェーズで疑問が生じたら、お気軽にサポート申し上げます！
