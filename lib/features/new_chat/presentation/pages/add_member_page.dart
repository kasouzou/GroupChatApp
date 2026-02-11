import 'package:flutter/material.dart';
import 'package:group_chat_app/shared/widgets/show_discard_dialog.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart'; // ★ URLを開くために追加

class AddMemberPage extends StatefulWidget {
  const AddMemberPage({super.key});

  @override
  State<AddMemberPage> createState() => _AddMemberPageState();
}

class _AddMemberPageState extends State<AddMemberPage> {
  // ★ 独自変数：デモ用招待コード
  final String _inviteCode = "123-456";
  // ★ 独自変数：スキャン用のデータ（ディズニーランドのURL）
  final String _qrData = "https://www.tokyodisneyresort.jp/tdl/";
  
  // ★ 状態管理変数：連続スキャンを防ぐためのフラグ
  bool _isProcessing = false;

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
            debugPrint('×ボタンが押されました。編集を破棄して戻ります。(メンバー追加画面)');
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
          physics: const NeverScrollableScrollPhysics(), // スキャン中の誤操作防止
          children: [
            _buildScannerTab(),
            _buildInviteTab(),
          ],
        ),
      ),
    );
  }

  // --- タブ1：スキャン画面 ---
  Widget _buildScannerTab() {
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            // ★ フラグチェック：処理中なら何もしない（ガード節）
            if (_isProcessing) return;

            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              final String? code = barcode.rawValue;
              if (code != null) {
                debugPrint('QRコードを検知: $code');
                _handleJoinGroup(code); // 処理開始
                break; // 1つ見つけたらループを抜ける
              }
            }
          },
        ),
        // スキャン枠のデザイン
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
        // 処理中のインジケーター（ロード中なら出す）
        if (_isProcessing)
          const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          
        // 手入力への逃げ道
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _showManualEntryDialog(),
              icon: const Icon(Icons.keyboard),
              label: const Text('招待コードを手入力する'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- タブ2：招待画面（親がQRを見せる想定） ---
  Widget _buildInviteTab() {
    return SingleChildScrollView( // ★ 追加：これで縦方向の溢れを解消
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
      child: Center( // ★ 中央寄せを維持するために追加
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'このQRコードを\nスキャンしてもらってね',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            
            // 組み込みウィジェット：QRコード
            QrImageView(
              data: _qrData,
              version: QrVersions.auto,
              size: 250.0,
              backgroundColor: Colors.white,
            ),
            
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'または、この番号を教えてね：',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            
            // 招待コードを大きく表示
            Text(
              _inviteCode,
              style: const TextStyle(
                fontSize: 48,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            
            const SizedBox(height: 10),
            const Text(
              '※ 5分間だけ有効です',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            
            // ★ マクロな視点：スクロール可能になったので、下に余白を追加
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- ロジック：手入力ダイアログ ---
  void _showManualEntryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コード入力'),
        content: const TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '6桁の番号を入力'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('参加する')),
        ],
      ),
    );
  }

  // --- ★ ロジック：URLを開く処理（非同期） ---
  Future<void> _handleJoinGroup(String data) async {
    // 1. まずフラグを立てて、連続スキャンをブロックする
    setState(() {
      _isProcessing = true;
    });

    try {
      final Uri url = Uri.parse(data);

      // 2. ユーザーに確認ダイアログを出す（セキュリティ配慮）
      // いきなりブラウザが開くとびっくりするし、悪意あるサイトへの誘導を防ぐため
      if (!mounted) return;
      final bool? shouldOpen = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ページを開きますか？'),
          content: Text('以下のURLをブラウザで開きます。\n$data'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('開く'),
            ),
          ],
        ),
      );

      // 3. 「開く」が押されたら実際にブラウザを起動
      if (shouldOpen == true) {
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // アプリ内ではなく、Chrome/Safariで開く
          );
        } else {
          throw 'URLを開けませんでした: $url';
        }
      }
    } catch (e) {
      debugPrint('エラー発生: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無効なQRコード、またはURLを開けませんでした')),
        );
      }
    } finally {
      // 4. 処理が終わったら（またはキャンセルしたら）少し待ってからフラグを戻す
      // すぐに戻すと、まだカメラにQRが映っていて再検知しちゃうから
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}