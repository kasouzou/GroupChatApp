# AddMemberPage - 招待コード表示部分の詳細解説

## 選択コードの位置と役割

```dart
final inviteCode = _inviteInfo?.inviteCode ?? '----';
final qrData = _inviteInfo?.inviteUrl ?? 'INVITE_NOT_READY';
final expiresAt = _inviteInfo?.expiresAt;
```

このコードは **タブ2（招待画面）** で、バックエンドから取得した招待情報を UI 用に準備する部分です。

---

## 1. `_inviteInfo` のデータ構造

まず、`_inviteInfo` が何かを理解する必要があります。

```
_inviteInfo: GroupInviteInfo? = null または GroupInviteInfo インスタンス
```

### GroupInviteInfo（バックエンドから取得）
バックエンドの `CreateInviteResponse` に対応：

```
GroupInviteInfo {
  groupId: String          // グループID（例: "grp_abc123def456"）
  inviteCode: String       // 招待コード（例: "INV-ABCDEF1234"）
  inviteUrl: String        // 招待URL（例: "https://example.com/invite/INV-ABCDEF1234"）
  expiresAt: DateTime      // 有効期限（例: 2026-02-23 15:30:00Z）
}
```

---

## 2. 3行コードの詳細解説

### 行1: `final inviteCode = _inviteInfo?.inviteCode ?? '----';`

```
フロー図:
┌─────────────────────────────────────┐
│ _inviteInfo の値を確認             │
└────────────┬────────────────────────┘
             │
        ┌────┴─────┐
        ▼          ▼
    [null]      [有効]
        │          │
        │          ▼
        │    _inviteInfo?.inviteCode
        │          │
        │          ▼
        │    "INV-ABC123" を取得
        │          │
        └─────┬────┘
              │
              ▼
    inviteCode の最終値を決定
```

**詳細な処理:**

| 状態 | 処理内容 | 結果 |
|------|--------|------|
| `_inviteInfo` が null | `?.` による安全なアクセス → `null` を返す | `??` の左側が null |
| `_inviteInfo` が有効 | `inviteCode` プロパティを取得 | 招待コード文字列を返す |
| `??` の左側が null | 右側のデフォルト値を使用 | `'----'` を代入 |
| `??` の左側が有効 | 左側の値をそのまま使用 | 招待コード文字列を代入 |

**実装例:**
```dart
// ケース1: _inviteInfo = null
final inviteCode = null ?? '----';  // 結果: '----'

// ケース2: _inviteInfo が有効で inviteCode = "INV-XYZ789"
final inviteCode = "INV-XYZ789" ?? '----';  // 結果: "INV-XYZ789"
```

**画面への影響:**
```dart
Text(
  inviteCode,  // ← ここで表示される
  style: const TextStyle(
    fontSize: 36,
    letterSpacing: 4,
    fontWeight: FontWeight.bold,
    color: Colors.blueAccent,
  ),
)
```

結果：
- ✅ 招待発行済み: **`INV-ABC123`** が大きく表示
- ⏳ 招待未発行: **`----`** が表示（プレースホルダー）

---

### 行2: `final qrData = _inviteInfo?.inviteUrl ?? 'INVITE_NOT_READY';`

```
フロー図:
┌─────────────────────────────────────────┐
│ _inviteInfo の値を確認               │
└────────────┬─────────────────────────────┘
             │
        ┌────┴──────────┐
        ▼               ▼
    [null]          [有効]
        │               │
        │               ▼
        │        _inviteInfo?.inviteUrl
        │               │
        │               ▼
        │        "https://example.com/invite/INV-ABC123"
        │               │
        └────────┬──────┘
                 │
                 ▼
        qrData の最終値を決定
                 │
                 ▼
        QrImageView へ渡される
```

**詳細な処理:**

| 状態 | 説明 | 結果 |
|------|------|------|
| `_inviteInfo` が null | URL がまだ生成されていない | `'INVITE_NOT_READY'` |
| `_inviteInfo` が有効 | バックエンドから取得した完全なURL | `'https://example.com/invite/INV-ABC123'` |

**実装例:**
```dart
// ケース1: 招待未発行状態
final qrData = null ?? 'INVITE_NOT_READY';
// 結果: 'INVITE_NOT_READY'

// ケース2: 招待発行済み状態
final qrData = "https://example.com/invite/INV-ABC123" ?? 'INVITE_NOT_READY';
// 結果: "https://example.com/invite/INV-ABC123"
```

**画面への影響:**
```dart
QrImageView(
  data: qrData,  // ← ここで QR コード生成に使用
  version: QrVersions.auto,
  size: 250.0,
  backgroundColor: Colors.white,
)
```

結果：
- ✅ 招待発行済み: **QR コード画像が表示** （スキャン可能）
- ⏳ 招待未発行: **`INVITE_NOT_READY` のQR** （スキャン不可の無効なコード）

---

### 行3: `final expiresAt = _inviteInfo?.expiresAt;`

```
フロー図:
┌─────────────────────────────────────┐
│ _inviteInfo の値を確認            │
└────────────┬────────────────────────┘
             │
        ┌────┴────────┐
        ▼             ▼
    [null]        [有効]
        │             │
        │             ▼
        │        _inviteInfo?.expiresAt
        │             │
        │             ▼
        │        DateTime object
        │        (例: 2026-02-23 15:30:00Z)
        │             │
        └────────┬────┘
                 │
                 ▼
        expiresAt の最終値
```

**詳細な処理:**

| 状態 | 説明 | 結果 |
|------|------|------|
| `_inviteInfo` が null | 有効期限がまだ存在しない | `null` |
| `_inviteInfo` が有効 | DateTime オブジェクトを取得 | `DateTime` インスタンス |

**実装例:**
```dart
// ケース1: 招待未発行状態
final expiresAt = null;
// 結果: null

// ケース2: 招待発行済み状態
final expiresAt = DateTime(2026, 2, 23, 15, 30, 0);
// 結果: DateTime インスタンス
```

**画面への影響:**
```dart
Text(
  expiresAt == null
      ? '有効期限を取得中...'
      : '有効期限: ${expiresAt.toLocal()}',  // ← ここで表示
  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
)
```

結果：
- ✅ 招待発行済み: **`有効期限: 2026-02-23 15:30:00`** と表示
- ⏳ 招待未発行: **`有効期限を取得中...`** と表示（ローディング状態）

---

## 3. 全体の時系列フロー

### 初期化時（ページ読み込み直後）

```
1. ページロード
   │
   ▼
2. initState() 実行
   │
   ▼
3. _refreshInvite() 呼び出し（非同期）
   │
   ├─ バックエンドへリクエスト（API呼び出し）
   │
   ▼
4. バックエンドから CreateInviteResponse を受信
   │
   ├─ groupId: "grp_abc123def456"
   ├─ inviteCode: "INV-ABC123"
   ├─ inviteUrl: "https://example.com/invite/INV-ABC123"
   └─ expiresAt: DateTime(2026, 02, 23, 15, 30, 00, 000)
   │
   ▼
5. _inviteInfo に GroupInviteInfo を代入
   │
   ▼
6. setState() により再描画トリガー
   │
   ▼
7. build() 実行
   │
   ▼
8. 3行のコード実行
   │
   ├─ inviteCode = "INV-ABC123"
   ├─ qrData = "https://example.com/invite/INV-ABC123"
   └─ expiresAt = DateTime(...)
   │
   ▼
9. UI に値が表示される
```

---

## 4. 実際の画面表示

### 招待未発行時（初期状態）

```
┌────────────────────────────────────┐
│      メンバー追加                │
├────────────────────────────────────┤
│                                    │
│ GroupId入力欄: [family_group_001] │
│                                    │
│ ┌──────────────────────────────┐  │
│ │ 🔄 招待コードを再生成       │  │
│ └──────────────────────────────┘  │
│                                    │
│ このQRコードを                    │
│ スキャンしてもらってね            │
│                                    │
│ ┌──────────────────────────────┐  │
│ │                              │  │
│ │    INVITE_NOT_READY のQR     │  │ ← qrData
│ │                              │  │
│ └──────────────────────────────┘  │
│                                    │
│ または、この番号を教えてね:        │
│                                    │
│         ─────────────────          │  ← inviteCode
│      有効期限を取得中...         │  ← expiresAt
│                                    │
└────────────────────────────────────┘
```

### 招待発行後（正常状態）

```
┌────────────────────────────────────┐
│      メンバー追加                │
├────────────────────────────────────┤
│                                    │
│ GroupId入力欄: [family_group_001] │
│                                    │
│ ┌──────────────────────────────┐  │
│ │ 🔄 招待コードを再生成       │  │
│ └──────────────────────────────┘  │
│                                    │
│ このQRコードを                    │
│ スキャンしてもらってね            │
│                                    │
│ ┌──────────────────────────────┐  │
│ │                              │  │
│ │    有効な QR コード画像       │  │ ← qrData
│ │  (URLからQR生成可能)        │  │
│ │                              │  │
│ └──────────────────────────────┘  │
│                                    │
│ または、この番号を教えてね:        │
│                                    │
│     I N V - A B C 1 2 3          │  ← inviteCode
│   有効期限: 2026-02-23 15:30   │  ← expiresAt
│                                    │
└────────────────────────────────────┘
```

---

## 5. Null Safety のキーポイント

### `?.` 演算子（Conditional Member Access）
```dart
_inviteInfo?.inviteCode
// _inviteInfo が null なら null を返す
// _inviteInfo が有効なら inviteCode を返す
```

### `??` 演算子（Null Coalescing）
```dart
_inviteInfo?.inviteCode ?? '----'
// 左側が null なら右側を返す
// 左側が有効なら左側をそのまま返す
```

### `expiresAt` の Null 許容型
```dart
final expiresAt = _inviteInfo?.expiresAt;
// 型: DateTime?（nullの可能性あり）
```

---

## 6. バックエンドとの連携

### バックエンド（Python FastAPI）
```python
# backend/chat_api/app/api/group_router.py

@router.post("/group-invites", response_model=CreateInviteResponse)
async def create_group_invite(...):
    code = f"INV-{uuid4().hex[:10]}".upper()
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=5)
    
    return CreateInviteResponse(
        group_id=payload.group_id,
        invite_code=code,                    # "INV-ABC123"
        invite_url=invite_url,               # "https://.../invite/INV-ABC123"
        expires_at=expires_at.isoformat(),   # "2026-02-23T15:30:00+00:00"
    )
```

### フロント（Flutter）
```dart
// バックエンドからのレスポンスを GroupInviteInfo へマッピング
GroupInviteInfo {
  groupId: "grp_abc123def456",
  inviteCode: "INV-ABC123",              // ← これが inviteCode に
  inviteUrl: "https://.../invite/INV-ABC123",  // ← これが qrData に
  expiresAt: DateTime(2026, 02, 23, ...),     // ← これが expiresAt に
}
```

---

## 7. エラーハンドリングのフロー

```
_refreshInvite() 呼び出し
│
├─ groupId が空 → スナックバー: "GroupIdを入力してください"
│
├─ ユーザー未認証 → スナックバー: "ログイン状態が無効です"
│
├─ API呼び出し失敗 → スナックバー: "招待コード発行に失敗: <エラー>"
│
└─ 成功
   ├─ _inviteInfo に GroupInviteInfo をセット
   ├─ setState() で UI 再描画
   ├─ 3行のコードが新しい値を取得
   └─ 画面に招待コード・QR・有効期限を表示
```

---

## まとめ

| コード | 役割 | 表示される場所 |
|--------|------|-----------|
| `inviteCode` | 招待コード文字列 | 大きな36フォントで表示 |
| `qrData` | QR生成用のURL | QrImageView へ渡される |
| `expiresAt` | 有効期限 DateTime | "有効期限: ..." テキスト |

3行はすべて **`_inviteInfo` の有無に応じてデフォルト値を用意する** という同じパターンを使っています。これにより、バックエンドから招待情報が取得されるまで、画面は「準備中」の状態を表示し、取得完了後は実際の招待情報を表示します。
