import 'package:flutter/material.dart';
import 'package:day08_quranv2/ui/view/surah_download_demo_simple.dart';

/// Point d'entrée principal pour la démo de téléchargement de sourates
void main() {
  runApp(const QuranDownloadDemoApp());
}

class QuranDownloadDemoApp extends StatelessWidget {
  const QuranDownloadDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Audio Download Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SurahDownloadDemoSimple(),
      debugShowCheckedModeBanner: false,
    );
  }
}
