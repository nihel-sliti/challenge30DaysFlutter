import 'package:flutter/material.dart';
import 'package:quran_app/data/service/download_service.dart';
import 'package:quran_app/ui/components/quran_play.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadService _downloadService = DownloadService();
  late Future<List<Map<String, dynamic>>> _downloadsFuture;
  bool _isLoading = false;
  String? _currentlyPlayingPath;

  // 🔹 État des téléchargements
  final Set<String> _downloadingFiles = <String>{};
  final Map<String, double> _downloadProgress = <String, double>{};

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() {
      _downloadsFuture = _downloadService.getDownloadedFiles();
    });
  }

  Future<void> _deleteFile(String filePath, String fileName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _downloadService.deleteFile(filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  success ? 'تم حذف "$fileName" بنجاح' : 'فشل حذف "$fileName"',
                ),
              ],
            ),
            backgroundColor:
                success ? Colors.green.shade600 : Colors.red.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (success) {
        _loadDownloads();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('خطأ: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshDownloads() async {
    await _loadDownloads();
  }

  /// 🔹 Télécharger une sourate avec progression
  Future<void> _downloadSurahWithProgress(
    String surahName,
    int surahNo,
  ) async {
    final reciterId = 1; // Récitateur par défaut
    final fileName = 'surah_${surahNo}_reciter_$reciterId.mp3';

    if (_downloadingFiles.contains(fileName)) return;

    setState(() {
      _downloadingFiles.add(fileName);
      _downloadProgress[fileName] = 0.0;
    });

    try {
      // Construire l'URL pour la sourate complète
      final surahNumber = surahNo.toString().padLeft(3, '0');
      final audioUrl =
          'https://download.quranicaudio.com/quran/abdul_basit_abdus_samad_192kbps/$surahNumber.mp3';

      final file = await _downloadService.downloadAudio(
        url: audioUrl,
        fileName: fileName,
        onProgress: (progress) {
          setState(() {
            _downloadProgress[fileName] = progress;
          });
        },
      );

      if (file != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download_done, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('تم تحميل سورة $surahName بنجاح'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        _loadDownloads(); // Rafraîchir la liste
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('فشل تحميل السورة: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _downloadingFiles.remove(fileName);
        _downloadProgress.remove(fileName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'التحميلات',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _isLoading ? null : _refreshDownloads,
              ),
            ],
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // En-tête avec statistiques
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.1),
                    theme.colorScheme.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: FutureBuilder<int>(
                future: _downloadService.getTotalDownloadSize(),
                builder: (context, snapshot) {
                  final totalSize = snapshot.data ?? 0;
                  final formattedSize =
                      _downloadService.formatFileSize(totalSize);

                  return FutureBuilder<String>(
                    future: _downloadService.getAvailableStorage(),
                    builder: (context, storageSnapshot) {
                      final availableStorage =
                          storageSnapshot.data ?? 'غير معروف';

                      return Column(
                        children: [
                          Icon(
                            Icons.download,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'إجمالي التحميلات',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            formattedSize,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'المساحة المتاحة: $availableStorage',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Lecteur audio intégré
            if (_currentlyPlayingPath != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: QuranPlay(
                      audioUrl: '', // URL vide car on utilise le fichier local
                      localPath: () async => _currentlyPlayingPath,
                    ),
                  ),
                ),
              ),

            // Liste des téléchargements
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _downloadsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
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
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'خطأ في تحميل التحميلات',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _refreshDownloads,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }

                  final downloads = snapshot.data ?? [];

                  if (downloads.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تحميلات بعد',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ابدأ بتحميل السور أو الآيات لمشاهدتها هنا',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshDownloads,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: downloads.length,
                      itemBuilder: (context, index) {
                        final download = downloads[index];
                        final name = download['name'] as String;
                        final path = download['path'] as String;
                        final size = download['size'] as int;
                        final date = download['date'] as DateTime;
                        final type = download['type'] as String;
                        final isCurrentlyPlaying =
                            _currentlyPlayingPath == path;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isCurrentlyPlaying
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isCurrentlyPlaying
                                  ? theme.colorScheme.primary.withOpacity(0.3)
                                  : theme.colorScheme.outline.withOpacity(0.2),
                              width: isCurrentlyPlaying ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isCurrentlyPlaying
                                    ? theme.colorScheme.primary.withOpacity(0.2)
                                    : theme.colorScheme.shadow
                                        .withOpacity(0.05),
                                blurRadius: isCurrentlyPlaying ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: type == 'surah'
                                      ? [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary
                                              .withOpacity(0.8),
                                        ]
                                      : [
                                          theme.colorScheme.secondary,
                                          theme.colorScheme.secondary
                                              .withOpacity(0.8),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      type == 'surah'
                                          ? Icons.book
                                          : Icons.format_quote,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  if (isCurrentlyPlaying)
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.play_arrow,
                                          color: theme.colorScheme.primary,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isCurrentlyPlaying
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _downloadService.formatFileSize(size),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(date),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                if (isCurrentlyPlaying)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'جاري التشغيل',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton de lecture
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.primary
                                            .withOpacity(0.8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      isCurrentlyPlaying
                                          ? Icons.stop
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      if (isCurrentlyPlaying) {
                                        setState(() {
                                          _currentlyPlayingPath = null;
                                        });
                                      } else {
                                        setState(() {
                                          _currentlyPlayingPath = path;
                                        });
                                      }
                                    },
                                    tooltip:
                                        isCurrentlyPlaying ? "إيقاف" : "تشغيل",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'حذف',
                                            style: TextStyle(
                                              color: Colors.red.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'delete') {
                                      if (_currentlyPlayingPath == path) {
                                        setState(() {
                                          _currentlyPlayingPath = null;
                                        });
                                      }
                                      _showDeleteDialog(name, path);
                                    }
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              if (isCurrentlyPlaying) {
                                setState(() {
                                  _currentlyPlayingPath = null;
                                });
                              } else {
                                setState(() {
                                  _currentlyPlayingPath = path;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Section pour télécharger de nouvelles sourates
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.secondary.withOpacity(0.02),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تحميل سور إضافية',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSurahDownloadButton('الفاتحة', 1),
                      _buildSurahDownloadButton('البقرة', 2),
                      _buildSurahDownloadButton('آل عمران', 3),
                      _buildSurahDownloadButton('النساء', 4),
                      _buildSurahDownloadButton('المائدة', 5),
                      _buildSurahDownloadButton('الأنعام', 6),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget pour le bouton de téléchargement de sourate
  Widget _buildSurahDownloadButton(String surahName, int surahNo) {
    final theme = Theme.of(context);
    final reciterId = 1;
    final fileName = 'surah_${surahNo}_reciter_$reciterId.mp3';
    final isDownloading = _downloadingFiles.contains(fileName);
    final progress = _downloadProgress[fileName] ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDownloading
            ? Colors.blue.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDownloading
              ? Colors.blue.withOpacity(0.3)
              : theme.colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDownloading
              ? null
              : () => _downloadSurahWithProgress(surahName, surahNo),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDownloading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade600,
                      value: progress,
                    ),
                  )
                else
                  Icon(
                    Icons.download,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                const SizedBox(width: 8),
                Text(
                  isDownloading ? '${(progress * 100).toInt()}%' : surahName,
                  style: TextStyle(
                    color: isDownloading
                        ? Colors.blue.shade600
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'الآن';
        }
        return 'منذ ${difference.inMinutes} دقيقة';
      }
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'منذ $weeks أسبوع${weeks > 1 ? '' : ''}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showDeleteDialog(String fileName, String filePath) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف "$fileName"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFile(filePath, fileName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }
}
