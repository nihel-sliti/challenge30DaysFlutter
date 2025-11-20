class ReadingProgress {
  final int surahNo;
  final int lastReadAyah;
  final DateTime lastReadDate;
  final int totalAyahs;
  final double completionPercentage;
  final int readingStreak;
  final DateTime? lastStreakDate;
  final int totalReadingTime; // in minutes

  ReadingProgress({
    required this.surahNo,
    required this.lastReadAyah,
    required this.lastReadDate,
    required this.totalAyahs,
    required this.completionPercentage,
    this.readingStreak = 0,
    this.lastStreakDate,
    this.totalReadingTime = 0,
  });

  bool get isCompleted => completionPercentage >= 100.0;
  bool get hasStreak => readingStreak > 0;

  Map<String, dynamic> toJson() {
    return {
      'surahNo': surahNo,
      'lastReadAyah': lastReadAyah,
      'lastReadDate': lastReadDate.toIso8601String(),
      'totalAyahs': totalAyahs,
      'completionPercentage': completionPercentage,
      'readingStreak': readingStreak,
      'lastStreakDate': lastStreakDate?.toIso8601String(),
      'totalReadingTime': totalReadingTime,
    };
  }

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      surahNo: json['surahNo'] as int,
      lastReadAyah: json['lastReadAyah'] as int,
      lastReadDate: DateTime.parse(json['lastReadDate'] as String),
      totalAyahs: json['totalAyahs'] as int,
      completionPercentage: (json['completionPercentage'] as num).toDouble(),
      readingStreak: json['readingStreak'] as int? ?? 0,
      lastStreakDate: json['lastStreakDate'] != null
          ? DateTime.parse(json['lastStreakDate'] as String)
          : null,
      totalReadingTime: json['totalReadingTime'] as int? ?? 0,
    );
  }

  ReadingProgress copyWith({
    int? surahNo,
    int? lastReadAyah,
    DateTime? lastReadDate,
    int? totalAyahs,
    double? completionPercentage,
    int? readingStreak,
    DateTime? lastStreakDate,
    int? totalReadingTime,
  }) {
    return ReadingProgress(
      surahNo: surahNo ?? this.surahNo,
      lastReadAyah: lastReadAyah ?? this.lastReadAyah,
      lastReadDate: lastReadDate ?? this.lastReadDate,
      totalAyahs: totalAyahs ?? this.totalAyahs,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      readingStreak: readingStreak ?? this.readingStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      totalReadingTime: totalReadingTime ?? this.totalReadingTime,
    );
  }
}

class DailyReadingGoal {
  final DateTime date;
  final int targetMinutes; // target reading time in minutes
  final int actualMinutes; // actual reading time in minutes
  final int targetSurahs; // target number of surahs to read
  final int actualSurahs; // actual number of surahs read
  final bool isCompleted;

  DailyReadingGoal({
    required this.date,
    this.targetMinutes = 30,
    this.actualMinutes = 0,
    this.targetSurahs = 1,
    this.actualSurahs = 0,
  }) : isCompleted = actualMinutes >= targetMinutes;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'targetMinutes': targetMinutes,
      'actualMinutes': actualMinutes,
      'targetSurahs': targetSurahs,
      'actualSurahs': actualSurahs,
      'isCompleted': isCompleted,
    };
  }

  factory DailyReadingGoal.fromJson(Map<String, dynamic> json) {
    return DailyReadingGoal(
      date: DateTime.parse(json['date'] as String),
      targetMinutes: json['targetMinutes'] as int? ?? 30,
      actualMinutes: json['actualMinutes'] as int? ?? 0,
      targetSurahs: json['targetSurahs'] as int? ?? 1,
      actualSurahs: json['actualSurahs'] as int? ?? 0,
    );
  }

  double get completionPercentage =>
      targetMinutes > 0 ? (actualMinutes / targetMinutes) * 100 : 0.0;
}

class ReadingStats {
  final int totalSurahsRead;
  final int totalAyahsRead;
  final int totalReadingTime; // in minutes
  final int currentStreak;
  final int longestStreak;
  final DateTime lastReadingDate;
  final Map<String, int> dailyReadingMinutes; // date -> minutes

  ReadingStats({
    required this.totalSurahsRead,
    required this.totalAyahsRead,
    required this.totalReadingTime,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastReadingDate,
    required this.dailyReadingMinutes,
  });

  double get averageReadingTime {
    return totalReadingTime > 0 ? totalReadingTime / totalSurahsRead : 0.0;
  }

  String get formattedTotalTime {
    final hours = totalReadingTime ~/ 60;
    final minutes = totalReadingTime % 60;
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSurahsRead': totalSurahsRead,
      'totalAyahsRead': totalAyahsRead,
      'totalReadingTime': totalReadingTime,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadingDate': lastReadingDate.toIso8601String(),
      'dailyReadingMinutes': dailyReadingMinutes,
    };
  }

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    final dailyMinutesMap = <String, int>{};
    if (json['dailyReadingMinutes'] != null) {
      final dailyMinutes = json['dailyReadingMinutes'] as Map<String, dynamic>;
      for (final entry in dailyMinutes.entries) {
        dailyMinutesMap[entry.key] = entry.value as int;
      }
    }

    return ReadingStats(
      totalSurahsRead: json['totalSurahsRead'] as int? ?? 0,
      totalAyahsRead: json['totalAyahsRead'] as int? ?? 0,
      totalReadingTime: json['totalReadingTime'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastReadingDate: DateTime.parse(json['lastReadingDate'] as String),
      dailyReadingMinutes: dailyMinutesMap,
    );
  }
}
