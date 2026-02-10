import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';// Google Fontsを使うために必要
import 'package:group_chat_app/common/network_status_manager/ui/NetworkAwarenessWrapper.dart';
import 'package:group_chat_app/pages/splash_screen.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Group Chat App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // アプリ全体のテキストテーマを Google Fonts で上書きする
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme, 
        ),
      ),
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