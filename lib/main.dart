import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:group_chat_app/core/network/network_awareness_widget.dart';
import 'package:group_chat_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:group_chat_app/shared/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Chat App',
      theme: AppTheme.light(context),
      // 💡 ここがポイント！全画面の Scaffold を強制的にラップする。
      // オフライン／オンラインを監視してオフラインならどの画面に居ても通知を出せる。
      // 要ははアプリ全体を包んでいるイメージ
      builder: (context, child) {
        return NetworkAwarenessWrapper(child: child!);
      },
      home: const SplashScreenPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
