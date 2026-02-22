# GroupChatApp - 各ページの処理フロー詳細解説

本アプリケーションは **クリーンアーキテクチャ** に基づいており、Riverpodを使った状態管理と、StreamBuilderを活用したリアルタイムデータ購読が特徴です。

---　

## 📱 **1. スプラッシュスクリーン（Splash Screen）**
**ファイル**: lib/features/auth/presentation/pages/splash_screen.dart

### 処理フロー
```
アプリ起動
    ↓
[initState] → SystemChrome設定（ステータスバー非表示）
    ↓
_navigateToNextScreen() 実行
    ├─ 4秒待機（ユーザーに画面を見せる）
    ├─ GoogleSignIn初期化
    ├─ attemptLightweightAuthentication() → サイレント復元試行
    │   ├─ 成功 → remote.loginWithGoogleToken() で既存セッション復元
    │   └─ 失敗 → キャッチして続行
    │
    └─ 認証状態判定
        ├─ currentUser != null → YoutubeLikeBottomNavigationBar へ
        └─ currentUser == null → LoginPage へ
```

### 主要な処理
- `authSessionProvider` で現在のユーザー状態を確認
- GoogleSignInの **軽量認証** でトークン復元を試み、既ログインユーザーを自動ログイン
- `Navigator.pushReplacement()` で画面遷移（スタックを置き換え）

---

## 🔐 **2. ログイン画面（Login Page）**
**ファイル**: lib/features/auth/presentation/pages/login_page.dart

### 処理フロー
```
ログイン画面表示
    ↓
Googleサインインボタン表示
    ↓
ユーザーがボタンをタップ
    ├─ _handleSignIn() 実行
    │   ├─ _isSigningIn = true（連続送信防止）
    │   ├─ googleLoginUseCaseProvider から UseCase取得
    │   ├─ useCase.signIn() 実行
    │   │   └─ Googleでログイン → RemoteDataSourceでバックエンド認証
    │   ├─ user != null → authSessionProvider に保存
    │   └─ _isSigningIn = false
    │
    └─ ログイン成功 → YoutubeLikeBottomNavigationBar へ
       ログイン失敗 → SnackBar でエラー表示
```

### 主要な処理
- `googleLoginUseCaseProvider` から UseCase を取得
- Google認証 → バックエンド検証の一連の流れ
- `authSessionProvider` に保存して、他のページで参照可能に

---

## 📋 **3. チャット一覧画面（My Chats Page）**
**ファイル**: lib/features/chat/presentation/pages/my_chats_page.dart

### 処理フロー
```
画面初期化
    ↓
ref.watch(fetchMyChatsUseCaseProvider) → UseCase取得
    ↓
StreamBuilder で watchMyChats() を購読
    └─ Repository が 5秒ごとにポーリング
    └─ チャット一覧をストリーム配信
    
画面表示
├─ SearchBar で グループ名/GroupId 検索
│   └─ onChange → setState() で _applySearchAndSort()
│
├─ ソートタブ（未読順/最新順/人気順）
│   └─ _selectedSortIndex を変更 → _applySearchAndSort() 再実行
│
└─ チャットカード一覧表示
    └─ ユーザーがカードをタップ
        └─ ChatPage へ navigate（rootNavigator: true）
        
_applySearchAndSort() の流れ
├─ 検索キーワードでフィルタ（groupName/groupId/lastMessagePreview）
└─ ソート順に応じた並べ替え
    ├─ 未読順: unreadCount降順 → lastMessageAt降順
    ├─ 最新順: lastMessageAt降順
    └─ 人気順: memberCount降順 → lastMessageAt降順
```

### 主要な処理
- `watchMyChats()` でストリーム購読（リアルタイム更新）
- フロント側で検索・ソート処理を集約（UIの責務として明確化）
- `StreamBuilder` でデータ変更時に自動リビルド

---

## 💬 **4. チャット画面（Chat Page）**
**ファイル**: lib/features/chat/presentation/pages/chat_page.dart

### 処理フロー
```
チャット画面初期化
    ├─ [initState]
    │   ├─ groupId, groupName, currentUserId を保持
    │   ├─ authSessionProvider から currentUser 取得
    │   └─ WidgetsBinding.addPostFrameCallback で ChatNotifier 設定
    │       └─ setChatContext(groupId, currentUserId, currentUserRole)
    │
    └─ [build]
        ├─ chatRepositoryProvider から Repository 取得
        ├─ chatNotifierProvider から UI状態監視
        │
        └─ メッセージ表示部分
            └─ StreamBuilder: repository.watchMessages(groupId)
                ├─ ConnectionState.waiting → CircularProgressIndicator
                ├─ snapshot.data = null → メッセージなし表示
                └─ messages 配信
                    └─ ListView.builder で各メッセージを _buildMessageBubble()
                        └─ isMe ? 右寄せ(緑) : 左寄せ(白)

入力・送信処理
    ├─ ユーザーが TextField に入力
    │
    └─ 送信ボタンタップ
        └─ _sendMessage(text) 実行
            ├─ text.trim() が空でないか確認
            ├─ _textController.clear()
            └─ chatNotifierProvider.notifier.sendMessage(text)
                └─ ChatNotifier.sendMessage() 実行
                    ├─ state = state.copyWith(isSending: true)
                    ├─ sendMessageUseCaseProvider から UseCase取得
                    ├─ useCase.execute(groupId, userId, role, TextContent)
                    │   └─ バックエンド送信
                    ├─ 成功 → state = state.copyWith(isSending: false)
                    └─ 失敗 → errorMessage 設定 + SnackBar表示
```

### 主要な処理
- `ref.read(authSessionProvider)` でログインユーザー特定
- `repository.watchMessages(groupId)` で 3秒ごとのポーリング
- `ChatNotifier` で送信状態を一元管理（isSending, errorMessage）
- メッセージの自分/他人判定で表示スタイルを分岐

---

## ➕ **5. 新規チャット/メンバー追加ハブ（New Chat Page）**
**ファイル**: lib/features/new_chat/presentation/pages/new_chat_page.dart

### 処理フロー
```
ハブ画面表示
    ├─ MediaQuery で画面向き判定（縦/横）
    │   └─ isLandscape = true → Flex(direction: horizontal)
    │   └─ isLandscape = false → Flex(direction: vertical)
    │
    └─ 2つのメインボタン表示
        ├─ 「チャット作成」ボタン
        │   └─ タップ → MakeChatPage へ push
        │
        └─ 「メンバー追加」ボタン
            └─ タップ → AddMemberPage へ push
```

### 主要な処理
- `LayoutBuilder` で親の制約情報を取得
- `ConstrainedBox` と `SingleChildScrollView` でレスポンシブ対応
- `Flex` で縦横の方向を動的に切り替え

---

## 🆕 **6. チャット作成画面（Make Chat Page）**
**ファイル**: lib/features/new_chat/presentation/pages/make_chat_page.dart

### 処理フロー
```
チャット作成画面表示
    ├─ TextEditingController: _chatNameController
    │
    ├─ 権限管理 Map<String, bool>
    │   ├─ add_member: false（デフォルトOFF）
    │   ├─ delete_member: true
    │   ├─ can_speak: true
    │   ├─ change_settings: true
    │   ├─ delete_message: false
    │   └─ pin_message: false
    │
    └─ UI 構成
        ├─ チャット名 TextField
        ├─ CheckboxListTile × 6個（権限選択）
        │   └─ onChanged → setState() で _permissions[key] 更新
        │
        └─ 保存ボタン
            └─ _onSavePressed() 実行
                ├─ チャット名バリデーション（空でないか）
                ├─ _isSaving = true
                ├─ authSessionProvider から creatorUserId 取得
                ├─ createChatUsecaseProvider から UseCase取得
                ├─ useCase.call(name, creatorUserId, memberIds)
                │   └─ バックエンド: グループ作成
                ├─ 成功 → groupId を返す → Navigator.pop(context, groupId)
                └─ 失敗 → SnackBar でエラー表示
```

### 主要な処理
- ローカル状態管理（TextEditingController + Map + bool）
- 権限設定を疎結合な Map で管理（拡張性向上）
- `createChatUsecaseProvider` で DI 経由で UseCase取得

---

## 👥 **7. メンバー追加画面（Add Member Page）**
**ファイル**: lib/features/new_chat/presentation/pages/add_member_page.dart

### 処理フロー
```
メンバー追加画面表示（DefaultTabController）
    ├─ Tab 1: 「招待を受ける」（スキャンタブ）
    │   ├─ MobileScanner 起動
    │   │   ├─ カメラで QR/バーコード検知
    │   │   ├─ _isProcessing = true（連続スキャン防止）
    │   │   ├─ barcode.rawValue を取得
    │   │   └─ _handleJoinGroup(code) 実行
    │   │       └─ バックエンドへ参加リクエスト
    │   │
    │   ├─ スキャン枠（ビジュアル）
    │   │
    │   ├─ 処理中インジケーター（_isProcessing = true時）
    │   │
    │   └─ 手入力エスケープ
    │       └─ キーボードアイコンボタン
    │           └─ _showManualEntryDialog()
    │               └─ 招待コード手入力ダイアログ表示
    │
    └─ Tab 2: 「招待する」（QRコード発行タブ）
        ├─ QrImageView で QRコード表示
        │   └─ data = _qrData（グループ参加URL）
        │
        ├─ 招待コード表示（"123-456"）
        │   └─ コピーボタンで クリップボードへ
        │
        └─ SNS共有ボタン
            └─ url_launcher で URL起動
```

### 主要な処理
- `DefaultTabController` で 2タブ管理
- `MobileScanner` でカメラ起動（QR/バーコード検知）
- `_isProcessing` フラグで連続スキャン防止
- `QrImageView` で QRコード動的生成
- `url_launcher` で 外部URLを開く

---

## 👤 **8. プロフィール画面（Profile Page）**
**ファイル**: lib/features/profile/presentation/pages/profile_page.dart

### 処理フロー
```
プロフィール画面初期化
    ├─ [initState]
    │   └─ WidgetsBinding.addPostFrameCallback
    │       ├─ authSessionProvider から userId 取得
    │       └─ profileNotifierProvider.notifier.loadUser(userId)
    │           └─ バックエンドからユーザー情報を非同期取得
    │
    └─ [build]
        ├─ ref.watch(profileNotifierProvider)
        │   └─ ProfileUiModel（user, editingName, editingPhotoUrl等）
        │
        ├─ AppBar
        │   └─ 設定アイコン（右上）
        │       └─ _isSettingsPressed で press/release状態を管理
        │           └─ Icons.settings（塗りつぶし） ↔ Icons.settings_outlined（線）
        │
        └─ プロフィール情報表示
            ├─ ユーザープロトタイプ画像
            ├─ ユーザー名
            ├─ プロフィール説明
            │
            ├─ 「プロフィール編集」ボタン
            │   └─ _openProfileEdit() 実行
            │       ├─ state.user が未ロードならロード
            │       ├─ notifier.startEditing() で編集モード移行
            │       └─ Navigator.push → ProfileEditPage
            │
            └─ 設定アイコンタップ
                └─ _openSettings() 実行
                    └─ Navigator.push → SettingsPage
                        （rootNavigator: true でボトムバーを隠す）
```

### 主要な処理
- `profileNotifierProvider.notifier.loadUser(userId)` で非同期ロード
- `ref.watch(profileNotifierProvider)` で状態を監視（編集後は自動リビルド）
- アイコンの press/release を `_isSettingsPressed` でトラッキング
- `rootNavigator: true` で モーダル的に画面を開く（ボトムバー非表示）

---

## ✏️ **9. プロフィール編集画面（Profile Edit Page）**
**ファイル**: lib/features/profile/presentation/pages/profile_edit_page.dart

### 処理フロー
```
プロフィール編集画面初期化
    ├─ [initState]
    │   ├─ _nameController = TextEditingController()
    │   │
    │   └─ WidgetsBinding.addPostFrameCallback
    │       ├─ profileNotifierProvider.notifier.startEditing()
    │       │   └─ state.user の情報を editingName, editingPhotoUrl にコピー
    │       │
    │       └─ _nameController.text = editingName（初期値セット）
    │
    ├─ ref.listen (editingName の変更を監視)
    │   └─ _nameController.text を追従（入力中でなければ）
    │       └─ カーソル位置を末尾に戻す
    │
    └─ [build]
        ├─ ref.watch (editingPhotoUrl)
        │   └─ プロフィール画像を表示
        │
        ├─ ref.watch (isSaving)
        │   └─ 保存中なら ボタン無効化 + グルグル表示
        │
        ├─ ref.listen (errorMessage)
        │   └─ エラー発生時に SnackBar表示
        │
        └─ UI
            ├─ プロフィール画像選択
            │   └─ タップ → ImagePicker で写真選択
            │       → ImageCropper で トリミング
            │       → notifier.setEditingPhotoUrl() で状態更新
            │
            ├─ 名前入力 TextField
            │   └─ onChange → notifier.updateEditingName(newName)
            │
            ├─ 保存ボタン
            │   └─ notifier.save() 実行
            │       └─ バックエンド送信 → リモート保存
            │
            └─ × 閉じるボタン
                └─ showDiscardDialog() で 確認
                    └─ 「いいえ」→ 編集継続
                    └─ 「はい」→ notifier.cancelEditing() → Navigator.pop()
```

### 主要な処理
- `startEditing()` で 編集前の状態をコピー（キャンセル時に復元可能）
- `ref.listen()` で `editingName` 変更を追従（TextEditingController更新）
- `ImagePicker` + `ImageCropper` で 写真選択・トリミング
- `isSaving` と `errorMessage` を監視して UI反映
- `cancelEditing()` で ユーザーが ×ボタンで破棄時に state.user へ復帰

---

## ⚙️ **10. 設定画面（Settings Page）**
**ファイル**: lib/features/profile/presentation/pages/settings_page.dart

### 処理フロー
```
設定画面表示
    ├─ AppBar
    │   ├─ × 閉じるボタン
    │   │   └─ Navigator.pop(context, 'done')
    │   │
    │   └─ タイトル: 「設定」
    │
    └─ CustomScrollView
        ├─ SliverSafeArea (top: true, bottom: false)
        │   └─ SliverPadding
        │       └─ SliverToBoxAdapter
        │           └─ Column（複数の設定タイル）
        │
        ├─ 設定タイル一覧
        │   ├─ 通知設定 → print("通知設定へ遷移")
        │   ├─ テーマカラー → print("テーマカラーへ遷移")
        │   ├─ プライバシーポリシー → print("プライバシーポリシーへ遷移")
        │   └─ 利用規約 → print("利用規約へ遷移")
        │
        └─ 下部余白（SizedBox height: 120）
            └─ ボトムナビゲーションバーとの干渉を避ける
```

### 主要な処理
- `SliverSafeArea` で ステータスバー回避（top: true）+ ボトムバー透過（bottom: false）
- `_buildSettingsTile()` で 各設定項目を共通化
- 下部に固定の余白（120px）を確保（島型ナビゲーションバーとの干渉防止）
- 現在の実装は `print()` のみで、将来の拡張ポイント

---

## 🎬 **11. ボトムナビゲーションバー（Navigation Hub）**
**ファイル**: lib/ui/youtube_like_bottom_navigation_bar.dart

### 処理フロー
```
ボトムナビゲーションバー初期化
    ├─ selectedTabIndex = 0（最初はチャット一覧）
    ├─ navigatorKeys = List.generate(3) で 3つの GlobalKey<NavigatorState> 作成
    │   ├─ navigatorKeys[0]: MyChatsPage 用
    │   ├─ navigatorKeys[1]: NewChatPage 用
    │   └─ navigatorKeys[2]: ProfilePage 用
    │
    └─ [build]
        ├─ Scaffold(extendBody: true)
        │   └─ body が bottomNavigationBar の背後まで伸びる
        │
        ├─ IndexedStack(index: selectedTabIndex)
        │   ├─ children[0] = _buildTabNavigator(0, MyChatsPage())
        │   ├─ children[1] = _buildTabNavigator(1, NewChatPage())
        │   └─ children[2] = _buildTabNavigator(2, ProfilePage())
        │
        └─ BottomNavigationBar
            ├─ 3個の BottomNavigationBarItem
            ├─ onTap = _onTapBottomNavItem(index)
            │   └─ selectedTabIndex = index
            │   └─ setState() → IndexedStack リビルド
            │
            ├─ selectedItemColor: 黄色（#FFAF00）
            └─ unselectedItemColor: 白

タブ間の状態保持
    └─ IndexedStack により、非表示タブも メモリに保持
        └─ 戻ると以前の状態が復元される
```

### 主要な処理
- `IndexedStack` で 各ページを非表示時も保持（スクロール位置等の状態維持）
- `extendBody: true` でボトムバーを透かして背後に body を伸ばす
- `Theme.copyWith()` で wave ripple を全消去（`splashFactory: NoSplash.splashFactory`）
- `Material` を transparent にして、黒背景を防止

---

## 🏗️ **アーキテクチャの全体像**

```
┌─────────────────────────────────────────┐
│      Presentation Layer (UI)             │
│  Pages + Widgets + Notifier/Provider    │
└────────────────┬────────────────────────┘
                 ↓
        ┌────────────────────┐
        │  Riverpod DI容器   │
        │  (Provider定義)    │
        └────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│    Application Layer (UseCase)           │
│  ビジネスロジック集約層                  │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│      Domain Layer (Entity + Interface)   │
│  純粋なビジネスルール                    │
└────────────────┬────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│       Data Layer (Repository Impl)       │
│  ├─ RemoteDataSource (HTTP/FastAPI)     │
│  ├─ LocalDataSource (SQLite)            │
│  └─ Repository (統合)                    │
└─────────────────────────────────────────┘
```

---

## 🔄 **データフロー（Chat機能の例）**

```
ChatPage（UI層）
    ↓
StreamBuilder: watchMessages(groupId)
    ↓
ChatRepository.watchMessages()
    ├─ LocalDataSource: キャッシュ初期化
    └─ RemoteDataSource: 3秒ごとのポーリング
    ↓
StreamController.add(messages)
    ↓
ChatPage（UI再描画）
```

各ページは **Riverpod** で Provider/Notifier を経由し、 **リアルタイム更新** と **離散的な操作** を統一的に管理しています。
