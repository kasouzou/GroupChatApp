import 'package:flutter/material.dart';
import 'package:genron/pages/splash_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Google Fontsを使うために必要

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Genron',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        // アプリ全体のテキストテーマを Google Fonts で上書きする
        textTheme: GoogleFonts.notoSansJpTextTheme(
          Theme.of(context).textTheme, 
        ),
      ),
      home: const SplashScreenPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}