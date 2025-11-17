import 'package:dio/dio.dart';
import '../models/surah_models.dart';

class QuranService {
  final Dio dio;

  QuranService(this.dio);

  static const String baseUrl = 'https://quranapi.pages.dev/api';

  /// Récupère la liste des sourates depuis surah.json
  /// Comme l'API ne retourne pas surahNo, on le génère à partir de l'index (index + 1).
  Future<List<SurahSummary>> getAllSurah() async {
    try {
      final response = await dio.get('$baseUrl/surah.json');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        if (data is List) {
          // Format: [ { surahName: ..., ... }, ... ]
          return data.asMap().entries.map((entry) {
            final index = entry.key; // 0,1,2,...
            final value = entry.value as Map<String, dynamic>;

            // Add surahNo to the JSON data
            final jsonWithSurahNo = Map<String, dynamic>.from(value);
            jsonWithSurahNo['surahNo'] = index + 1; // on commence à 1

            return SurahSummary.fromJson(jsonWithSurahNo);
          }).toList();
        } else if (data is Map) {
          // Si jamais c'est un Map { "1": {...}, "2": {...} }
          final entries = data.entries.toList()
            ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

          return entries.map((mapEntry) {
            final surahNo = int.tryParse(mapEntry.key.toString()) ?? 1;

            // Add surahNo to the JSON data
            final jsonWithSurahNo = Map<String, dynamic>.from(
                mapEntry.value as Map<String, dynamic>);
            jsonWithSurahNo['surahNo'] = surahNo;

            return SurahSummary.fromJson(jsonWithSurahNo);
          }).toList();
        } else {
          throw Exception('Unexpected surah.json format');
        }
      } else {
        throw Exception('Failed to load surah list');
      }
    } catch (e) {
      print('QuranService.getAllSurah error: $e');
      rethrow;
    }
  }

  /// Détail d'une sourate : /<surahNo>.json
  Future<SurahDetail> getSurahDetail(int surahNo) async {
    try {
      final response = await dio.get('$baseUrl/$surahNo.json');

      if (response.statusCode == 200 && response.data != null) {
        return SurahDetail.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load surah detail');
      }
    } catch (e) {
      print('QuranService.getSurahDetail error: $e');
      rethrow;
    }
  }

  /// Récupère l'audio d'un verset précis : /<surahNo>/<ayahNo>.json
  Future<Map<int, AudioReciter>> getAyahAudio(
    int surahNo,
    int ayahNo,
  ) async {
    try {
      final response = await dio.get('$baseUrl/$surahNo/$ayahNo.json');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final audioJson = data['audio'] as Map<String, dynamic>? ?? {};

        // même structure que pour la sourate :
        return audioJson.map(
          (key, value) => MapEntry(
            int.tryParse(key) ?? 0,
            AudioReciter.fromJson(value as Map<String, dynamic>),
          ),
        );
      } else {
        throw Exception('Failed to load ayah audio');
      }
    } catch (e) {
      print('QuranService.getAyahAudio error: $e');
      rethrow;
    }
  }
}
