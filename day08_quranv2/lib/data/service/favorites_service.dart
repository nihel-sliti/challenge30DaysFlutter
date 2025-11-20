import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../models/favorites_models.dart';

class FavoritesService {
  static const String _bookmarksKey = 'quran_bookmarks';
  static const String _favoriteSurahsKey = 'quran_favorite_surahs';
  static const String _lastBookmarkIdKey = 'quran_last_bookmark_id';

  int _lastBookmarkId = 0;

  // Save a bookmark
  Future<bool> saveBookmark(Bookmark bookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = (jsonDecode(bookmarksJson) as List)
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      bookmarksList.add(bookmark);

      await prefs.setString(_bookmarksKey,
          jsonEncode(bookmarksList.map((b) => b.toJson()).toList()));
      await prefs.setInt(_lastBookmarkIdKey, bookmark.id);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Create and save a new bookmark
  Future<bool> addBookmark({
    required int surahNo,
    required int ayahNo,
    required String ayahText,
    required FavoriteCategory category,
    String? note,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastBookmarkId = prefs.getInt(_lastBookmarkIdKey) ?? 0;
      _lastBookmarkId++;

      final bookmark = Bookmark(
        id: _lastBookmarkId,
        surahNo: surahNo,
        ayahNo: ayahNo,
        ayahText: ayahText,
        category: category,
        createdAt: DateTime.now(),
        note: note,
      );

      return await saveBookmark(bookmark);
    } catch (e) {
      return false;
    }
  }

  // Get all bookmarks
  Future<List<Bookmark>> getAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = (jsonDecode(bookmarksJson) as List)
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by creation date (newest first)
      bookmarksList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return bookmarksList;
    } catch (e) {
      return [];
    }
  }

  // Get bookmarks by category
  Future<List<Bookmark>> getBookmarksByCategory(
      FavoriteCategory category) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks
        .where((bookmark) => bookmark.category == category)
        .toList();
  }

  // Get bookmarks for a specific surah
  Future<List<Bookmark>> getBookmarksForSurah(int surahNo) async {
    final allBookmarks = await getAllBookmarks();
    return allBookmarks
        .where((bookmark) => bookmark.surahNo == surahNo)
        .toList();
  }

  // Delete a bookmark
  Future<bool> deleteBookmark(int bookmarkId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = (jsonDecode(bookmarksJson) as List)
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      bookmarksList.removeWhere((bookmark) => bookmark.id == bookmarkId);

      await prefs.setString(_bookmarksKey,
          jsonEncode(bookmarksList.map((b) => b.toJson()).toList()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Update bookmark
  Future<bool> updateBookmark(Bookmark updatedBookmark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookmarksJson = prefs.getString(_bookmarksKey) ?? '[]';
      final bookmarksList = (jsonDecode(bookmarksJson) as List)
          .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
          .toList();

      final index = bookmarksList
          .indexWhere((bookmark) => bookmark.id == updatedBookmark.id);
      if (index != -1) {
        bookmarksList[index] = updatedBookmark;
        await prefs.setString(_bookmarksKey,
            jsonEncode(bookmarksList.map((b) => b.toJson()).toList()));
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Save favorite surah
  Future<bool> saveFavoriteSurah(FavoriteSurah favoriteSurah) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteSurahsKey) ?? '[]';
      final favoritesList = (jsonDecode(favoritesJson) as List)
          .map((json) => FavoriteSurah.fromJson(json as Map<String, dynamic>))
          .toList();

      // Check if already favorited
      if (!favoritesList.any((fav) => fav.surahNo == favoriteSurah.surahNo)) {
        favoritesList.add(favoriteSurah);
      }

      await prefs.setString(_favoriteSurahsKey,
          jsonEncode(favoritesList.map((f) => f.toJson()).toList()));

      return true;
    } catch (e) {
      return false;
    }
  }

  // Add favorite surah
  Future<bool> addFavoriteSurah({
    required int surahNo,
    required String surahName,
    required String surahNameArabic,
    required FavoriteCategory category,
    String? note,
  }) async {
    try {
      final favoriteSurah = FavoriteSurah(
        surahNo: surahNo,
        surahName: surahName,
        surahNameArabic: surahNameArabic,
        addedAt: DateTime.now(),
        category: category,
        note: note,
      );

      return await saveFavoriteSurah(favoriteSurah);
    } catch (e) {
      return false;
    }
  }

  // Get all favorite surahs
  Future<List<FavoriteSurah>> getAllFavoriteSurahs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteSurahsKey) ?? '[]';
      final favoritesList = (jsonDecode(favoritesJson) as List)
          .map((json) => FavoriteSurah.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by added date (newest first)
      favoritesList.sort((a, b) => b.addedAt.compareTo(a.addedAt));

      return favoritesList;
    } catch (e) {
      return [];
    }
  }

  // Get favorite surahs by category
  Future<List<FavoriteSurah>> getFavoriteSurahsByCategory(
      FavoriteCategory category) async {
    final allFavorites = await getAllFavoriteSurahs();
    return allFavorites
        .where((favorite) => favorite.category == category)
        .toList();
  }

  // Check if surah is favorited
  Future<bool> isSurahFavorited(int surahNo) async {
    final favorites = await getAllFavoriteSurahs();
    return favorites.any((favorite) => favorite.surahNo == surahNo);
  }

  // Remove favorite surah
  Future<bool> removeFavoriteSurah(int surahNo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteSurahsKey) ?? '[]';
      final favoritesList = (jsonDecode(favoritesJson) as List)
          .map((json) => FavoriteSurah.fromJson(json as Map<String, dynamic>))
          .toList();

      final removedCount = favoritesList.length;
      favoritesList.removeWhere((favorite) => favorite.surahNo == surahNo);

      if (favoritesList.length < removedCount) {
        await prefs.setString(_favoriteSurahsKey,
            jsonEncode(favoritesList.map((f) => f.toJson()).toList()));
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // Get bookmarks grouped by category
  Future<Map<FavoriteCategory, List<Bookmark>>>
      getBookmarksGroupedByCategory() async {
    final allBookmarks = await getAllBookmarks();
    final grouped = <FavoriteCategory, List<Bookmark>>{};

    for (final category in FavoriteCategory.values) {
      grouped[category] = [];
    }

    for (final bookmark in allBookmarks) {
      grouped[bookmark.category]!.add(bookmark);
    }

    return grouped;
  }

  // Get favorite surahs grouped by category
  Future<Map<FavoriteCategory, List<FavoriteSurah>>>
      getFavoriteSurahsGroupedByCategory() async {
    final allFavorites = await getAllFavoriteSurahs();
    final grouped = <FavoriteCategory, List<FavoriteSurah>>{};

    for (final category in FavoriteCategory.values) {
      grouped[category] = [];
    }

    for (final favorite in allFavorites) {
      grouped[favorite.category]!.add(favorite);
    }

    return grouped;
  }

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bookmarksKey);
      await prefs.remove(_lastBookmarkIdKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear all favorite surahs
  Future<bool> clearAllFavoriteSurahs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoriteSurahsKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Export bookmarks to JSON string
  Future<String> exportBookmarks() async {
    final bookmarks = await getAllBookmarks();
    return jsonEncode(bookmarks.map((b) => b.toJson()).toList());
  }

  // Export favorite surahs to JSON string
  Future<String> exportFavoriteSurahs() async {
    final favorites = await getAllFavoriteSurahs();
    return jsonEncode(favorites.map((f) => f.toJson()).toList());
  }
}
