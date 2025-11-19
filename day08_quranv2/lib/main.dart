import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:day08_quranv2/ui/view/surah_list_screen.dart';
import 'package:dio/dio.dart';
import 'package:day08_quranv2/data/service/quran_service.dart';
import 'package:day08_quranv2/bloc/quran_audio/quran_audio_bloc.dart';
import 'package:audioplayers/audioplayers.dart';

// Thème islamique personnalisé
class QuranTheme {
  static const Color primaryGreen = Color(0xFF2E7D32); // Vert profond du Coran
  static const Color lightGreen = Color(0xFF66BB6A); // Vert clair
  static const Color gold = Color(0xFFFFB300); // Or doré
  static const Color cream = Color(0xFFFFF8E1); // Crème
  static const Color darkBrown = Color(0xFF5D4037); // Brun foncé

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.light,
      primary: primaryGreen,
      secondary: gold,
      surface: Colors.white,
      error: Colors.red.shade600,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkBrown,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkBrown,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryGreen,
      brightness: Brightness.dark,
      primary: lightGreen,
      secondary: gold,
      surface: const Color(0xFF1E1E1E),
      error: Colors.red.shade400,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardTheme(
      elevation: 4,
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: Colors.white70,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.white70,
      ),
    ),
  );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<QuranService>(
          create: (context) => QuranService(Dio()),
        ),
        RepositoryProvider<AudioPlayer>(
          create: (context) => AudioPlayer(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<QuranAudioBloc>(
            create: (context) => QuranAudioBloc(
              quranService: context.read<QuranService>(),
              audioPlayer: context.read<AudioPlayer>(),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'القرآن الكريم',
          theme: QuranTheme.lightTheme,
          darkTheme: QuranTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: SurahListScreen(),
        ),
      ),
    );
  }
}
