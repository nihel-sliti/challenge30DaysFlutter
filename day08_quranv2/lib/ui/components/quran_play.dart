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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message d'erreur amélioré
          if (_error != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.red.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Section du slider avec design amélioré
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Slider avec thumb personnalisé
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: primary,
                    inactiveTrackColor: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.1),
                    thumbColor: primary,
                    overlayColor: primary.withOpacity(0.15),
                    trackHeight: 8,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 16,
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
                const SizedBox(height: 16),
                // Temps avec design amélioré
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primary.withOpacity(0.15),
                            primary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _fmt(_position),
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.secondary.withOpacity(0.15),
                            theme.colorScheme.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _fmt(_duration),
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contrôles avec design premium
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Bouton Loop
              _buildControlButton(
                icon: Icons.repeat,
                color: loopColor,
                isActive: _loopEnabled,
                backgroundColor: _loopEnabled
                    ? primary.withOpacity(0.15)
                    : Colors.transparent,
                onPressed: () {
                  setState(() => _loopEnabled = !_loopEnabled);
                },
                tooltip: "Loop infini",
                size: 44,
              ),

              // Bouton Replay
              _buildControlButton(
                icon: Icons.replay,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                onPressed: _loading ? null : _replay,
                tooltip: "Rejouer",
                size: 44,
              ),

              // Bouton -15s
              _buildControlButton(
                icon: Icons.replay_10,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                onPressed: _loading ? null : () => _skip(-15),
                tooltip: "Reculer 15s",
                size: 44,
              ),

              // Bouton Play/Pause agrandi et amélioré
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primary,
                      primary.withOpacity(0.85),
                      primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    if (_isPlaying)
                      BoxShadow(
                        color: primary.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _loading ? null : _togglePlay,
                    child: Center(
                      child: _loading
                          ? SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.5,
                                color: Colors.white,
                              ),
                            )
                          : AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_fill,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Bouton +15s
              _buildControlButton(
                icon: Icons.forward_10,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                onPressed: _loading ? null : () => _skip(15),
                tooltip: "Avancer 15s",
                size: 44,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget helper pour les boutons de contrôle
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required String tooltip,
    double size = 40,
    Color? backgroundColor,
    bool isActive = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: color, width: 2)
            : Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Tooltip(
            message: tooltip,
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: size * 0.55,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
