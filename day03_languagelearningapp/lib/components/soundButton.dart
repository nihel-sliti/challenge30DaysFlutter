import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SoundButton extends StatefulWidget {
  final String pathSound;
  const SoundButton({super.key, required this.pathSound});

  @override
  State<SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<SoundButton> {
  final AudioPlayer _player = AudioPlayer();

  bool isPlaying = false;
  Duration total = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.onDurationChanged.listen((d) {
      setState(() => total = d);
    });

    _player.onPositionChanged.listen((p) {
      setState(() => position = p);
    });

    _player.onPlayerComplete.listen((_) {
      setState(() {
        isPlaying = false;
        position = Duration.zero;
      });
    });
  }

  Future<void> _handleTap() async {
    if (!isPlaying) {
      setState(() => isPlaying = true);
      await _player.play(AssetSource(widget.pathSound));
    } else {
      setState(() => isPlaying = false);
      await _player.pause();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = total.inMilliseconds == 0
        ? 0
        : position.inMilliseconds / total.inMilliseconds;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: isPlaying ? progress : 0,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(Colors.white),
              strokeWidth: 3,
            ),
          ),
          IconButton(
            onPressed: _handleTap,
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
