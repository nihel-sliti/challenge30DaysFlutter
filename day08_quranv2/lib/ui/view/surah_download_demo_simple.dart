import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:day08_quranv2/data/service/surah_download_service.dart';
import 'dart:io';

/// 🔥 **ÉCRAN DE DÉMONSTRATION SIMPLIFIÉ** - Téléchargement et lecture de sourates
class SurahDownloadDemoSimple extends StatefulWidget {
  const SurahDownloadDemoSimple({super.key});

  @override
  State<SurahDownloadDemoSimple> createState() =>
      _SurahDownloadDemoSimpleState();
}

class _SurahDownloadDemoSimpleState extends State<SurahDownloadDemoSimple> {
  final SurahDownloadService _downloadService = SurahDownloadService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // États de l'interface
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _currentFilePath;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _statusMessage = 'Prêt à télécharger';

  // Liste des sourates populaires pour démo
  final List<Map<String, dynamic>> _popularSurahs = [
    {'number': 1, 'name': 'Al-Fatiha', 'arabic': 'الفاتحة'},
    {'number': 2, 'name': 'Al-Baqarah', 'arabic': 'البقرة'},
    {'number': 3, 'name': 'Aal-E-Imran', 'arabic': 'آل عمران'},
    {'number': 36, 'name': 'Ya-Sin', 'arabic': 'يس'},
    {'number': 55, 'name': 'Ar-Rahman', 'arabic': 'الرحمن'},
    {'number': 67, 'name': 'Al-Mulk', 'arabic': 'الملك'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  /// Initialise le lecteur audio avec les listeners
  void _initializeAudioPlayer() {
    // Listener pour les changements de durée
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });

    // Listener pour les changements de position
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listener pour les changements d'état
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Listener pour la fin de lecture
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  /// 🔥 **FONCTION DE TÉLÉCHARGEMENT** - Lance le download avec progression
  Future<void> _downloadSurah(int surahNumber, String surahName) async {
    if (_isDownloading) return; // Éviter les téléchargements multiples

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _statusMessage = 'Téléchargement de $surahName...';
    });

    try {
      // Utiliser notre service de téléchargement
      final file = await _downloadService.downloadSurah(
        surahNumber: surahNumber,
        surahName: surahName,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
              _statusMessage = 'Téléchargement: ${(progress * 100).toInt()}%';
            });
          }
        },
      );

      if (file != null) {
        final fileSize = await file.length();
        setState(() {
          _currentFilePath = file.path;
          _isDownloading = false;
          _downloadProgress = 1.0;
          _statusMessage =
              '✅ Téléchargement terminé (${_downloadService.formatSize(fileSize)})';
        });
      } else {
        setState(() {
          _isDownloading = false;
          _statusMessage = '❌ Échec du téléchargement';
        });
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _statusMessage = '❌ Erreur: ${e.toString()}';
      });
    }
  }

  /// 🔊 **FONCTION DE LECTURE** - Joue le fichier local
  Future<void> _playLocalAudio(String filePath) async {
    try {
      setState(() {
        _statusMessage = 'Lecture audio...';
      });

      // Utiliser DeviceFileSource pour les fichiers locaux
      await _audioPlayer.play(DeviceFileSource(filePath));

      setState(() {
        _statusMessage = '🔊 En cours de lecture';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Erreur de lecture: ${e.toString()}';
      });
    }
  }

  /// Met en pause la lecture
  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    setState(() {
      _statusMessage = '⏸ En pause';
    });
  }

  /// Arrête la lecture
  Future<void> _stopAudio() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _statusMessage = '⏹ Arrêté';
    });
  }

  /// Formate la durée en MM:SS
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          '📥 Téléchargement Sourates',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📊 **CARTE D'ÉTAT**
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      _isDownloading
                          ? Icons.download
                          : _isPlaying
                              ? Icons.volume_up
                              : Icons.cloud_download,
                      size: 48,
                      color: _isDownloading
                          ? Colors.blue
                          : _isPlaying
                              ? Colors.green
                              : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 📈 **BARRE DE PROGRESSION**
                    if (_isDownloading)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(_downloadProgress * 100).toInt()}%',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🎵 **LECTEUR AUDIO** (si fichier disponible)
            if (_currentFilePath != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.music_note,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fichier audio prêt',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 🎛️ **CONTROLES DE LECTURE**
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Bouton Play/Pause
                          IconButton(
                            onPressed: _isPlaying
                                ? _pauseAudio
                                : () => _playLocalAudio(_currentFilePath!),
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Bouton Stop
                          IconButton(
                            onPressed: _stopAudio,
                            icon: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 32,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 📊 **INFORMATIONS TEMPORELLES**
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // 📜 **LISTE DES SOURATES**
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📖 Sourates disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _popularSurahs.length,
                          itemBuilder: (context, index) {
                            final surah = _popularSurahs[index];
                            final isDownloaded = _currentFilePath != null &&
                                _currentFilePath!
                                    .contains('surah_${surah['number']}.mp3');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDownloaded
                                      ? Colors.green.shade50
                                      : Colors.white,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: isDownloaded
                                        ? Colors.green.shade600
                                        : Colors.blue.shade600,
                                    child: Text(
                                      '${surah['number']}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    surah['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    surah['arabic'] ?? '',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: isDownloaded
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : ElevatedButton(
                                          onPressed: _isDownloading
                                              ? null
                                              : () => _downloadSurah(
                                                    surah['number'],
                                                    surah['name'],
                                                  ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade600,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: _isDownloading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                              : const Text('Télécharger'),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
