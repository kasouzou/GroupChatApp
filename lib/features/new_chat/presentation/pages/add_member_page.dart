import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:group_chat_app/features/auth/di/auth_session_provider.dart';
import 'package:group_chat_app/features/new_chat/di/create_group_invite_usecase_provider.dart';
import 'package:group_chat_app/features/new_chat/di/join_group_by_invite_usecase_provider.dart';
import 'package:group_chat_app/features/new_chat/domain/entities/group_invite_info.dart';
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddMemberPage extends ConsumerStatefulWidget {
  final String? groupId;

  const AddMemberPage({super.key, this.groupId});

  @override
  ConsumerState<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends ConsumerState<AddMemberPage> {
  // 連続スキャン/多重実行の防止フラグ
  bool _isProcessing = false;
  GroupInviteInfo? _inviteInfo;
  late final TextEditingController _groupIdController;

  @override
  void initState() {
    super.initState();
    _groupIdController = TextEditingController(
      text:
          widget.groupId ??
          const String.fromEnvironment(
            'DEFAULT_GROUP_ID',
            defaultValue: 'family_group_001',
          ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshInvite();
    });
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () async {
              final shouldDiscard = await showDiscardDialog(context);
              if (shouldDiscard != true) {
                return;
              }
              if (!mounted) return;
              Navigator.pop(context, 'cancel');
            },
          ),
          title: const Text(
            'メンバー追加',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.camera_alt), text: '招待を受ける'),
              Tab(icon: Icon(Icons.qr_code), text: '招待する'),
            ],
          ),
        ),
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
        MobileScanner(
          onDetect: (capture) {
            if (_isProcessing) return;

            final barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final raw = barcode.rawValue;
              if (raw != null && raw.isNotEmpty) {
                _handleJoinGroup(raw);
                break;
              }
            }
          },
        ),
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
        if (_isProcessing)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
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
    final inviteCode = _inviteInfo?.inviteCode ?? '----';
    final qrData = _inviteInfo?.inviteUrl ?? 'INVITE_NOT_READY';
    final expiresAt = _inviteInfo?.expiresAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _groupIdController,
              decoration: const InputDecoration(
                labelText: '招待対象のGroupId',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
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
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
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

  Future<void> _refreshInvite() async {
    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty) {
      _showSnack('GroupIdを入力してください');
      return;
    }

    final currentUser = ref.read(authSessionProvider);
    const fallbackUserId = String.fromEnvironment(
      'CHAT_USER_ID',
      defaultValue: 'user-001',
    );
    final userId = currentUser?.id ?? fallbackUserId;

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

  Future<void> _handleJoinGroup(String rawData) async {
    final inviteCode = _extractInviteCode(rawData);
    if (inviteCode.isEmpty) {
      _showSnack('招待コードの形式が不正です');
      return;
    }

    final currentUser = ref.read(authSessionProvider);
    const fallbackUserId = String.fromEnvironment(
      'CHAT_USER_ID',
      defaultValue: 'user-001',
    );
    final userId = currentUser?.id ?? fallbackUserId;

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

  String _extractInviteCode(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // URL形式: https://host/invite/INV-XXXX
    final inviteIndex = trimmed.lastIndexOf('/invite/');
    if (inviteIndex >= 0) {
      final code = trimmed.substring(inviteIndex + '/invite/'.length).trim();
      return code.toUpperCase();
    }

    // 生コード形式
    return trimmed.toUpperCase();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
