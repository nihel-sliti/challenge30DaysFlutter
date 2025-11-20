import 'package:day08_quranv2/ui/view/surah_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import 'package:day08_quranv2/data/models/surah_models.dart';
import 'package:day08_quranv2/data/service/quran_service.dart';
import 'package:day08_quranv2/data/service/favorites_service.dart';
import 'package:day08_quranv2/data/models/favorites_models.dart';

/// Map simplifiée : surahNo -> numéro du Juz où commence la sourate
/// (assez bon pour l’UI, pas un outil de fiqh).
const Map<int, int> _surahToJuz = {
  1: 1,
  2: 2,
  3: 3,
  4: 4,
  5: 6,
  6: 7,
  7: 8,
  8: 9,
  9: 10,
  10: 11,
  11: 11,
  12: 12,
  13: 13,
  14: 13,
  15: 14,
  16: 14,
  17: 15,
  18: 15,
  19: 16,
  20: 16,
  21: 17,
  22: 17,
  23: 18,
  24: 18,
  25: 19,
  26: 19,
  27: 19,
  28: 20,
  29: 20,
  30: 21,
  31: 21,
  32: 21,
  33: 21,
  34: 22,
  35: 22,
  36: 23,
  37: 23,
  38: 23,
  39: 23,
  40: 24,
  41: 24,
  42: 25,
  43: 25,
  44: 25,
  45: 25,
  46: 26,
  47: 26,
  48: 26,
  49: 26,
  50: 26,
  51: 27,
  52: 27,
  53: 27,
  54: 27,
  55: 27,
  56: 27,
  57: 27,
  58: 28,
  59: 28,
  60: 28,
  61: 28,
  62: 28,
  63: 28,
  64: 28,
  65: 28,
  66: 28,
  67: 29,
  68: 29,
  69: 29,
  70: 29,
  71: 29,
  72: 29,
  73: 29,
  74: 29,
  75: 29,
  76: 29,
  77: 29,
  78: 30,
  79: 30,
  80: 30,
  81: 30,
  82: 30,
  83: 30,
  84: 30,
  85: 30,
  86: 30,
  87: 30,
  88: 30,
  89: 30,
  90: 30,
  91: 30,
  92: 30,
  93: 30,
  94: 30,
  95: 30,
  96: 30,
  97: 30,
  98: 30,
  99: 30,
  100: 30,
  101: 30,
  102: 30,
  103: 30,
  104: 30,
  105: 30,
  106: 30,
  107: 30,
  108: 30,
  109: 30,
  110: 30,
  111: 30,
  112: 30,
  113: 30,
  114: 30,
};

String _juzTitleAr(int juz) {
  const nums = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
    'الخامس عشر',
    'السادس عشر',
    'السابع عشر',
    'الثامن عشر',
    'التاسع عشر',
    'العشرون',
    'الحادي والعشرون',
    'الثاني والعشرون',
    'الثالث والعشرون',
    'الرابع والعشرون',
    'الخامس والعشرون',
    'السادس والعشرون',
    'السابع والعشرون',
    'الثامن والعشرون',
    'التاسع والعشرون',
    'الثلاثون',
  ];
  if (juz < 1 || juz > 30) return 'الجزء $juz';
  return 'الجزء ${nums[juz - 1]}';
}

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  late final QuranService _service;
  late final FavoritesService _favoritesService;
  late Future<List<SurahSummary>> _future;

  // Variables pour la recherche
  List<SurahSummary> _allSurahs = [];
  List<SurahSummary> _filteredSurahs = [];
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Variables pour les favoris
  Set<int> _favoriteSurahs = {};
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _service = QuranService(Dio());
    _favoritesService = FavoritesService();
    _future = _service.getAllSurah();

    // Initialiser la liste complète après le chargement
    _future.then((surahs) {
      if (mounted) {
        setState(() {
          _allSurahs = surahs;
          _filteredSurahs = surahs;
        });
        _loadFavorites();
      }
    });
  }

  // Charger les favoris
  Future<void> _loadFavorites() async {
    final favoriteSurahs = await _favoritesService.getAllFavoriteSurahs();
    if (mounted) {
      setState(() {
        _favoriteSurahs = favoriteSurahs.map((fav) => fav.surahNo).toSet();
      });
    }
  }

  // Ajouter/retirer des favoris
  Future<void> _toggleFavorite(SurahSummary surah) async {
    final surahNo = surah.surahNo;
    bool success;

    if (_favoriteSurahs.contains(surahNo)) {
      success = await _favoritesService.removeFavoriteSurah(surahNo);
      if (success && mounted) {
        setState(() {
          _favoriteSurahs.remove(surahNo);
        });
        _showSnackBar('تمت إزالة السورة من المفضلة', false);
      }
    } else {
      success = await _favoritesService.addFavoriteSurah(
        surahNo: surahNo,
        surahName: surah.surahName,
        surahNameArabic: surah.surahNameArabicLong,
        category: FavoriteCategory.daily,
      );
      if (success && mounted) {
        setState(() {
          _favoriteSurahs.add(surahNo);
        });
        _showSnackBar('تمت إضافة السورة إلى المفضلة', true);
      }
    }

    if (!success && mounted) {
      _showSnackBar('حدث خطأ أثناء تحديث المفضلة', false);
    }
  }

  // Afficher un message
  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Basculer l'affichage des favoris
  void _toggleFavoritesOnly() {
    setState(() {
      _showFavoritesOnly = !_showFavoritesOnly;
      if (_showFavoritesOnly) {
        _filteredSurahs = _allSurahs
            .where((surah) => _favoriteSurahs.contains(surah.surahNo))
            .toList();
      } else {
        _filterSurahs(_searchController.text);
      }
    });
  }

  // Afficher le dialogue de confirmation pour effacer les favoris
  void _showClearFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح المفضلات'),
        content: const Text('هل أنت متأكد من رغبتك في مسح جميع المفضلات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await _favoritesService.clearAllFavoriteSurahs();
              if (success && mounted) {
                setState(() {
                  _favoriteSurahs.clear();
                  if (_showFavoritesOnly) {
                    _filteredSurahs = [];
                  }
                });
                _showSnackBar('تم مسح جميع المفضلات', true);
              } else if (mounted) {
                _showSnackBar('حدث خطأ أثناء مسح المفضلات', false);
              }
            },
            child: const Text('مسح', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Méthode de recherche
  void _filterSurahs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSurahs = List.from(_allSurahs);
      } else {
        _filteredSurahs = _allSurahs.where((surah) {
          final searchLower = query.toLowerCase();
          final arabicName = surah.surahNameArabicLong.toLowerCase();
          final englishName = surah.surahName.toLowerCase();
          final surahNumber = surah.surahNo.toString();

          return arabicName.contains(searchLower) ||
              englishName.contains(searchLower) ||
              surahNumber.contains(searchLower);
        }).toList();
      }
    });
  }

  // Basculer le mode recherche
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterSurahs('');
        _searchFocusNode.unfocus();
      } else {
        _searchFocusNode.requestFocus();
      }
    });
  }

  // Widget pour le champ de recherche
  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن سورة...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _filterSurahs('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _filterSurahs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // L'écran est en arabe => RTL
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          title: _isSearching
              ? _buildSearchField()
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.menu_book, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'القرآن الكريم',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
          actions: [
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
            ),
          ],
        ),
        body: FutureBuilder<List<SurahSummary>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري تحميل السور...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'خطأ في تحميل السور',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _future = _service.getAllSurah();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              );
            }
            final surahs = snapshot.data ?? [];
            if (surahs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد بيانات متاحة',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Utiliser la liste filtrée pour l'affichage
            final displaySurahs = _isSearching ? _filteredSurahs : surahs;

            // Afficher un message si aucun résultat de recherche
            if (_isSearching && displaySurahs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لم يتم العثور على سورة مطابقة',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'جرب كلمات مفتاحية مختلفة',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.1),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isSearching ? 'نتائج البحث' : 'مرحباً بك',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isSearching
                                    ? '${displaySurahs.length} سورة'
                                    : 'القرآن الكريم',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isSearching
                                    ? 'من أصل ${surahs.length} سورة'
                                    : '${surahs.length} سورة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _isSearching ? Icons.search : Icons.auto_stories,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final surah = displaySurahs[index];
                      final surahNo = surah.surahNo;

                      final currentJuz = _surahToJuz[surahNo] ?? 1;
                      final prevJuz = index > 0
                          ? _surahToJuz[displaySurahs[index - 1].surahNo] ??
                              currentJuz
                          : null;

                      final showJuzHeader =
                          prevJuz == null || prevJuz != currentJuz;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showJuzHeader) ...[
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.bookmark,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _juzTitleAr(currentJuz),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          _ModernSurahRow(
                            surah: surah,
                            isHighlighted:
                                surahNo == 1, // par ex. Fatiha en vert
                            isFavorite: _favoriteSurahs.contains(surahNo),
                            onTap: () {
                              Navigator.of(context).push(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      SurahDetailScreen(surahNo: surahNo),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset.zero;
                                    const curve = Curves.ease;

                                    var tween =
                                        Tween(begin: begin, end: end).chain(
                                      CurveTween(curve: curve),
                                    );

                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            },
                            onFavoriteToggle: () => _toggleFavorite(surah),
                          ),
                          if (index < displaySurahs.length - 1)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(
                                height: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.1),
                              ),
                            ),
                        ],
                      );
                    },
                    childCount: displaySurahs.length,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ModernSurahRow extends StatelessWidget {
  final SurahSummary surah;
  final bool isHighlighted;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const _ModernSurahRow({
    required this.surah,
    required this.isHighlighted,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isHighlighted
                  ? colorScheme.primary.withOpacity(0.1)
                  : colorScheme.surface,
              border: Border.all(
                color: isHighlighted
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Numéro de sourate moderne
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isHighlighted
                          ? [
                              colorScheme.primary,
                              colorScheme.primary.withOpacity(0.8),
                            ]
                          : [
                              colorScheme.primary.withOpacity(0.8),
                              colorScheme.secondary.withOpacity(0.6),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isHighlighted
                                ? colorScheme.primary
                                : colorScheme.secondary)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${surah.surahNo}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Informations de la sourate
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.surahNameArabicLong,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                          height: 1.2,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${surah.totalAyah} آية',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (isHighlighted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'مميزة',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Favorite and play buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Favorite button
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? Colors.amber.withOpacity(0.2)
                              : colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isFavorite ? Icons.bookmark : Icons.bookmark_border,
                          color:
                              isFavorite ? Colors.amber : colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Play button
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
