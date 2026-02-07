// 編集内容破棄の確認ダイアログを表示する関数
import 'package:flutter/material.dart';

Future<bool?> showDiscardDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(240, 25, 25, 35),
          title: const Text(
            '編集を破棄しますか？',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            '変更内容は保存されません。',
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('キャンセル', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(230, 220, 70, 70),
              ),
              child: const Text('破棄する', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }