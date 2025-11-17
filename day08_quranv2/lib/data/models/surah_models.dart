class SurahSummary {
  final int surahNo;
  final String surahName;
  final String surahNameArabicLong;
  final int totalAyah;

  SurahSummary({
    required this.surahNo,
    required this.surahName,
    required this.surahNameArabicLong,
    required this.totalAyah,
  });

  factory SurahSummary.fromJson(Map<String, dynamic> json) {
    return SurahSummary(
      surahNo: json['surahNo'] ?? json['number'] ?? 0,
      surahName: json['surahName'] ?? json['name'] ?? '',
      surahNameArabicLong:
          json['surahNameArabicLong'] ?? json['nameArabicLong'] ?? '',
      totalAyah: json['totalAyah'] ?? json['numberOfAyahs'] ?? 0,
    );
  }
}

class AudioReciter {
  final String reciter;
  final String url;
  final String originalUrl;

  AudioReciter({
    required this.reciter,
    required this.url,
    required this.originalUrl,
  });

  factory AudioReciter.fromJson(Map<String, dynamic> json) {
    return AudioReciter(
      reciter: json['reciter'] ?? '',
      url: json['url'] ?? '',
      originalUrl: json['originalUrl'] ?? '',
    );
  }
}

class SurahDetail {
  final String surahName;
  final String surahNameArabic;
  final String surahNameArabicLong;
  final String surahNameTranslation;
  final String revelationPlace;
  final int totalAyah;
  final int surahNo;

  final Map<int, AudioReciter> audio;

  final List<String> arabic1;
  final List<String> arabic2;
  final List<String> english;
  final List<String> bengali;
  final List<String> urdu;

  SurahDetail({
    required this.surahName,
    required this.surahNameArabic,
    required this.surahNameArabicLong,
    required this.surahNameTranslation,
    required this.revelationPlace,
    required this.totalAyah,
    required this.surahNo,
    required this.audio,
    required this.arabic1,
    required this.arabic2,
    required this.english,
    required this.bengali,
    required this.urdu,
  });

  factory SurahDetail.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> audioJson =
        (json['audio'] as Map<String, dynamic>? ?? {});

    final parsedAudio = audioJson.map(
      (key, value) => MapEntry(
        int.tryParse(key) ?? 0,
        AudioReciter.fromJson(value as Map<String, dynamic>),
      ),
    );

    List<String> _parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return [];
    }

    return SurahDetail(
      surahName: json['surahName'] ?? '',
      surahNameArabic: json['surahNameArabic'] ?? '',
      surahNameArabicLong: json['surahNameArabicLong'] ?? '',
      surahNameTranslation: json['surahNameTranslation'] ?? '',
      revelationPlace: json['revelationPlace'] ?? '',
      totalAyah: json['totalAyah'] ?? 0,
      surahNo: json['surahNo'] ?? 0,
      audio: parsedAudio,
      arabic1: _parseStringList(json['arabic1']),
      arabic2: _parseStringList(json['arabic2']),
      english: _parseStringList(json['english']),
      bengali: _parseStringList(json['bengali']),
      urdu: _parseStringList(json['urdu']),
    );
  }
}
