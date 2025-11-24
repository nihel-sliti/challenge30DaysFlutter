import 'package:flutter/material.dart';
import 'package:quran_app/data/models/favorites_models.dart';
import 'package:quran_app/data/service/bookmark_service.dart';

class BookmarkWidget extends StatefulWidget {
  final int surahNo;
  final int ayahNo;
  final String ayahText;
  final String surahName;
  final VoidCallback? onBookmarkChanged;

  const BookmarkWidget({
    super.key,
    required this.surahNo,
    required this.ayahNo,
    required this.ayahText,
    required this.surahName,
    this.onBookmarkChanged,
  });

  @override
  State<BookmarkWidget> createState() => _BookmarkWidgetState();
}

class _BookmarkWidgetState extends State<BookmarkWidget> {
  late final BookmarkService _bookmarkService;
  bool _isBookmarked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bookmarkService = BookmarkService();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    setState(() {
      _isLoading = true;
    });

    final isBookmarked = await _bookmarkService.isAyahBookmarked(
      widget.surahNo,
      widget.ayahNo,
    );

    if (mounted) {
      setState(() {
        _isBookmarked = isBookmarked;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    setState(() {
      _isLoading = true;
    });

    if (_isBookmarked) {
      // Remove bookmark
      final success = await _bookmarkService.removeBookmark(
        widget.surahNo,
        widget.ayahNo,
      );

      if (success && mounted) {
        setState(() {
          _isBookmarked = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إزالة الإشارة المرجعية'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } else {
      // Show category selection dialog
      _showBookmarkDialog();
      return;
    }

    widget.onBookmarkChanged?.call();
  }

  void _showBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => _BookmarkDialog(
        surahNo: widget.surahNo,
        ayahNo: widget.ayahNo,
        ayahText: widget.ayahText,
        surahName: widget.surahName,
        onBookmarkSaved: (success) {
          if (success && mounted) {
            setState(() {
              _isBookmarked = true;
              _isLoading = false;
            });

            widget.onBookmarkChanged?.call();
          }
        },
      ),
    );
  }

  Future<bool> _saveBookmark(FavoriteCategory category, String note) async {
    try {
      final bookmark = Bookmark(
        id: DateTime.now().millisecondsSinceEpoch, // Simple ID generation
        surahNo: widget.surahNo,
        ayahNo: widget.ayahNo,
        ayahText: widget.ayahText,
        category: category,
        createdAt: DateTime.now(),
        note: note.isNotEmpty ? note : null,
      );

      return await _bookmarkService.saveBookmark(bookmark);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      onPressed: _toggleBookmark,
      icon: Icon(
        _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: _isBookmarked
            ? Colors.amber
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        size: 24,
      ),
      tooltip: _isBookmarked ? 'إزالة الإشارة المرجعية' : 'إضافة إشارة مرجعية',
    );
  }
}

class _BookmarkDialog extends StatefulWidget {
  final int surahNo;
  final int ayahNo;
  final String ayahText;
  final String surahName;
  final Function(bool) onBookmarkSaved;

  const _BookmarkDialog({
    required this.surahNo,
    required this.ayahNo,
    required this.ayahText,
    required this.surahName,
    required this.onBookmarkSaved,
  });

  @override
  State<_BookmarkDialog> createState() => _BookmarkDialogState();
}

class _BookmarkDialogState extends State<_BookmarkDialog> {
  late final BookmarkService _bookmarkService;
  FavoriteCategory selectedCategory = FavoriteCategory.daily;
  final noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bookmarkService = BookmarkService();
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

  Future<void> _saveBookmark() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final bookmark = Bookmark(
        id: DateTime.now().millisecondsSinceEpoch,
        surahNo: widget.surahNo,
        ayahNo: widget.ayahNo,
        ayahText: widget.ayahText,
        category: selectedCategory,
        createdAt: DateTime.now(),
        note: noteController.text.trim().isNotEmpty
            ? noteController.text.trim()
            : null,
      );

      final success = await _bookmarkService.saveBookmark(bookmark);

      if (success) {
        widget.onBookmarkSaved(true);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة الإشارة المرجعية'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حفظ الإشارة المرجعية'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'إضافة إشارة مرجعية',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر الفئة:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<FavoriteCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: FavoriteCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryNameArabic(category)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'ملاحظة (اختياري):',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: 'أضف ملاحظة...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              maxLines: 3,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سورة ${widget.surahName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'آية ${widget.ayahNo}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.ayahText.length > 100
                        ? '${widget.ayahText.substring(0, 100)}...'
                        : widget.ayahText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveBookmark,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
