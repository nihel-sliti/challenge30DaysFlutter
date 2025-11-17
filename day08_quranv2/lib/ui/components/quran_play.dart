import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class QuranPlay extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const QuranPlay({
    super.key,
    required this.audioUrl,
    this.onPrevious,
    this.onNext,
  });

  @override
  State<QuranPlay> createState() => _QuranPlayState();
}

class _QuranPlayState extends State<QuranPlay> {
  late final AudioPlayer _player;

  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _isPlaying = false;
  bool _loading = false;
  String? _error;

  bool _loopEnabled = false; // <<< LOOP INFINI

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    // Durée totale
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    // Position
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    // État play/pause
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    // <<< AUTO LOOP FIABLE (SANS TIMEOUT) >>>
    _player.onPlayerComplete.listen((_) async {
      if (_loopEnabled) {
        try {
          await _player.stop(); // reset
          await Future.delayed(
              const Duration(milliseconds: 250)); // évite timeout
          await _player.play(
            UrlSource(widget.audioUrl),
            position: Duration.zero,
          );
        } catch (e) {
          if (mounted) {
            setState(() => _error = "Loop error: $e");
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _position = Duration.zero;
            _isPlaying = false;
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuranPlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl) {
      _player.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _error = null;
      _isPlaying = false;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // PLAY / PAUSE
  Future<void> _togglePlay() async {
    if (widget.audioUrl.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        final startPos =
            (_position >= _duration - const Duration(milliseconds: 300))
                ? Duration.zero
                : _position;

        await _player.play(
          UrlSource(widget.audioUrl),
          position: startPos,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = "$e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // REPLAY
  Future<void> _replay() async {
    if (widget.audioUrl.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _player.stop();
      await Future.delayed(const Duration(milliseconds: 200));

      await _player.play(
        UrlSource(widget.audioUrl),
        position: Duration.zero,
      );
    } catch (e) {
      setState(() => _error = "$e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // Skip ± secondes
  Future<void> _skip(int sec) async {
    final newPos = _position + Duration(seconds: sec);

    Duration target;
    if (newPos < Duration.zero) {
      target = Duration.zero;
    } else if (newPos > _duration) {
      target = _duration;
    } else {
      target = newPos;
    }

    await _player.seek(target);
  }

  String _fmt(Duration d) {
    String t(int n) => n.toString().padLeft(2, '0');
    return "${t(d.inMinutes)}:${t(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = theme.colorScheme.primary;
    final loopColor = _loopEnabled
        ? primary
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade500);

    final maxSec = _duration.inSeconds > 0 ? _duration.inSeconds : 1;
    final current = _position.inSeconds.clamp(0, maxSec).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),

        // SLIDER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primary,
                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                  thumbColor: primary,
                ),
                child: Slider(
                  min: 0,
                  max: maxSec.toDouble(),
                  value: current,
                  onChanged: _loading
                      ? null
                      : (v) => _player.seek(Duration(seconds: v.toInt())),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_fmt(_position),
                      style: TextStyle(color: theme.colorScheme.onSurface)),
                  Text(_fmt(_duration),
                      style: TextStyle(color: theme.colorScheme.onSurface)),
                ],
              ),
            ],
          ),
        ),

        if (_loading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),

        // BOUTONS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // LOOP
            IconButton(
              icon: Icon(Icons.repeat, color: loopColor, size: 28),
              onPressed: () {
                setState(() => _loopEnabled = !_loopEnabled);
              },
              tooltip: "Loop infini",
            ),

            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: _loading ? null : _replay,
            ),

            IconButton(
              icon: const Icon(Icons.replay_10),
              onPressed: _loading ? null : () => _skip(-15),
            ),

            IconButton(
              iconSize: 40,
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: primary,
              ),
              onPressed: _loading ? null : _togglePlay,
            ),

            IconButton(
              icon: const Icon(Icons.forward_10),
              onPressed: _loading ? null : () => _skip(15),
            ),
          ],
        ),
      ],
    );
  }
}
