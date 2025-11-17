import 'package:audioplayers/audioplayers.dart';
import 'package:day08_quranv2/data/models/surah_models.dart';
import 'package:day08_quranv2/data/service/quran_service.dart';
import 'package:day08_quranv2/ui/components/quran_play.dart';
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

  // Player global pour la sourate (dans QuranPlay)
  // Player spécifique pour un verset
  final AudioPlayer _ayahPlayer = AudioPlayer();

  String _selectedLanguage = 'arabic1';
  int? _selectedReciterKey;

  int? _playingAyahIndex; // index du verset en cours de lecture
  bool _isAyahLoading = false;
  String? _ayahError;

  @override
  void initState() {
    super.initState();

    _ayahPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingAyahIndex = null;
        });
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

  Future<void> _playAyah(SurahDetail detail, int index) async {
    final ayahNo = index + 1;

    setState(() {
      _isAyahLoading = true;
      _playingAyahIndex = index;
      _ayahError = null;
    });

    try {
      // Récupérer l'audio du verset
      final audioMap = await _service.getAyahAudio(detail.surahNo, ayahNo);

      if (audioMap.isEmpty) {
        throw Exception('Aucun audio trouvé pour ce verset.');
      }

      // On essaye de garder le même réciteur que celui choisi en haut
      final reciterKey = _selectedReciterKey ?? audioMap.keys.first;
      final reciter = audioMap[reciterKey] ?? audioMap.values.first;

      await _ayahPlayer.stop();
      await _ayahPlayer.play(
        UrlSource(
            reciter.originalUrl.isNotEmpty ? reciter.originalUrl : reciter.url),
      );
    } catch (e) {
      setState(() {
        _ayahError = e.toString();
        _playingAyahIndex = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAyahLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sourate ${widget.surahNo}'),
      ),
      body: FutureBuilder<SurahDetail>(
        future: _service.getSurahDetail(widget.surahNo),
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
          final verses = _getVerses(detail);

          // Préparer les réciteurs sur la sourate entière
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
              // HEADER
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.surahNameArabicLong,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${detail.surahName} • ${detail.surahNameTranslation}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${detail.revelationPlace} • ${detail.totalAyah} versets',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // LANGUE + RÉCITEUR (pour la sourate entière)
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

              const SizedBox(height: 8),

              // PLAYER GLOBAL POUR LA SOURATE ENTIÈRE
              QuranPlay(
                audioUrl: chapterAudioUrl,
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

              if (_isAyahLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),

              // LISTE DES VERSETS (clic pour jouer)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: verses.length,
                  itemBuilder: (context, index) {
                    final verseText = verses[index];
                    final isPlayingThisAyah = _playingAyahIndex == index;

                    return InkWell(
                      onTap: () => _playAyah(detail, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                verseText,
                                textAlign:
                                    _selectedLanguage.startsWith('arabic')
                                        ? TextAlign.right
                                        : TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isPlayingThisAyah
                                  ? Icons.volume_up
                                  : Icons.play_arrow,
                              color: isPlayingThisAyah
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                              size: 22,
                            ),
                          ],
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
