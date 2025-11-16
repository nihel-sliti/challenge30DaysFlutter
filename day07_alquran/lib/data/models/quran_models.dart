class AyahModel {
  final int numberInSurah;
  final String text;
  final String audio;

  AyahModel({
    required this.numberInSurah,
    required this.text,
    required this.audio,
  });

  factory AyahModel.fromJson(Map<String, dynamic> json) {
    return AyahModel(
      numberInSurah: (json['numberInSurah'] ?? 0) as int,
      text: json['text']?.toString() ?? '',
      audio: json['audio']?.toString() ?? '',
    );
  }
}

class SurahModel {
  final int number;
  final String name; // Nom en arabe : e.g. "الفاتحة"
  final String englishName; // e.g. "Al-Faatiha"
  final String revelationType; // e.g. "Meccan"
  final List<AyahModel> ayahs;

  SurahModel({
    required this.number,
    required this.name,
    required this.englishName,
    required this.revelationType,
    required this.ayahs,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final ayahsJson = json['ayahs'] as List<dynamic>? ?? [];

    return SurahModel(
      number: (json['number'] ?? 0) as int,
      name: json['name']?.toString() ?? '',
      englishName: json['englishName']?.toString() ?? '',
      revelationType: json['revelationType']?.toString() ?? '',
      ayahs: ayahsJson
          .map((a) => AyahModel.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}
