import 'package:day07_alquran/data/models/quran_models.dart';
import 'package:dio/dio.dart';

class QuranService {
  final Dio _dio;

  static const String _baseUrl = 'http://api.alquran.cloud/v1/quran/ar.alafasy';

  QuranService(this._dio);

  /// Charge tout le Coran une seule fois et renvoie la liste des sourates.
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      final response = await _dio.get(_baseUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final List<dynamic> surahsJson = data['surahs'] ?? [];

        return surahsJson
            .map((s) => SurahModel.fromJson(s as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load Quran: invalid response');
      }
    } catch (e, stack) {
      // En prod: logger propre, pas print sauvage
      print('Quran API Error: $e');
      print(stack);
      rethrow;
    }
  }

  /// Récupère une sourate précise à partir de son numéro (1..114)
  Future<SurahModel?> getSurahByNumber(int number) async {
    final surahs = await getAllSurahs();
    try {
      return surahs.firstWhere((s) => s.number == number);
    } catch (_) {
      return null;
    }
  }

  /// Récupère seulement les ayahs d’une sourate (helper pratique pour l’UI)
  Future<List<AyahModel>> getAyahsForSurah(int number) async {
    final surah = await getSurahByNumber(number);
    if (surah == null) {
      throw Exception('Surah $number not found');
    }
    return surah.ayahs;
  }
}
