import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/favorites_models.dart';

class BookmarkService {
  static const String _bookmarksKey = 'quran_bookmarks';

  // Save a new bookmark
  Future<bool> saveBookmark(Bookmark bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = jsonDecode(bookmarksJson) as List<dynamic>;

      final bookmarks = bookmarksList
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      // Check if bookmark already exists
      final existingIndex = bookmarks.indexWhere(
        (b) => b.surahNo == bookmark.surahNo && b.ayahNo == bookmark.ayahNo,
      );

      if (existingIndex >= 0) {
        // Update existing bookmark
        bookmarks[existingIndex] = bookmark;
      } else {
        // Add new bookmark
        bookmarks.add(bookmark);
      }

      // Sort by creation date (most recent first)
      bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      await prefs.setString(
          _bookmarksKey,
          jsonEncode(
            bookmarks.map((b) => b.toJson()).toList(),
          ));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all bookmarks
  Future<List<Bookmark>> getAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = jsonDecode(bookmarksJson) as List<dynamic>;

      return bookmarksList
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get bookmarks for a specific surah
  Future<List<Bookmark>> getBookmarksForSurah(int surahNo) async {
    try {
      final allBookmarks = await getAllBookmarks();
      return allBookmarks
          .where((bookmark) => bookmark.surahNo == surahNo)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Check if a specific ayah is bookmarked
  Future<bool> isAyahBookmarked(int surahNo, int ayahNo) async {
    try {
      final allBookmarks = await getAllBookmarks();
      return allBookmarks.any((bookmark) =>
          bookmark.surahNo == surahNo && bookmark.ayahNo == ayahNo);
    } catch (e) {
      return false;
    }
  }

  // Remove a specific bookmark
  Future<bool> removeBookmark(int surahNo, int ayahNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = jsonDecode(bookmarksJson) as List<dynamic>;

      final bookmarks = bookmarksList
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      bookmarks.removeWhere((bookmark) =>
          bookmark.surahNo == surahNo && bookmark.ayahNo == ayahNo);

      await prefs.setString(
          _bookmarksKey,
          jsonEncode(
            bookmarks.map((b) => b.toJson()).toList(),
          ));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Remove bookmark by ID
  Future<bool> removeBookmarkById(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = jsonDecode(bookmarksJson) as List<dynamic>;

      final bookmarks = bookmarksList
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      bookmarks.removeWhere((bookmark) => bookmark.id == id);

      await prefs.setString(
          _bookmarksKey,
          jsonEncode(
            bookmarks.map((b) => b.toJson()).toList(),
          ));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get bookmarks by category
  Future<List<Bookmark>> getBookmarksByCategory(
      FavoriteCategory category) async {
    try {
      final allBookmarks = await getAllBookmarks();
      return allBookmarks
          .where((bookmark) => bookmark.category == category)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get recent bookmarks (last 10)
  Future<List<Bookmark>> getRecentBookmarks({int limit = 10}) async {
    try {
      final allBookmarks = await getAllBookmarks();
      return allBookmarks.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get bookmark count by category
  Future<Map<FavoriteCategory, int>> getBookmarkCountByCategory() async {
    try {
      final allBookmarks = await getAllBookmarks();
      final counts = <FavoriteCategory, int>{};

      for (final category in FavoriteCategory.values) {
        counts[category] = 0;
      }

      for (final bookmark in allBookmarks) {
        counts[bookmark.category] = (counts[bookmark.category] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      return {};
    }
  }
}
