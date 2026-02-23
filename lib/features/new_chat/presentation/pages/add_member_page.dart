// Flutterの基本ウィジェットセットを利用するインポート
import 'package:flutter/material.dart';
// RiverpodのConsumerWidget/ConsumerStateを使うためのインポート
import 'package:flutter_riverpod/flutter_riverpod.dart';
// 認証セッション情報を取得するプロバイダのインポート
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
// 招待発行ユースケースのプロバイダを利用するためのインポート
import 'package:group_chat_app/features/new_chat/di/create_group_invite_usecase_provider.dart';
// 招待参加ユースケースのプロバイダを利用するためのインポート
import 'package:group_chat_app/features/new_chat/di/join_group_by_invite_usecase_provider.dart';
// 招待情報のエンティティを利用するためのインポート
import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
// 破棄確認ダイアログを表示するヘルパーのインポート
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';
// カメラスキャン用ライブラリのインポート
import 'package:mobile_scanner/mobile_scanner.dart';
// QRコード描画ライブラリのインポート
import 'package:qr_flutter/qr_flutter.dart';

// メンバー追加用ページのStatefulWidget定義
class AddMemberPage extends ConsumerStatefulWidget {
  // オプションで初期の groupId を受け取れる
  final String? groupId;

  // コンストラクタ
  const AddMemberPage({super.key, this.groupId});

  // Stateオブジェクトを生成する
  @override
  ConsumerState<AddMemberPage> createState() => _AddMemberPageState();
}

// State実装部
class _AddMemberPageState extends ConsumerState<AddMemberPage> {
  // 連続スキャンや多重実行を防止するフラグ
  bool _isProcessing = false;
  // 発行された招待情報を保持する変数
  GroupInviteInfo? _inviteInfo;
  // GroupIdを編集するためのテキストコントローラ
  late final TextEditingController _groupIdController;

  // 初期化処理
  @override
  void initState() {
    super.initState();
    // コントローラを生成し、渡されたgroupIdか環境変数のデフォルト値を設定
    _groupIdController = TextEditingController(
      text:
          widget.groupId ??
          const String.fromEnvironment(
            'DEFAULT_GROUP_ID',
            defaultValue: 'family_group_001',
          ),
    );
    // ウィジェットツリー構築後に招待情報を取得する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInvite();
    });
  }

  // 破棄処理でコントローラを解放
  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  // 描画ロジック
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            // 閉じるボタン
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              // 破棄確認ダイアログを表示
              final shouldDiscard = await showDiscardDialog(context);
              if (shouldDiscard != true) {
                return;
              }
              if (!mounted) return;
              Navigator.pop(context, 'cancel');
            },
          ),
          // タイトル表示
          title: const Text(
            'メンバー追加',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          // タブバー（スキャン / 招待発行）
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.camera_alt), text: '招待を受ける'),
              Tab(icon: Icon(Icons.qr_code), text: '招待する'),
            ],
          ),
        ),
        // タブに対応するビューを表示する
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [_buildScannerTab(), _buildInviteTab()],
        ),
      ),
    );
  }

  // --- タブ1：スキャン画面（招待コード参加） ---
  Widget _buildScannerTab() {
    return Stack(
      children: [
        // カメラでQRをスキャン
        MobileScanner(
          onDetect: (capture) {
            if (_isProcessing) return;

            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final raw = barcode.rawValue;
              if (raw != null && raw.isNotEmpty) {
                // スキャン結果を処理する
                _handleJoinGroup(raw);
                break;
              }
            }
          },
        ),
        // スキャン枠の視覚表示
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        // 処理中インジケータ
        if (_isProcessing)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        // 手入力ボタン（画面下部）
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _showManualEntryDialog,
              icon: const Icon(Icons.keyboard),
              label: const Text('招待コードを手入力する'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- タブ2：招待画面（招待コード発行） ---
  Widget _buildInviteTab() {
    // 表示用の招待コードとQRデータ／有効期限を準備
    final inviteCode = _inviteInfo?.inviteCode ?? '----';
    final qrData = _inviteInfo?.inviteUrl ?? 'INVITE_NOT_READY';
    final expiresAt = _inviteInfo?.expiresAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // GroupId入力欄
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(
                labelText: '招待対象のGroupId',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // 招待コード再生成ボタン
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _refreshInvite,
                icon: const Icon(Icons.refresh),
                label: const Text('招待コードを再生成'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'このQRコードを\nスキャンしてもらってね',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // QRコード描画
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 12),
            const Text('または、この番号を教えてね：', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            // 招待コードの大きな表示
            Text(
              inviteCode,
              style: const TextStyle(
                fontSize: 36,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // 有効期限表示（取得中または日時を表示）
            Text(
              expiresAt == null
                  ? '有効期限を取得中...'
                  : '有効期限: ${expiresAt.toLocal()}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 手入力ダイアログを表示するヘルパー
  void _showManualEntryDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('コード入力'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(hintText: '招待コードを入力'),
        ),
        actions: [
          TextButton(
            // キャンセルボタン
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            // 入力されたコードで参加処理を呼ぶ
            onPressed: () {
              Navigator.pop(dialogContext);
              _handleJoinGroup(controller.text.trim());
            },
            child: const Text('参加する'),
          ),
        ],
      ),
    );
  }

  // 招待情報（QR/コード）をリフレッシュして取得する
  Future<void> _refreshInvite() async {
    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty) {
      _showSnack('GroupIdを入力してください');
      return;
    }

    // 現在の認証セッションを取得
    final currentUser = ref.read(authSessionProvider);
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _showSnack('ログイン状態が無効です。再ログインしてください');
      return;
    }

    // 処理中フラグを立ててUseCaseを呼び出す
    setState(() => _isProcessing = true);
    try {
      final useCase = ref.read(createGroupInviteUseCaseProvider);
      final info = await useCase.call(
        groupId: groupId,
        requesterUserId: userId,
        expiresInMinutes: 5,
      );
      if (!mounted) return;
      setState(() => _inviteInfo = info);
      _showSnack('招待コードを発行しました');
    } catch (e) {
      _showSnack('招待コード発行に失敗: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // スキャンまたは手入力で受け取った値から参加処理を行う
  Future<void> _handleJoinGroup(String rawData) async {
    final inviteCode = _extractInviteCode(rawData);
    if (inviteCode.isEmpty) {
      _showSnack('招待コードの形式が不正です');
      return;
    }

    final currentUser = ref.read(authSessionProvider);
    final userId = currentUser?.id;
    if (userId == null || userId.isEmpty) {
      _showSnack('ログイン状態が無効です。再ログインしてください');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final useCase = ref.read(joinGroupByInviteUseCaseProvider);
      final result = await useCase.call(inviteCode: inviteCode, userId: userId);
      if (!mounted) return;
      _showSnack('参加成功: ${result.groupName}');
      Navigator.pop(context, result.groupId);
    } catch (e) {
      _showSnack('参加に失敗しました: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 生データから招待コードだけを抽出するユーティリティ
  String _extractInviteCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // URL形式: https://host/invite/INV-XXXX
    final inviteIndex = trimmed.lastIndexOf('/invite/');
    if (inviteIndex >= 0) {
      final code = trimmed.substring(inviteIndex + '/invite/'.length).trim();
      return code.toUpperCase();
    }

    // 生コード形式ならそのまま大文字化して返す
    return trimmed.toUpperCase();
  }

  // スナックバーでメッセージを表示するヘルパー
  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
