enum FavoriteCategory {
  daily('Daily Reading'),
  memorization('Memorization'),
  important('Important Verses'),
  reflection('Reflection');

  const FavoriteCategory(this.displayName);
  final String displayName;
}

class Bookmark {
  final int id;
  final int surahNo;
  final int ayahNo;
  final String ayahText;
  final FavoriteCategory category;
  final DateTime createdAt;
  final String? note;

  Bookmark({
    required this.id,
    required this.surahNo,
    required this.ayahNo,
    required this.ayahText,
    required this.category,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahNo': surahNo,
      'ayahNo': ayahNo,
      'ayahText': ayahText,
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as int,
      surahNo: json['surahNo'] as int,
      ayahNo: json['ayahNo'] as int,
      ayahText: json['ayahText'] as String,
      category: FavoriteCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => FavoriteCategory.daily,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}

class FavoriteSurah {
  final int surahNo;
  final String surahName;
  final String surahNameArabic;
  final DateTime addedAt;
  final FavoriteCategory category;
  final String? note;

  FavoriteSurah({
    required this.surahNo,
    required this.surahName,
    required this.surahNameArabic,
    required this.addedAt,
    required this.category,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahNo': surahNo,
      'surahName': surahName,
      'surahNameArabic': surahNameArabic,
      'addedAt': addedAt.toIso8601String(),
      'category': category.name,
      'note': note,
    };
  }

  factory FavoriteSurah.fromJson(Map<String, dynamic> json) {
    return FavoriteSurah(
      surahNo: json['surahNo'] as int,
      surahName: json['surahName'] as String,
      surahNameArabic: json['surahNameArabic'] as String,
      addedAt: DateTime.parse(json['addedAt'] as String),
      category: FavoriteCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => FavoriteCategory.daily,
      ),
      note: json['note'] as String?,
    );
  }
}
