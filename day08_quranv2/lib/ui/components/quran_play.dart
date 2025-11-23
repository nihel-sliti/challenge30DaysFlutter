import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class QuranPlay extends StatefulWidget {
  final String audioUrl;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final Future<String?> Function()?
      localPath; // Ajout du paramètre pour chemin local

  const QuranPlay({
    super.key,
    required this.audioUrl,
    this.onPrevious,
    this.onNext,
    this.localPath, // Ajout du paramètre optionnel
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

  bool _loopEnabled = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _player.onPlayerComplete.listen((_) async {
      if (_loopEnabled) {
        try {
          await _player.stop();
          await Future.delayed(const Duration(milliseconds: 250));

          // 🔹 PRIORITÉ: Vérifier d'abord si un fichier local existe pour la boucle
          if (widget.localPath != null) {
            final localPath = await widget.localPath!();
            if (localPath != null) {
              await _player.play(
                DeviceFileSource(localPath),
                position: Duration.zero,
              );
              return;
            }
          }

          // 🔹 FALLBACK: Utiliser l'URL distante pour la boucle
          if (widget.audioUrl.isNotEmpty) {
            await _player.play(
              UrlSource(widget.audioUrl),
              position: Duration.zero,
            );
          }
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

  Future<void> _togglePlay() async {
    // 🔹 PRIORITÉ: Vérifier d'abord si un fichier local existe
    if (widget.localPath != null) {
      final localPath = await widget.localPath!();
      if (localPath != null) {
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
              DeviceFileSource(localPath),
              position: startPos,
            );
          }
        } catch (e) {
          if (mounted) setState(() => _error = "$e");
        } finally {
          if (mounted) setState(() => _loading = false);
        }
        return;
      }
    }

    // 🔹 FALLBACK: Utiliser l'URL distante si pas de fichier local
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

  Future<void> _replay() async {
    // 🔹 PRIORITÉ: Vérifier d'abord si un fichier local existe
    if (widget.localPath != null) {
      final localPath = await widget.localPath!();
      if (localPath != null) {
        setState(() {
          _loading = true;
          _error = null;
        });

        try {
          await _player.stop();
          await Future.delayed(const Duration(milliseconds: 200));

          await _player.play(
            DeviceFileSource(localPath),
            position: Duration.zero,
          );
        } catch (e) {
          setState(() => _error = "$e");
        } finally {
          setState(() => _loading = false);
        }
        return;
      }
    }

    // 🔹 FALLBACK: Utiliser l'URL distante si pas de fichier local
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Play/Pause ultra-compact
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primary.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _loading ? null : _togglePlay,
                child: Center(
                  child: _loading
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Temps et slider ultra-compact
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Slider ultra-minimaliste
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primary,
                    inactiveTrackColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.08),
                    thumbColor: primary,
                    overlayColor: primary.withOpacity(0.1),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 10,
                    ),
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

                // Temps ultra-compact
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fmt(_position),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        _fmt(_duration),
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Contrôles ultra-compact
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Loop
              _buildCompactButton(
                icon: Icons.repeat,
                color: loopColor,
                isActive: _loopEnabled,
                backgroundColor: _loopEnabled
                    ? primary.withOpacity(0.1)
                    : Colors.transparent,
                onPressed: () {
                  setState(() => _loopEnabled = !_loopEnabled);
                },
                tooltip: "Loop",
                size: 32,
              ),

              const SizedBox(width: 6),

              // Bouton Replay
              _buildCompactButton(
                icon: Icons.replay,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                onPressed: _loading ? null : _replay,
                tooltip: "Rejouer",
                size: 32,
              ),

              const SizedBox(width: 6),

              // Bouton -15s
              _buildCompactButton(
                icon: Icons.replay_10,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                onPressed: _loading ? null : () => _skip(-15),
                tooltip: "-15s",
                size: 32,
              ),

              const SizedBox(width: 6),

              // Bouton +15s
              _buildCompactButton(
                icon: Icons.forward_10,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                onPressed: _loading ? null : () => _skip(15),
                tooltip: "+15s",
                size: 32,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bouton ultra-compact pour les contrôles
  Widget _buildCompactButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
    double size = 32,
    Color? backgroundColor,
    bool isActive = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: color, width: 1)
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: 1,
              ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
