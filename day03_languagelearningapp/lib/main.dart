import 'package:day03_languagelearningapp/screens/homePage.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(LanguageApp());
}

class LanguageApp extends StatelessWidget {
  const LanguageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}
