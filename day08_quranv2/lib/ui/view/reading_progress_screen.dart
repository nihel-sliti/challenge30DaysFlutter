import 'package:flutter/material.dart';
import 'dart:async';
import 'package:day08_quranv2/data/models/reading_progress_models.dart';
import 'package:day08_quranv2/data/service/reading_progress_service.dart';
import 'package:day08_quranv2/data/service/bookmark_service.dart';
import 'package:day08_quranv2/data/models/favorites_models.dart';

class ReadingProgressScreen extends StatefulWidget {
  const ReadingProgressScreen({super.key});

  @override
  State<ReadingProgressScreen> createState() => _ReadingProgressScreenState();
}

class _ReadingProgressScreenState extends State<ReadingProgressScreen> {
  late final ReadingProgressService _progressService;
  late final BookmarkService _bookmarkService;
  ReadingStats? _stats;
  List<ReadingProgress> _recentProgress = [];
  List<Bookmark> _recentBookmarks = [];
  DailyReadingGoal? _currentGoal;
  bool _isLoading = true;

  // Timer variables
  bool _isReading = false;
  DateTime? _readingStartTime;
  Duration _currentReadingTime = Duration.zero;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _progressService = ReadingProgressService();
    _bookmarkService = BookmarkService();
    _timer = Timer.periodic(const Duration(seconds: 1), _updateTimer);
    _loadData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimer(Timer timer) {
    if (_isReading && _readingStartTime != null) {
      setState(() {
        _currentReadingTime = DateTime.now().difference(_readingStartTime!);
      });
    }
  }

  // Start reading session
  Future<void> _startReadingSession() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() {
      _isReading = true;
      _readingStartTime = now;
      _currentReadingTime = Duration.zero;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('بدء جلسة القراءة'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Stop reading session
  Future<void> _stopReadingSession() async {
    if (!_isReading || _readingStartTime == null) return;

    final now = DateTime.now();
    final duration = now.difference(_readingStartTime!);
    final durationMinutes = duration.inMinutes;

    setState(() {
      _isReading = false;
      _readingStartTime = null;
      _currentReadingTime = Duration.zero;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('انتهت جلسة القراءة: ${durationMinutes} دقيقة'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _progressService.getReadingStats();
      final recentProgress = await _progressService.getSurahsWithProgress();
      final today = DateTime.now();
      final currentGoal = await _progressService.getDailyGoal(today);
      final bookmarks = await _bookmarkService.getAllBookmarks();

      if (mounted) {
        setState(() {
          _stats = stats;
          _recentProgress = recentProgress.take(7).toList(); // Take last 7
          _currentGoal = currentGoal;
          _recentBookmarks = bookmarks.take(5).toList(); // Take last 5
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'تقدم القراءة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimerCard(),
                      const SizedBox(height: 20),
                      if (_stats != null) ...[
                        _buildStatsCard(),
                        const SizedBox(height: 20),
                        _buildStreakCard(),
                        const SizedBox(height: 20),
                      ],
                      if (_currentGoal != null) ...[
                        _buildGoalCard(),
                        const SizedBox(height: 20),
                      ],
                      _buildRecentBookmarksCard(),
                      const SizedBox(height: 20),
                      _buildRecentProgressCard(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'إحصائيات القراءة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'السور المقروءة',
                    '${_stats!.totalSurahsRead}',
                    Icons.calendar_today,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'إجمالي الآيات',
                    '${_stats!.totalAyahsRead}',
                    Icons.format_list_numbered,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'متوسط وقت القراءة',
                    '${(_stats!.averageReadingTime).toStringAsFixed(1)} دق',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatItem(
                    'إجمالي الوقت',
                    '${(_stats!.totalReadingTime ~/ 60)} ساعة',
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon,
      [Color? iconColor]) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor ?? Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.orange.withOpacity(0.1),
              Colors.red.withOpacity(0.1),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Text(
                  'السلسلة الحالية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStreakItem(
                    'أيام', '${_stats!.currentStreak}', Colors.orange),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.3),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                _buildStreakItem(
                    'أفضل سلسلة', '${_stats!.longestStreak}', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalCard() {
    final progress = _currentGoal!.actualMinutes;
    final goal = _currentGoal!.targetMinutes;
    final percentage = _currentGoal!.completionPercentage;

    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'الهدف اليومي',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 100 ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$progress دقيقة من $goal دقيقة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: percentage >= 100 ? Colors.green : Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProgressCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'التقدم الأخير',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentProgress.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'لا يوجد تقدم مؤخر',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentProgress.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final progress = _recentProgress[index];
                  return _buildProgressItem(progress);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(ReadingProgress progress) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.menu_book,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
      ),
      title: Text(
        'سورة ${progress.surahNo} - آية ${progress.lastReadAyah}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        _formatDate(progress.lastReadDate),
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Text(
        '${progress.completionPercentage.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildTimerCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.1),
              Colors.blue.withOpacity(0.1),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isReading ? Icons.timer : Icons.play_circle,
                  color: _isReading
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'جلسة القراءة الحالية',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_currentReadingTime.inHours.toString().padLeft(2, '0')}:${(_currentReadingTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_currentReadingTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _isReading
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isReading ? _stopReadingSession : _startReadingSession,
                    icon: Icon(
                      _isReading ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    label: Text(
                      _isReading ? 'إيقاف' : 'بدء',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isReading ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentBookmarksCard() {
    return Card(
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bookmark,
                  color: Colors.amber,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'الإشارات المرجعية الأخيرة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/favorites');
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('عرض الكل', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentBookmarks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'لا توجد إشارات مرجعية',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentBookmarks.take(5).length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bookmark = _recentBookmarks[index];
                  return _buildBookmarkItem(bookmark);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkItem(Bookmark bookmark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCategoryColor(bookmark.category).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.bookmark,
          color: _getCategoryColor(bookmark.category),
          size: 20,
        ),
      ),
      title: Text(
        'سورة ${bookmark.surahNo} - آية ${bookmark.ayahNo}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getCategoryNameArabic(bookmark.category),
            style: TextStyle(
              fontSize: 12,
              color: _getCategoryColor(bookmark.category),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (bookmark.note != null)
            Text(
              bookmark.note!,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Text(
        _formatDate(bookmark.createdAt),
        style: TextStyle(
          fontSize: 10,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  String _getCategoryNameArabic(FavoriteCategory category) {
    switch (category) {
      case FavoriteCategory.daily:
        return 'قراءة يومية';
      case FavoriteCategory.memorization:
        return 'حفظ';
      case FavoriteCategory.important:
        return 'آيات مهمة';
      case FavoriteCategory.reflection:
        return 'تأمل';
    }
  }

  Color _getCategoryColor(FavoriteCategory category) {
    switch (category) {
      case FavoriteCategory.daily:
        return Colors.blue;
      case FavoriteCategory.memorization:
        return Colors.green;
      case FavoriteCategory.important:
        return Colors.red;
      case FavoriteCategory.reflection:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
