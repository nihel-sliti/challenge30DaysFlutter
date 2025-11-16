import 'package:day07_alquran/data/models/quran_models.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SurahDetailScreen extends StatefulWidget {
  final SurahModel surah;

  const SurahDetailScreen({super.key, required this.surah});

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late final AudioPlayer _audioPlayer;
  String? _currentlyPlayingAyah;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAyahAudio(String audioUrl, String ayahIdentifier) async {
    try {
      // Si le même verset joue déjà → on stoppe
      if (_currentlyPlayingAyah == ayahIdentifier) {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingAyah = null;
        });
        return;
      }

      // Stop tout ce qui joue
      await _audioPlayer.stop();

      // Lecture depuis une URL (mp3)
      await _audioPlayer.play(UrlSource(audioUrl));
      setState(() {
        _currentlyPlayingAyah = ayahIdentifier;
      });

      _audioPlayer.onPlayerComplete.listen((_) {
        if (!mounted) return;
        setState(() {
          _currentlyPlayingAyah = null;
        });
      });
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _currentlyPlayingAyah = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de lecture audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.name)),
      body: ListView.builder(
        itemCount: widget.surah.ayahs.length,
        itemBuilder: (context, index) {
          final ayah = widget.surah.ayahs[index];
          final ayahIdentifier = '${widget.surah.number}_${ayah.numberInSurah}';
          final isPlaying = _currentlyPlayingAyah == ayahIdentifier;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${ayah.numberInSurah}'),
              ),
              title: Text(
                ayah.text,
                style: const TextStyle(fontSize: 18, height: 1.5),
                textDirection: TextDirection.rtl,
              ),
              trailing: ayah.audio.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow,
                        color: isPlaying ? Colors.red : Colors.green,
                      ),
                      onPressed: () =>
                          _playAyahAudio(ayah.audio, ayahIdentifier),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
