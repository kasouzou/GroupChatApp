# ASIENTS.md — 設計指示書（DDD + 疎結合 + Clean Architecture + Defensive Security）🚀

> **目的**：本プロジェクトはドメイン（ビジネス概念）を最優先し、変更に強く、テスト可能で差し替え容易な実装を目指す。設計判断は常に「このルールはビジネス概念か？ 技術的都合か？」を基準に行う。さらにコードは「攻撃者の視点」で設計・生成することを義務とする。

---

## 1) 最終的なルール（端的）

* 依存方向を厳守：`Presentation → Application → Domain`（Infrastructure は外側で Domain の抽象を実装する）。
* Domain は純粋なビジネスモデル（エンティティ／値オブジェクト／不変条件／ドメインイベント）のみ。I/O・外部ライブラリは持ち込まない。
* 外部処理（DB, HTTP, ファイル, Queue）は **Domain に抽象（ポート）を置き**、具象は Infrastructure に置く。
* UseCase はオーケストレーター。状態遷移のルールは Domain に実装。UI更新は Repository の Stream を購読させる（原則 Presenter 不要）。
* 用語ルール：Domain に技術語（`local`/`remote`/`HTTP`/`SQLite` 等）を持ち込まない。ビジネス語彙（`persist`/`dispatch`/`markSent`/`markFailed`）を使う。

---

## 2) ディレクトリ・命名ポリシー（Dart/Flutter 想定）

```
lib/
  domain/
    message/
      message.dart
      value_objects.dart
      message_status.dart
      ports/
        message_repository.dart
        message_sender.dart
        attachment_uploader.dart
  application/
    usecases/
      send_message_usecase.dart
    services/
      retry_policy.dart (抽象)
  infrastructure/
    persistence/
      drift_message_repository.dart
      in_memory_message_repository.dart
    network/
      http_message_sender.dart
    storage/
      attachment_uploader_impl.dart
  presentation/
    pages/
      chat_page.dart
    viewmodels/
      chat_viewmodel.dart
```

* Domain 型は `Message` のような名詞。`Model` / `DTO` の語は Infra 用に限定する。

---

## 3) Domain 層のルール（何をどう書くか）

* **エンティティは可能な限り不変**。状態遷移はメソッドで新インスタンスを返すか private 管理する。
* **値オブジェクト**（例：MessageId, MessageContent）は等価性（==）を実装し、バリデーションを内包する。
* **状態遷移ロジック（invariants）** はエンティティに実装する（例：`markAsSent` は `status != sent` を検査）。
* **ドメインイベント** は Domain で定義可。イベント処理自体は Application/Infra で購読。
* **ポート（抽象）** を Domain に置く：`MessageRepository`, `MessageSender`, `AttachmentUploader`, 必要なら `RetryPolicy`（ビジネス判断ならDomainに置く）。

---

## 4) Repository / Port の設計方針

* Repository は「集合への抽象」だけ（save/find/watch）。例：

  ```dart
  abstract class MessageRepository {
    Future<void> save(Message message);      // upsert
    Future<Message?> findByLocalId(MessageId id);
    Stream<List<Message>> watchMessages(String groupId);
  }
  ```
* 送信は別ポート（`MessageSender`）に分離：

  ```dart
  abstract class MessageSender {
    Future<SendResponse> send(Message message);
  }
  ```
* Port の命名はビジネス語彙。実装（HTTP/SQLite）は Infrastructure 側で行う。

---

## 5) UseCase（Application）の責務

* UseCase はオーケストレータ：`createPending` → `repository.save` → optional upload → `sender.send` → `message.markAsSent/markAsFailed` → `repository.save`。
* UseCase は UI を直接操作しない（UI の即時反映は `watchMessages` の購読で実現）。必要に応じて `Presenter` 抽象を注入するパターンは許容するが最小化する。
* 外部時間・ID・乱数は抽象化（`IdGenerator`, `Clock`, `RandomProvider` を DI）してテスト可能にする。

---

## 6) メッセージ送信フロー（実務的な手順）

1. UI が UseCase を呼ぶ（送信ボタン）。
2. UseCase が `idGen.newId()` / `clock.nowMs()` で `Message.createPending(...)` を生成。
3. `repository.save(message)`（ローカル upsert）。
4. UI は `repository.watchMessages(groupId)` を購読しているため、即時表示される。
5. 必要なら `uploader.upload(message)` を呼び content を更新 → `repository.save(updated)`。
6. `sender.send(message)` を呼ぶ。

   * 成功：`message.markAsSent(serverId, serverSentAt)` → `repository.save(updated)`
   * 失敗：`message.markAsFailed(nextRetryAt)` → `repository.save(failed)`（RetryPolicy に応じたスケジュール）

> 実運用では `send` はバックグラウンドキューで処理する設計を推奨（WorkManager / BackgroundWorker 等）。

---

## 7) Presentation の作法

* UI は Domain の `Message` を直接描画して良い（依存方向は正）。ただし視覚化用に `ViewModel` にマッピングしても良い。
* UI は `MessageRepository.watchMessages(groupId)` を購読。Repository 側は**初回スナップショットを返す**実装にする（即時表示のため）。
* UX：ローカル保存→描画→server更新で再描画→失敗なら再送UI（ボタン）を表示、という流れを観測モデルで実現する。

---

## 8) Attachment / Upload の扱い

* Attachment のアップロードは UseCase の判断で実行（事前アップロード or server 側で受け渡す方式を要件で決定）。
* Upload 結果は `MessageContent` を差し替える形で Domain に反映し、`repository.save` で永続化する。
* `AttachmentUploader` は Domain の抽象（ポート）を定義し実装は Infra（GCS/S3等）に置く。

---

## 9) 再送（Retry）ポリシー

* `RetryPolicy` はビジネス決定なら Domain 抽象に置く（例：重要メッセージは 5 回リトライ）。技術的バックオフのみなら Application に置く。
* 計算は純粋関数（`nextDelayMs(currentRetryCount)`）で実装してテスト容易にする。
* retry を永続化したキュー（Infrastructure）で管理する場合、UseCase はそのキックのみを行う。

---

## 10) テスト設計

* Domain 単体テスト：`Message` の状態遷移と値オブジェクトのバリデーション。外部依存なし。
* UseCase 単体テスト：`MessageRepository` / `MessageSender` / `AttachmentUploader` / `IdGenerator` / `Clock` をモックして正常系・異常系を網羅。
* Integration テスト：DB 実装（Drift）＋ Simulated Sender で `watchMessages` の stream 発火検証。
* E2E：バックグラウンド送信・ネットワーク遮断等を含む。

---

## 11) 実装上の注意（必須）

* Domain ファイルに `dart:io` / `http` / DB ライブラリを import しない。
* UseCase は副作用を抽象に委譲。外部依存はコンストラクタ注入（DI）する。
* `IdGenerator` / `Clock` を DI して deterministic テストを可能にする。
* 抽象（Port）は Domain 層に置き、具象は Infrastructure に置く。
* 層ごとに名前空間を分ける（`domain`, `application`, `infrastructure`, `presentation`）。
* `watchMessages` は初回スナップショットを返す実装にする（UI 即時表示のため）。
* DB 実装は upsert をサポートする（`save` で insert/update を包括）。

---

## 12) 非機能要件（運用・プライバシー）

* 通信は TLS（HTTPS/WSS）を必須。認証はトークン（Bearer）方式推奨。
* 機密情報は環境変数/シークレットマネージャで管理。コードに直書きしない。
* ログは必要最小限にし、メッセージ本文など機密データは平文で出力しない（Masking）。
* 監視：送信失敗率・再送増加をメトリクス化しアラート設定する。

---

## 13) コードレビュー / PR チェックリスト

* 依存方向が守られているか？（Presentation → Application → Domain）
* Domain に技術語（`local`/`HTTP` 等）が入り込んでいないか？
* 値オブジェクトに不変バリデーションがあるか？
* 抽象（Port）は Domain に、実装は Infra にあるか？
* IdGenerator / Clock / Random が DI されているか？
* `watchMessages` の stream は初回スナップショットを返すか？
* 単体テストが追加されているか？（Domain・UseCase の主要分岐）

---

## 14) エージェント（AI／自動化）向け短縮指示

* 「この変更は Domain のルールか？」 → Yes: Domain。No: Application/Infrastructure。
* 「UseCase が UI を直接更新しているか？」 → していればリファクタ：Repository の Stream / Presenter 抽象へ移す。
* 「新しい外部依存を追加する場合」 → まず Domain に抽象を定義し、Infra 実装は別 PR で追加。
* テスト：Domain 変更は Domain 単体テスト必須。UseCase 分岐が変わる場合は UseCase テスト追加。

---

## 15) 付録：最小限の Domain ポート例（Dart）

```dart
// domain/ports/message_repository.dart
abstract class MessageRepository {
  Future<void> save(Message message);               // upsert
  Future<Message?> findByLocalId(MessageId id);
  Stream<List<Message>> watchMessages(String groupId);
}

// domain/ports/message_sender.dart
class SendResponse { final String serverId; final int serverSentAtMs; SendResponse(this.serverId, this.serverSentAtMs); }
abstract class MessageSender {
  Future<SendResponse> send(Message message);
}
```

---

## 16) 防御的セキュリティ設計 (Defensive Security Engineering) 🔐

> AI / 開発者は常に「攻撃者の視点」を持ち、以下の脅威を想定してコード・アーキテクチャを設計すること。各対処はコード生成時・実装時の必須ガイドライン。

### 1. インジェクション攻撃（Injection）

* **脅威**: SQLi / NoSQLi / OSコマンド注入。
* **必須対処**：

  * ユーザー入力を直接クエリに埋め込まない。必ず **プリペアドステートメント** または型安全な ORM / Query Builder を使う。
  * 動的 SQL を避ける。動的生成が必要な場合は、ホワイトリスト検証を行い、文字列連結を廃止する。
  * OSコマンド実行が必要な場合は、実行パスとパラメータを厳格なホワイトリストで検証し、外部入力は一切渡さない。

### 2. 認証・認可の不備（Broken Access Control）

* **脅威**: ID 列挙 / BOLA / IDOR（他人リソースへの不正アクセス）。
* **必須対処**：

  * リソースアクセス時は必ず所有権チェック：DB クエリレベルで `WHERE id = ? AND owner_id = ?` のように所有者で制限する。
  * ドメインサービスやユースケース境界で権限（Role-Based / Attribute-Based）を再評価すること。UIレイヤでのチェックだけに頼らない。
  * トークンは短命にし、リフレッシュの仕組みと不正検知（多重ログイン検出）を実装する。

### 3. 機密データの露出と安全な管理

* **脅威**: APIキーや平文パスワードのソース混入。
* **必須対処**：

  * パスワードは `Argon2` または `bcrypt` などの強力な KDF でハッシュ化（ソルト必須）。Plaintext 禁止。
  * 機密情報は環境変数 / シークレットマネージャ（クラウド KMS 等）から取得し、コード・ログには出力しない（ログはマスク）。
  * 設定ファイル等も secrets を含まないテンプレのみをリポジトリに含める。CI のシークレット管理は必須。

### 4. 脆弱なライブラリと依存関係（Supply-Chain）

* **脅威**: サプライチェーン攻撃、古いライブラリの脆弱性。
* **必須対処**：

  * 依存パッケージの選定時にメンテ状況・CVE を確認する。定期的な依存性スキャン（OSS スキャナ）を CI に組み込む。
  * 重要なライブラリは LTS を選び、セキュリティアップデートは迅速に適用する。
  * フロント/バックで共通のバリデーションロジック（SSOT）を維持し、入力検証を二重で行う（フロントは UX、バックはセキュリティ目的）。

### 5. セキュリティ・バイ・デザイン

* **最小権限（Least Privilege）**：実行プロセスや DB ユーザーには必要最低限の権限のみ付与する。DB ユーザーは CRUD のうち必要な操作のみ許可する。
* **フェイルセーフ**：エラーが発生したら詳細情報をユーザに返さない（`Internal Server Error` 等の抽象メッセージ）。ログには詳細を書くが、ログアクセスは制限する。
* **入力検証**：境界で必ず入力検証（型・長さ・正規表現・ドメイン制約）を行う。Domain 側の値オブジェクトにも検証を重ねる（防御的二重検査）。
* **暗号化**：保存すべき機密データは静的（at rest）で暗号化を検討する（DB のカラム暗号化やストレージ暗号化）。通信は常に TLS。
* **監査ログ**：送信失敗の急増や大量削除などは監査ログに残し、SIEM/監視でアラート化する。ログは改ざん検知を検討する（必要に応じ HMAC 付与等）。

---

## 17) セキュリティ実装ガイド（具体的チェックリスト）

* DB クエリはすべてパラメータバインディングを使っているか。
* すべてのエンドポイントで認可が検証されているか（owner check を DB レベルで行っているか）。
* パスワード保存は安全なハッシュ（Argon2 / bcrypt）か。
* シークレットは環境変数 / シークレットマネージャで管理され、CI/CD にハードコードされたキーが無いか。
* 依存ライブラリの脆弱性スキャンを CI に組込んでいるか。
* ログに機密情報が出ていないか（例：メッセージ本文、APIキー）。
* エラーメッセージが内部情報を露出していないか（ユーザー向けは抽象化）。

---
