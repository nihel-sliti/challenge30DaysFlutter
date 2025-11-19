import 'package:audioplayers/audioplayers.dart';
import 'package:day08_quranv2/data/models/surah_models.dart';
import 'package:day08_quranv2/data/models/repeat_settings.dart';
import 'package:day08_quranv2/data/service/quran_service.dart';
import 'package:day08_quranv2/ui/components/quran_play.dart';
import 'package:day08_quranv2/ui/components/repeat_settings_panel.dart';
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

  // 🔹 Réglages de répétition (sauvegardés sur l’écran)
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

      // 1) Répétition d’ayah
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

  @override
  void dispose() {
    _ayahPlayer.dispose();
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

    try {
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

  /// 🔹 Ouvrir le panneau et mettre à jour _repeatSettings quand l’utilisateur change les valeurs
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
              // ici on SAUVEGARDE les settings dans l’écran
              setState(() => _repeatSettings = value);
            },
          ),
        );
      },
    );
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_stories, size: 20),
            ),
            const SizedBox(width: 8),
            Text('سورة ${widget.surahNo}'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat),
            onPressed: () {
              final detail = _currentDetail;
              if (detail != null) {
                _openRepeatSettings(detail);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Implement bookmark functionality
            },
          ),
        ],
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

              // LANGUE + RÉCITEUR
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
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              //  const SizedBox(height: 8),

              // PLAYER GLOBAL
              QuranPlay(
                audioUrl: chapterAudioUrl,
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
                  padding: const EdgeInsets.all(16.0),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verseText = verses[index];
                    final isPlayingThisAyah = _playingAyahIndex == index;

                    return Container(
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
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Indicateur de lecture
                                    if (isPlayingThisAyah)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
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
                                        onPressed: () {
                                          // TODO: Implement share functionality
                                        },
                                        tooltip: "مشاركة",
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Bouton de favori
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
                                          Icons.bookmark_border,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.7),
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          // TODO: Implement bookmark functionality
                                        },
                                        tooltip: "حفظ",
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
}
