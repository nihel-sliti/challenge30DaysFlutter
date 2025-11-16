import 'package:day07_alquran/data/models/quran_models.dart';
import 'package:day07_alquran/data/services/quran_service.dart';
import 'package:day07_alquran/ui/views/surah_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late final QuranService _quranService;
  late Future<List<SurahModel>> _futureSurahs;

  @override
  void initState() {
    super.initState();
    _quranService = QuranService(Dio());
    _futureSurahs = _quranService.getAllSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sourates')),
      body: FutureBuilder<List<SurahModel>>(
        future: _futureSurahs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          final surahs = snapshot.data ?? [];

          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return ListTile(
                title: Text(surah.name), // nom arabe
                subtitle: Text(surah.englishName), // optionnel
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahDetailScreen(surah: surah),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
