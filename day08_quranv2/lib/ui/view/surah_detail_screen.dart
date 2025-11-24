import 'package:audioplayers/audioplayers.dart';
import 'package:quran_app/data/models/surah_models.dart';
import 'package:quran_app/data/models/repeat_settings.dart';
import 'package:quran_app/data/service/quran_service.dart';
import 'package:quran_app/ui/components/quran_play.dart';
import 'package:quran_app/ui/components/repeat_settings_panel.dart';
import 'package:quran_app/ui/components/bookmark_widget.dart';
import 'package:quran_app/data/models/favorites_models.dart';
import 'package:quran_app/data/service/favorites_service.dart';
import 'package:quran_app/data/service/download_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNo;

  const SurahDetailScreen({
    super.key,
    required this.surahNo,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranService _service = QuranService(Dio());
  final AudioPlayer _ayahPlayer = AudioPlayer();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listKey = GlobalKey();
  final FavoritesService _favoritesService = FavoritesService();
  final DownloadService _downloadService = DownloadService();

  late Future<SurahDetail> _detailFuture;
  SurahDetail? _currentDetail;

  String _selectedLanguage = 'arabic1';
  int? _selectedReciterKey;

  int? _playingAyahIndex;
  bool _isAyahLoading = false;
  String? _ayahError;

  bool _sequentialMode = false;

  int _rangeStartIndex = 0;
  int _rangeEndIndex = 0;
  int _currentRangeLoop = 0;
  int _ayahRepeatsLeft = 1;

  final Map<int, Map<int, AudioReciter>> _ayahAudioCache = {};

  // 🔹 État des téléchargements
  final Set<String> _downloadingFiles = <String>{};
  final Map<String, double> _downloadProgress = <String, double>{};
  final Set<String> _downloadedFiles = <String>{};

  // 🔹 Réglages de répétition (sauvegardés sur l'écran)
  RepeatSettings _repeatSettings = RepeatSettings(
    fromAyah: 1,
    toAyah: 1,
    rangeRepeatEnabled: false,
    rangeRepeatCount: null, // null = infini
    ayahRepeatEnabled: false,
    ayahRepeatCount: 1,
  );

  @override
  void initState() {
    super.initState();
    _detailFuture = _service.getSurahDetail(widget.surahNo);
    _initializeDownloadedFiles();

    _ayahPlayer.onPlayerComplete.listen((_) async {
      if (!mounted) return;

      if (!_sequentialMode ||
          _currentDetail == null ||
          _playingAyahIndex == null) {
        setState(() => _playingAyahIndex = null);
        return;
      }

      final detail = _currentDetail!;
      final totalVerses = _getVerses(detail).length;

      if (_playingAyahIndex! < 0 || _playingAyahIndex! >= totalVerses) {
        setState(() {
          _playingAyahIndex = null;
          _sequentialMode = false;
        });
        return;
      }

      // 1) Répétition d'ayah
      if (_repeatSettings.ayahRepeatEnabled && _ayahRepeatsLeft > 1) {
        setState(() {
          _ayahRepeatsLeft -= 1;
        });
        await _playAyah(detail, _playingAyahIndex!, sequential: true);
        return;
      }

      _ayahRepeatsLeft = _repeatSettings.ayahRepeatEnabled
          ? _repeatSettings.ayahRepeatCount
          : 1;

      // 2) Verset suivant dans le range
      var nextIndex = _playingAyahIndex! + 1;

      if (nextIndex > _rangeEndIndex) {
        // Fin du range
        if (_repeatSettings.rangeRepeatEnabled) {
          if (_repeatSettings.rangeRepeatCount == null) {
            // infini
            nextIndex = _rangeStartIndex;
            setState(() => _currentRangeLoop++);
            await _playAyah(detail, nextIndex, sequential: true);
          } else {
            if (_currentRangeLoop + 1 >= _repeatSettings.rangeRepeatCount!) {
              setState(() {
                _sequentialMode = false;
                _playingAyahIndex = null;
              });
            } else {
              setState(() => _currentRangeLoop++);
              nextIndex = _rangeStartIndex;
              await _playAyah(detail, nextIndex, sequential: true);
            }
          }
        } else {
          setState(() {
            _sequentialMode = false;
            _playingAyahIndex = null;
          });
        }
      } else {
        await _playAyah(detail, nextIndex, sequential: true);
      }
    });
  }

  /// Initialiser la liste des fichiers déjà téléchargés
  Future<void> _initializeDownloadedFiles() async {
    try {
      // Vérifier les fichiers de sourate et d'ayah pour le récitateur actuel
      final reciterId = _selectedReciterKey ?? 1;
      final surahFileName = 'surah_${widget.surahNo}_reciter_$reciterId.mp3';

      final isSurahDownloaded =
          await _downloadService.isAudioDownloaded(surahFileName);

      if (isSurahDownloaded) {
        setState(() {
          _downloadedFiles.add(surahFileName);
        });
      }

      // Vérifier quelques ayahs pour optimiser
      for (int i = 1; i <= 5 && i <= 286; i++) {
        // Maximum 286 ayahs dans le Coran
        final ayahFileName =
            'surah_${widget.surahNo}/ayah_${i}_reciter_$reciterId.mp3';
        final isAyahDownloaded =
            await _downloadService.isAudioDownloaded(ayahFileName);
        if (isAyahDownloaded) {
          setState(() {
            _downloadedFiles.add(ayahFileName);
          });
        }
      }
    } catch (e) {
      print('Error initializing downloaded files: $e');
    }
  }

  /// Vérifier si un ayah est téléchargé localement
  Future<bool> _isAyahDownloaded(int ayahNo, int reciterId) async {
    final fileName =
        'surah_${widget.surahNo}/ayah_${ayahNo}_reciter_$reciterId.mp3';
    return _downloadedFiles.contains(fileName) ||
        await _downloadService.isAudioDownloaded(fileName);
  }

  /// Vérifier si la sourate est téléchargée localement
  Future<bool> _isSurahDownloaded(int reciterId) async {
    final fileName = 'surah_${widget.surahNo}_reciter_$reciterId.mp3';
    return _downloadedFiles.contains(fileName) ||
        await _downloadService.isAudioDownloaded(fileName);
  }

  /// Obtenir le chemin du fichier audio local pour un ayah
  Future<String?> _getAyahLocalPath(int ayahNo, int reciterId) async {
    final fileName =
        'surah_${widget.surahNo}/ayah_${ayahNo}_reciter_$reciterId.mp3';
    return await _downloadService.getLocalAudioPath(fileName);
  }

  /// Obtenir le chemin du fichier audio local pour la sourate
  Future<String?> _getSurahLocalPath(int reciterId) async {
    final fileName = 'surah_${widget.surahNo}_reciter_$reciterId.mp3';
    return await _downloadService.getLocalAudioPath(fileName);
  }

  /// Télécharger un ayah avec progression
  Future<void> _downloadAyahWithProgress(
    SurahDetail detail,
    int ayahNo,
    String ayahText,
  ) async {
    final reciterId = _selectedReciterKey ?? 1;
    final fileName =
        'surah_${widget.surahNo}/ayah_${ayahNo}_reciter_$reciterId.mp3';

    if (_downloadingFiles.contains(fileName)) return;

    setState(() {
      _downloadingFiles.add(fileName);
      _downloadProgress[fileName] = 0.0;
    });

    try {
      // Construire l'URL pour l'ayah spécifique
      final audioUrl =
          'https://the-quran-project.github.io/Quran-Audio/Data/${detail.surahNo}/${ayahNo}_2.mp3';

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
        setState(() {
          _downloadedFiles.add(fileName);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download_done, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('تم تحميل الآية $ayahNo بنجاح'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('فشل تحميل الآية: ${e.toString()}'),
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

  /// Télécharger la sourate complète avec progression depuis Quran API
  Future<void> _downloadSurahWithProgress(SurahDetail detail) async {
    final reciterId = _selectedReciterKey ?? 1;
    final fileName = 'surah_${widget.surahNo}_reciter_$reciterId.mp3';

    // éviter de lancer 2 fois le même download
    if (_downloadingFiles.contains(fileName)) return;

    setState(() {
      _downloadingFiles.add(fileName);
      _downloadProgress[fileName] = 0.0;
    });

    try {
      // 1) Appel de l'API Quran API pour récupérer les URL audio de la sourate
      final apiUrl =
          'https://quranapi.pages.dev/api/audio/${detail.surahNo}.json';

      final dio = Dio();
      final response = await dio.get(apiUrl);

      // Le JSON ressemble à :
      // {
      //   "1": { "reciter": "...", "url": "...", "originalUrl": "..." },
      //   "2": { ... },
      //   ...
      // }
      final data = response.data as Map<String, dynamic>;

      final reciterKey = reciterId.toString();
      final reciterData = data[reciterKey];

      if (reciterData == null) {
        throw Exception(
            'Aucune entrée audio trouvée pour le réciteur $reciterKey');
      }

      // On privilégie l’originalUrl (mp3quran), sinon on prend url (GitHub)
      final audioUrl =
          (reciterData['originalUrl'] as String?)?.trim().isNotEmpty == true
              ? reciterData['originalUrl'] as String
              : reciterData['url'] as String;

      // 2) Téléchargement du fichier audio choisi
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
        setState(() {
          _downloadedFiles.add(fileName);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.download_done, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('تم تحميل سورة ${detail.surahNameArabicLong} بنجاح'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
  void dispose() {
    _ayahPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getVerses(SurahDetail detail) {
    switch (_selectedLanguage) {
      case 'arabic1':
        return detail.arabic1;
      case 'arabic2':
        return detail.arabic2;
      case 'english':
        return detail.english;
      case 'bengali':
        return detail.bengali;
      case 'urdu':
        return detail.urdu;
      default:
        return detail.arabic1;
    }
  }

  // Method to scroll to a specific ayah
  Future<void> _scrollToAyah(int index) async {
    // Wait a bit for UI to update
    await Future.delayed(const Duration(milliseconds: 100));

    if (_scrollController.hasClients) {
      // Calculate approximate position (each ayah item is roughly 200px tall)
      final double estimatedPosition = index * 200.0;
      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double targetPosition = estimatedPosition.clamp(0.0, maxScroll);

      await _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _playAyah(
    SurahDetail detail,
    int index, {
    bool sequential = false,
  }) async {
    final ayahNo = index + 1;

    setState(() {
      _isAyahLoading = true;
      _playingAyahIndex = index;
      _ayahError = null;
      _sequentialMode = sequential;
      _currentDetail = detail;
    });

    // Scroll to ayah when it starts playing
    _scrollToAyah(index);

    try {
      final reciterId = _selectedReciterKey ?? 1;

      // 🔹 PRIORITÉ: Vérifier d'abord si le fichier local existe
      final localPath = await _getAyahLocalPath(ayahNo, reciterId);
      if (localPath != null) {
        // Utiliser le fichier local
        await _ayahPlayer.stop();
        await _ayahPlayer.play(DeviceFileSource(localPath));
      } else {
        // 🔹 FALLBACK: Utiliser l'URL distante
        Map<int, AudioReciter>? audioMap = _ayahAudioCache[ayahNo];

        if (audioMap == null) {
          audioMap = await _service.getAyahAudio(detail.surahNo, ayahNo);
          if (audioMap.isEmpty) {
            throw Exception('Aucun audio trouvé pour ce verset.');
          }
          _ayahAudioCache[ayahNo] = audioMap;
        }

        final reciterKey = _selectedReciterKey ?? audioMap.keys.first;
        final reciter = audioMap[reciterKey] ?? audioMap.values.first;

        await _ayahPlayer.stop();
        await _ayahPlayer.play(
          UrlSource(
            reciter.originalUrl.isNotEmpty ? reciter.originalUrl : reciter.url,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _ayahError = e.toString();
        _playingAyahIndex = null;
        _sequentialMode = false;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAyahLoading = false;
        });
      }
    }
  }

  Future<void> _stopSequential() async {
    await _ayahPlayer.stop();
    if (mounted) {
      setState(() {
        _sequentialMode = false;
        _playingAyahIndex = null;
      });
    }
  }

  /// 🔹 Télécharger un ayah spécifique (ancienne méthode pour compatibilité)
  Future<void> _downloadAyah(
      SurahDetail detail, int ayahNo, String ayahText) async {
    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text('جاري تحميل الآية $ayahNo...'),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final reciterId = _selectedReciterKey ?? 1;
      final filePath = await _downloadService.downloadAyahAudio(
        detail.surahNo,
        ayahNo,
        reciterId: reciterId,
      );

      if (mounted && filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم تحميل الآية $ayahNo بنجاح'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('فشل تحميل الآية: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 🔹 Télécharger la sourate complète (ancienne méthode pour compatibilité)
  Future<void> _downloadSurah(SurahDetail detail) async {
    try {
      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text('جاري تحميل سورة ${detail.surahNameArabicLong}...'),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      final reciterId = _selectedReciterKey ?? 1;
      final filePath = await _downloadService.downloadSurahAudio(
        detail.surahNo,
        detail.surahNameArabicLong,
        reciterId: reciterId,
      );

      if (mounted && filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.download_done, color: Colors.white),
                const SizedBox(width: 8),
                Text('تم تحميل سورة ${detail.surahNameArabicLong} بنجاح'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
    }
  }

  /// 🔹 Partager un ayah
  Future<void> _shareAyah(String ayahText, int surahNo, int ayahNo) async {
    try {
      await _downloadService.shareAyah(ayahText, surahNo, ayahNo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('فشل المشاركة: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 🔹 Vérifier la connectivité et afficher un message si hors-ligne
  Future<bool> _checkConnectivityAndShowMessage() async {
    try {
      // Simuler une vérification de connectivité simple
      // En production, vous pourriez utiliser connectivity_plus ou une autre méthode
      final hasConnection = await _hasInternetConnection();

      if (!hasConnection) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'حسناً',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      // En cas d'erreur lors de la vérification, supposer qu'il y a une connexion
      return true;
    }
  }

  /// 🔹 Vérification simple de la connectivité Internet
  Future<bool> _hasInternetConnection() async {
    try {
      // Tenter une connexion simple vers un service fiable
      // C'est une méthode basique - en production, utilisez une solution plus robuste
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      dio.options.receiveTimeout = const Duration(seconds: 3);
      dio.options.sendTimeout = const Duration(seconds: 5);

      final response = await dio.get('https://httpbin.org/json');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 🔹 Afficher un message si pas de fichier local et pas de connexion
  void _showOfflineMessage(int ayahNo) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text('وضع عدم الاتصال'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الآية $ayahNo غير متاحة للعرض حالياً.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'يرجى تنزيل الآية أثناء الاتصال بالإنترنت لتتمكن من الاستماع إليها في وضع عدم الاتصال.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('حسناً'),
              ),
            ],
          );
        },
      );
    }
  }

  /// 🔹 Appliquer _repeatSettings sur la lecture "Lire toute la sourate (verset par verset)"
  Future<void> _startSequential(SurahDetail detail) async {
    final total = _getVerses(detail).length;

    final start = _repeatSettings.fromAyah.clamp(1, total) - 1;
    final end = _repeatSettings.toAyah.clamp(1, total) - 1;

    setState(() {
      _rangeStartIndex = start;
      _rangeEndIndex = end;
      _currentRangeLoop = 0;
      _ayahRepeatsLeft = _repeatSettings.ayahRepeatEnabled
          ? _repeatSettings.ayahRepeatCount
          : 1;
    });

    await _playAyah(detail, start, sequential: true);
  }

  /// 🔹 Ouvrir le panneau et mettre à jour _repeatSettings quand l'utilisateur change les valeurs
  void _openRepeatSettings(SurahDetail detail) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: RepeatSettingsPanel(
            totalAyah: detail.totalAyah,
            initial: _repeatSettings,
            onChanged: (value) {
              // ici on SAUVEGARDE les settings dans l'écran
              setState(() => _repeatSettings = value);
            },
          ),
        );
      },
    );
  }

  /// 🔹 Ajouter la sourate aux favoris avec snackbar
  Future<void> _toggleSurahFavorite(SurahDetail detail) async {
    try {
      final isFavorited =
          await _favoritesService.isSurahFavorited(detail.surahNo);

      if (isFavorited) {
        // Retirer des favoris
        final success =
            await _favoritesService.removeFavoriteSurah(detail.surahNo);

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.bookmark_remove, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('${detail.surahNameArabicLong} retirée des favoris'),
                  ],
                ),
                backgroundColor: Colors.orange.shade600,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Ajouter aux favoris
        final success = await _favoritesService.addFavoriteSurah(
          surahNo: detail.surahNo,
          surahName: detail.surahName,
          surahNameArabic: detail.surahNameArabicLong,
          category: FavoriteCategory.daily,
        );

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.bookmark_added, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('${detail.surahNameArabicLong} ajoutée aux favoris'),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Text('Erreur: ${e.toString()}'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
              // Flèche de retour à droite
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'سورة ${_currentDetail?.surahName ?? ''}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.repeat, color: Colors.white),
                onPressed: () {
                  final detail = _currentDetail;
                  if (detail != null) {
                    _openRepeatSettings(detail);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<SurahDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('Aucune donnée disponible'),
            );
          }

          final detail = snapshot.data!;
          _currentDetail ??= detail;

          // première fois : on met le "toAyah" sur toute la sourate
          if (_repeatSettings.toAyah == 1 && detail.totalAyah > 1) {
            _repeatSettings = _repeatSettings.copyWith(
              toAyah: detail.totalAyah,
            );
          }

          final verses = _getVerses(detail);

          final audioEntries = detail.audio.entries.toList()
            ..sort((a, b) => a.key.compareTo(b.key));

          if (_selectedReciterKey == null && audioEntries.isNotEmpty) {
            _selectedReciterKey = audioEntries.first.key;
          }

          final chapterAudioUrl = (_selectedReciterKey != null &&
                  detail.audio[_selectedReciterKey] != null)
              ? detail.audio[_selectedReciterKey]!.originalUrl
              : '';

          return Column(
            children: [
              // HEADER MODERNE
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
                child: Column(
                  children: [
                    // Image et informations principales
                    Row(
                      children: [
                        // Image avec cadre décoratif
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              detail.revelationPlace
                                      .toLowerCase()
                                      .contains('mecca')
                                  ? 'assets/image/Mecca.png'
                                  : 'assets/image/Medina.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: detail.revelationPlace
                                              .toLowerCase()
                                              .contains('mecca')
                                          ? [
                                              theme.colorScheme.primary,
                                              theme.colorScheme.secondary
                                            ]
                                          : [
                                              Colors.orange.shade300,
                                              Colors.orange.shade500
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    detail.revelationPlace
                                            .toLowerCase()
                                            .contains('mecca')
                                        ? Icons.mosque
                                        : Icons.location_city,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detail.surahNameArabicLong,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${detail.surahName} • ${detail.surahNameTranslation}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: detail.revelationPlace
                                              .toLowerCase()
                                              .contains('mecca')
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      detail.revelationPlace,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: detail.revelationPlace
                                                .toLowerCase()
                                                .contains('mecca')
                                            ? Colors.green
                                            : Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${detail.totalAyah} آية',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: theme.colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 🔹 Bouton de téléchargement de la sourate avec indicateur
                                  _buildDownloadButton(
                                    detail: detail,
                                    isSurah: true,
                                    onPressed: () =>
                                        _downloadSurahWithProgress(detail),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // LANGUE + RÉCITATEUR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedLanguage,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'arabic1',
                            child: Text('Arabe (mushaf)'),
                          ),
                          DropdownMenuItem(
                            value: 'arabic2',
                            child: Text('Arabe simple'),
                          ),
                          DropdownMenuItem(
                            value: 'english',
                            child: Text('Anglais'),
                          ),
                          DropdownMenuItem(
                            value: 'bengali',
                            child: Text('Bengali'),
                          ),
                          DropdownMenuItem(
                            value: 'urdu',
                            child: Text('Urdu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedLanguage = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<int>(
                        value: _selectedReciterKey,
                        isExpanded: true,
                        items: audioEntries.map((entry) {
                          return DropdownMenuItem<int>(
                            value: entry.key,
                            child: Text(
                              '${entry.key}. ${entry.value.reciter}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedReciterKey = value;
                            // Réinitialiser les fichiers téléchargés quand on change de récitateur
                            _initializeDownloadedFiles();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // PLAYER GLOBAL (mis à jour pour lecture hors-ligne)
              FutureBuilder<bool>(
                future: _isSurahDownloaded(_selectedReciterKey ?? 1),
                builder: (context, snapshot) {
                  final isDownloaded = snapshot.data ?? false;
                  return QuranPlay(
                    audioUrl: isDownloaded
                        ? '' // URL vide si téléchargé
                        : chapterAudioUrl,
                    localPath: isDownloaded
                        ? () => _getSurahLocalPath(_selectedReciterKey ?? 1)
                        : null,
                  );
                },
              ),

              const SizedBox(height: 8),

              // 🔹 BOUTON QUI UTILISE _repeatSettings
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: (_isAyahLoading && _sequentialMode)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _sequentialMode
                                ? Icons.stop
                                : Icons.play_circle_fill,
                          ),
                    label: Text(
                      _sequentialMode
                          ? 'Arrêter la lecture'
                          : 'Lire selon les réglages',
                    ),
                    onPressed: _isAyahLoading && _sequentialMode
                        ? null
                        : () {
                            if (_sequentialMode) {
                              _stopSequential();
                            } else {
                              _startSequential(detail);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              if (_ayahError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _ayahError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),

              // LISTE DES VERSETS MODERNE
              Expanded(
                child: ListView.builder(
                  key: _listKey,
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verseText = verses[index];
                    final isPlayingThisAyah = _playingAyahIndex == index;
                    final ayahNo = index + 1;
                    final reciterId = _selectedReciterKey ?? 1;
                    final fileName =
                        'surah_${widget.surahNo}/ayah_${ayahNo}_reciter_$reciterId.mp3';
                    final isDownloaded = _downloadedFiles.contains(fileName);
                    final isDownloading = _downloadingFiles.contains(fileName);
                    final progress = _downloadProgress[fileName] ?? 0.0;

                    return Container(
                      key: ValueKey('ayah_$index'),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isAyahLoading
                              ? null
                              : () => _playAyah(
                                    detail,
                                    index,
                                    sequential: false,
                                  ),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isPlayingThisAyah
                                  ? theme.colorScheme.primary.withOpacity(0.1)
                                  : theme.colorScheme.surface,
                              border: Border.all(
                                color: isPlayingThisAyah
                                    ? theme.colorScheme.primary.withOpacity(0.3)
                                    : theme.colorScheme.outline
                                        .withOpacity(0.2),
                                width: isPlayingThisAyah ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isPlayingThisAyah
                                      ? theme.colorScheme.primary
                                          .withOpacity(0.2)
                                      : theme.colorScheme.shadow
                                          .withOpacity(0.05),
                                  blurRadius: isPlayingThisAyah ? 8 : 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête du verset
                                Row(
                                  children: [
                                    // Numéro du verset
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isPlayingThisAyah
                                              ? [
                                                  theme.colorScheme.primary,
                                                  theme.colorScheme.primary
                                                      .withOpacity(0.8),
                                                ]
                                              : [
                                                  theme.colorScheme.primary
                                                      .withOpacity(0.8),
                                                  theme.colorScheme.secondary
                                                      .withOpacity(0.6),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: isPlayingThisAyah
                                            ? [
                                                BoxShadow(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$ayahNo',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Indicateur de lecture et téléchargement
                                    if (isPlayingThisAyah || isDownloading)
                                      Row(
                                        children: [
                                          if (isPlayingThisAyah)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color:
                                                    theme.colorScheme.primary,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Text(
                                                    'جاري التشغيل',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          if (isDownloading)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade600,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                      value: progress,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${(progress * 100).toInt()}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),

                                    // Indicateur de fichier téléchargé
                                    if (isDownloaded && !isDownloading)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.download_done,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            const Text(
                                              'تم التحميل',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                // Texte du verset
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    verseText,
                                    textAlign:
                                        _selectedLanguage.startsWith('arabic')
                                            ? TextAlign.right
                                            : TextAlign.left,
                                    style: TextStyle(
                                      fontSize:
                                          _selectedLanguage.startsWith('arabic')
                                              ? 20
                                              : 18,
                                      height: 1.6,
                                      color: theme.colorScheme.onSurface,
                                      fontWeight:
                                          _selectedLanguage.startsWith('arabic')
                                              ? FontWeight.normal
                                              : FontWeight.w400,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Boutons d'action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    // 🔹 Bouton de téléchargement avec état
                                    _buildDownloadButton(
                                      detail: detail,
                                      ayahNo: ayahNo,
                                      isDownloaded: isDownloaded,
                                      isDownloading: isDownloading,
                                      progress: progress,
                                      onPressed: isDownloading
                                          ? null
                                          : isDownloaded
                                              ? null
                                              : () => _downloadAyahWithProgress(
                                                  detail, ayahNo, verseText),
                                    ),

                                    const SizedBox(width: 8),

                                    // Bouton de partage
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.share,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                          size: 20,
                                        ),
                                        onPressed: () => _shareAyah(
                                          verseText,
                                          detail.surahNo,
                                          ayahNo,
                                        ),
                                        tooltip: "مشاركة الآية",
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Bouton de favori avec BookmarkWidget
                                    Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.outline
                                              .withOpacity(0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: BookmarkWidget(
                                        surahNo: detail.surahNo,
                                        ayahNo: ayahNo,
                                        ayahText: verseText,
                                        surahName: detail.surahNameArabicLong,
                                        onBookmarkChanged: () {
                                          // Refresh UI when bookmark changes
                                          setState(() {});
                                        },
                                      ),
                                    ),

                                    const SizedBox(width: 8),

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
                                      child: _isAyahLoading &&
                                              _playingAyahIndex == index
                                          ? Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : IconButton(
                                              icon: Icon(
                                                isPlayingThisAyah
                                                    ? Icons.stop
                                                    : Icons.play_arrow,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed: _isAyahLoading
                                                  ? null
                                                  : () => _playAyah(
                                                        detail,
                                                        index,
                                                        sequential: false,
                                                      ),
                                              tooltip: isPlayingThisAyah
                                                  ? "إيقاف"
                                                  : "تشغيل",
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
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Widget pour le bouton de téléchargement avec état
  Widget _buildDownloadButton({
    required SurahDetail detail,
    int? ayahNo,
    bool isSurah = false,
    bool isDownloaded = false,
    bool isDownloading = false,
    double progress = 0.0,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDownloaded
            ? Colors.green.withOpacity(0.1)
            : isDownloading
                ? Colors.blue.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDownloaded
              ? Colors.green.withOpacity(0.3)
              : isDownloading
                  ? Colors.blue.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: isDownloading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue.shade600,
                  value: progress,
                ),
              )
            : Icon(
                isDownloaded ? Icons.download_done : Icons.download,
                color:
                    isDownloaded ? Colors.green.shade600 : Colors.blue.shade600,
                size: isSurah ? 16 : 20,
              ),
        onPressed: onPressed,
        tooltip: isSurah
            ? "تحميل السورة"
            : isDownloaded
                ? "تم التحميل"
                : "تحميل الآية",
      ),
    );
  }
}
