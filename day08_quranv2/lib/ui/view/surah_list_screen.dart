import 'package:day08_quranv2/data/models/surah_models.dart';
import 'package:day08_quranv2/data/service/quran_service.dart';
import 'package:day08_quranv2/ui/view/surah_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SurahListScreen extends StatelessWidget {
  SurahListScreen({super.key});

  final QuranService _service = QuranService(Dio());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sourates'),
      ),
      body: FutureBuilder<List<SurahSummary>>(
        future: _service.getAllSurah(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          final surahs = snapshot.data ?? [];

          if (surahs.isEmpty) {
            return const Center(child: Text('Aucune sourate trouvée'));
          }

          return ListView.builder(
            itemCount: surahs.length,
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(surah.surahNo.toString()),
                ),
                title: Text(surah.surahNameArabicLong),
                subtitle: Text('${surah.surahName} • ${surah.totalAyah} ayat'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahDetailScreen(
                        surahNo: surah.surahNo,
                      ),
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
