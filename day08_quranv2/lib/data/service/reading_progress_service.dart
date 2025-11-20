import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/reading_progress_models.dart';

class ReadingProgressService {
  static const String _progressKey = 'quran_reading_progress';
  static const String _dailyGoalsKey = 'quran_daily_goals';
  static const String _statsKey = 'quran_reading_stats';

  // Save or update reading progress for a surah
  Future<bool> updateReadingProgress(ReadingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey) ?? '{}';
      final progressMap = Map<String, dynamic>.from(jsonDecode(progressJson));

      progressMap[progress.surahNo.toString()] = progress.toJson();

      await prefs.setString(_progressKey, jsonEncode(progressMap));

      // Update overall stats
      await _updateOverallStats(progress);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get reading progress for a specific surah
  Future<ReadingProgress?> getReadingProgress(int surahNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey) ?? '{}';
      final progressMap = Map<String, dynamic>.from(jsonDecode(progressJson));

      final progressData = progressMap[surahNo.toString()];
      if (progressData != null) {
        return ReadingProgress.fromJson(progressData as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all reading progress
  Future<Map<int, ReadingProgress>> getAllReadingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey) ?? '{}';
      final progressMap = Map<String, dynamic>.from(jsonDecode(progressJson));

      final result = <int, ReadingProgress>{};
      for (final entry in progressMap.entries) {
        final surahNo = int.tryParse(entry.key);
        if (surahNo != null) {
          result[surahNo] =
              ReadingProgress.fromJson(entry.value as Map<String, dynamic>);
        }
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  // Mark ayah as read and update progress
  Future<bool> markAyahAsRead(int surahNo, int ayahNo, int totalAyahs,
      {int readingTimeMinutes = 1}) async {
    try {
      final currentProgress = await getReadingProgress(surahNo);
      final now = DateTime.now();

      if (currentProgress == null) {
        // Create new progress
        final newProgress = ReadingProgress(
          surahNo: surahNo,
          lastReadAyah: ayahNo,
          lastReadDate: now,
          totalAyahs: totalAyahs,
          completionPercentage: (ayahNo / totalAyahs) * 100,
          readingStreak: 1,
          lastStreakDate: now,
          totalReadingTime: readingTimeMinutes,
        );

        return await updateReadingProgress(newProgress);
      } else {
        // Update existing progress
        final newLastReadAyah = ayahNo > currentProgress.lastReadAyah
            ? ayahNo
            : currentProgress.lastReadAyah;
        final newCompletionPercentage = (newLastReadAyah / totalAyahs) * 100;
        final newTotalTime =
            currentProgress.totalReadingTime + readingTimeMinutes;

        // Calculate streak
        final newStreak = await _calculateStreak(currentProgress, now);
        final newStreakDate =
            newStreak > 0 ? now : currentProgress.lastStreakDate;

        final updatedProgress = currentProgress.copyWith(
          lastReadAyah: newLastReadAyah,
          lastReadDate: now,
          completionPercentage: newCompletionPercentage,
          readingStreak: newStreak,
          lastStreakDate: newStreakDate,
          totalReadingTime: newTotalTime,
        );

        return await updateReadingProgress(updatedProgress);
      }
    } catch (e) {
      return false;
    }
  }

  // Calculate reading streak
  Future<int> _calculateStreak(
      ReadingProgress currentProgress, DateTime now) async {
    final lastReadDate = currentProgress.lastReadDate;
    final lastStreakDate = currentProgress.lastStreakDate;

    final today = DateTime(now.year, now.month, now.day);
    final lastReadDay =
        DateTime(lastReadDate.year, lastReadDate.month, lastReadDate.day);
    final lastStreakDay = lastStreakDate != null
        ? DateTime(
            lastStreakDate.year, lastStreakDate.month, lastStreakDate.day)
        : null;

    final difference = today.difference(lastReadDay).inDays;

    if (difference == 0) {
      // Read today, maintain current streak
      return currentProgress.readingStreak;
    } else if (difference == 1) {
      // Read yesterday, increment streak
      return currentProgress.readingStreak + 1;
    } else if (lastStreakDay != null) {
      final streakDifference = today.difference(lastStreakDay).inDays;
      if (streakDifference == 1) {
        // Last streak was yesterday, increment
        return currentProgress.readingStreak + 1;
      } else {
        // Streak broken, start new
        return 1;
      }
    } else {
      // No previous streak, start new
      return 1;
    }
  }

  // Save daily reading goal
  Future<bool> saveDailyGoal(DailyReadingGoal goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getString(_dailyGoalsKey) ?? '{}';
      final goalsMap = Map<String, dynamic>.from(jsonDecode(goalsJson));

      final dateKey = DateFormat('yyyy-MM-dd').format(goal.date);
      goalsMap[dateKey] = goal.toJson();

      await prefs.setString(_dailyGoalsKey, jsonEncode(goalsMap));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get daily reading goal
  Future<DailyReadingGoal?> getDailyGoal(DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final goalsJson = prefs.getString(_dailyGoalsKey) ?? '{}';
      final goalsMap = Map<String, dynamic>.from(jsonDecode(goalsJson));

      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final goalData = goalsMap[dateKey];

      if (goalData != null) {
        return DailyReadingGoal.fromJson(goalData as Map<String, dynamic>);
      }

      // Create default goal for today if not exists
      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      if (isToday) {
        final defaultGoal = DailyReadingGoal(date: date);
        await saveDailyGoal(defaultGoal);
        return defaultGoal;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Update today's reading progress
  Future<bool> updateTodayProgress(
      {int readingMinutes = 0, int surahsRead = 0}) async {
    try {
      final today = DateTime.now();
      final currentGoal = await getDailyGoal(today);

      if (currentGoal != null) {
        final updatedGoal = DailyReadingGoal(
          date: today,
          targetMinutes: currentGoal.targetMinutes,
          actualMinutes: currentGoal.actualMinutes + readingMinutes,
          targetSurahs: currentGoal.targetSurahs,
          actualSurahs: currentGoal.actualSurahs + surahsRead,
        );

        return await saveDailyGoal(updatedGoal);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get reading statistics
  Future<ReadingStats> getReadingStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);

      if (statsJson != null) {
        final statsData = jsonDecode(statsJson) as Map<String, dynamic>;
        return ReadingStats.fromJson(statsData);
      }

      // Return default stats if none exist
      return ReadingStats(
        totalSurahsRead: 0,
        totalAyahsRead: 0,
        totalReadingTime: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastReadingDate: DateTime.now(),
        dailyReadingMinutes: {},
      );
    } catch (e) {
      return ReadingStats(
        totalSurahsRead: 0,
        totalAyahsRead: 0,
        totalReadingTime: 0,
        currentStreak: 0,
        longestStreak: 0,
        lastReadingDate: DateTime.now(),
        dailyReadingMinutes: {},
      );
    }
  }

  // Update overall statistics
  Future<bool> _updateOverallStats(ReadingProgress progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsJson = prefs.getString(_statsKey);

      ReadingStats currentStats;
      if (statsJson != null) {
        final statsData = jsonDecode(statsJson) as Map<String, dynamic>;
        currentStats = ReadingStats.fromJson(statsData);
      } else {
        currentStats = ReadingStats(
          totalSurahsRead: 0,
          totalAyahsRead: 0,
          totalReadingTime: 0,
          currentStreak: 0,
          longestStreak: 0,
          lastReadingDate: DateTime.now(),
          dailyReadingMinutes: {},
        );
      }

      // Update daily reading minutes
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final todayMinutes = currentStats.dailyReadingMinutes[todayKey] ?? 0;
      currentStats.dailyReadingMinutes[todayKey] =
          todayMinutes + 1; // Add 1 minute for now

      // Update longest streak if needed
      final newLongestStreak =
          progress.readingStreak > currentStats.longestStreak
              ? progress.readingStreak
              : currentStats.longestStreak;

      final updatedStats = ReadingStats(
        totalSurahsRead:
            currentStats.totalSurahsRead + (progress.isCompleted ? 1 : 0),
        totalAyahsRead: currentStats.totalAyahsRead + 1, // Assume 1 ayah read
        totalReadingTime:
            currentStats.totalReadingTime + progress.totalReadingTime,
        currentStreak: progress.readingStreak,
        longestStreak: newLongestStreak,
        lastReadingDate: progress.lastReadDate,
        dailyReadingMinutes: currentStats.dailyReadingMinutes,
      );

      await prefs.setString(_statsKey, jsonEncode(updatedStats.toJson()));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get completed surahs
  Future<List<int>> getCompletedSurahs() async {
    try {
      final allProgress = await getAllReadingProgress();
      final completed = <int>[];

      for (final entry in allProgress.entries) {
        if (entry.value.isCompleted) {
          completed.add(entry.key);
        }
      }

      return completed;
    } catch (e) {
      return [];
    }
  }

  // Get surahs with progress
  Future<List<ReadingProgress>> getSurahsWithProgress() async {
    try {
      final allProgress = await getAllReadingProgress();
      final progressList = allProgress.values.toList();

      // Sort by last read date (most recent first)
      progressList.sort((a, b) => b.lastReadDate.compareTo(a.lastReadDate));

      return progressList;
    } catch (e) {
      return [];
    }
  }

  // Get reading time for today
  Future<int> getTodayReadingTime() async {
    try {
      final stats = await getReadingStats();
      final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
      return stats.dailyReadingMinutes[todayKey] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get reading time for this week
  Future<int> getThisWeekReadingTime() async {
    try {
      final stats = await getReadingStats();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartKey = DateFormat('yyyy-MM-dd').format(weekStart);

      int totalTime = 0;
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        totalTime += stats.dailyReadingMinutes[dateKey] ?? 0;
      }

      return totalTime;
    } catch (e) {
      return 0;
    }
  }

  // Get reading time for this month
  Future<int> getThisMonthReadingTime() async {
    try {
      final stats = await getReadingStats();
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      int totalTime = 0;
      for (int day = 1; day <= 31; day++) {
        final date = DateTime(now.year, now.month, day);
        if (date.month != now.month) break; // Stop if we've passed the month

        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        totalTime += stats.dailyReadingMinutes[dateKey] ?? 0;
      }

      return totalTime;
    } catch (e) {
      return 0;
    }
  }

  // Clear all progress data
  Future<bool> clearAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_dailyGoalsKey);
      await prefs.remove(_statsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Export all data
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'progress': prefs.getString(_progressKey) ?? '{}',
        'goals': prefs.getString(_dailyGoalsKey) ?? '{}',
        'stats': prefs.getString(_statsKey) ?? '{}',
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }
}
