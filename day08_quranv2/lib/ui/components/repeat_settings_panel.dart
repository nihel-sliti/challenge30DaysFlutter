import 'package:day08_quranv2/data/models/repeat_settings.dart';
import 'package:day08_quranv2/data/models/surah_models.dart';
import 'package:flutter/material.dart';

class RepeatSettingsPanel extends StatefulWidget {
  final int totalAyah;
  final RepeatSettings initial;
  final ValueChanged<RepeatSettings>? onChanged;

  const RepeatSettingsPanel({
    super.key,
    required this.totalAyah,
    required this.initial,
    this.onChanged,
  });

  @override
  State<RepeatSettingsPanel> createState() => _RepeatSettingsPanelState();
}

class _RepeatSettingsPanelState extends State<RepeatSettingsPanel> {
  late RepeatSettings _settings;
  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
  }

  void _notify() {
    if (widget.onChanged != null) {
      widget.onChanged!(_settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      // RTL pour l’arabe
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            Center(
              child: Text(
                'إعدادات التكرار',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 24),

            // ====== Section : النطاق ======
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'النطاق',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('من'),
                    trailing: DropdownButton<int>(
                      value: _settings.fromAyah,
                      items: List.generate(widget.totalAyah, (i) => i + 1)
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text('الآية: $n'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _settings = _settings.copyWith(
                            fromAyah: value,
                            toAyah: value > _settings.toAyah
                                ? value
                                : _settings.toAyah,
                          );
                        });
                        _notify();
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('إلى'),
                    trailing: DropdownButton<int>(
                      value: _settings.toAyah,
                      items: List.generate(widget.totalAyah, (i) => i + 1)
                          .map(
                            (n) => DropdownMenuItem(
                              value: n,
                              child: Text('الآية: $n'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _settings = _settings.copyWith(
                            toAyah: value < _settings.fromAyah
                                ? _settings.fromAyah
                                : value,
                          );
                        });
                        _notify();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ====== Section : تكرار النطاق ======
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'التكرار',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _settings.rangeRepeatEnabled,
                    onChanged: (v) {
                      setState(() {
                        _settings = _settings.copyWith(rangeRepeatEnabled: v);
                      });
                      _notify();
                    },
                    title: const Text('تكرار النطاق'),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Boutons + -
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: !_settings.rangeRepeatEnabled
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_settings.rangeRepeatCount ==
                                              null) {
                                            _settings = _settings.copyWith(
                                              rangeRepeatCount: 1,
                                            );
                                          } else {
                                            _settings = _settings.copyWith(
                                              rangeRepeatCount:
                                                  _settings.rangeRepeatCount! +
                                                      1,
                                            );
                                          }
                                        });
                                        _notify();
                                      },
                              ),
                              const VerticalDivider(width: 1),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: !_settings.rangeRepeatEnabled
                                    ? null
                                    : () {
                                        setState(() {
                                          final current =
                                              _settings.rangeRepeatCount;
                                          if (current == null) return;
                                          if (current <= 1) {
                                            _settings = _settings.copyWith(
                                              rangeRepeatCount: null,
                                            );
                                          } else {
                                            _settings = _settings.copyWith(
                                              rangeRepeatCount: current - 1,
                                            );
                                          }
                                        });
                                        _notify();
                                      },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'التكرارات',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _settings.rangeRepeatCount == null
                                ? '∞'
                                : _settings.rangeRepeatCount.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ====== Section : تكرار الآية ======
            Card(
              color: theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _settings.ayahRepeatEnabled,
                    onChanged: (v) {
                      setState(() {
                        _settings = _settings.copyWith(ayahRepeatEnabled: v);
                      });
                      _notify();
                    },
                    title: const Text('تكرار الآية'),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: !_settings.ayahRepeatEnabled
                                    ? null
                                    : () {
                                        setState(() {
                                          _settings = _settings.copyWith(
                                            ayahRepeatCount:
                                                _settings.ayahRepeatCount + 1,
                                          );
                                        });
                                        _notify();
                                      },
                              ),
                              const VerticalDivider(width: 1),
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: !_settings.ayahRepeatEnabled
                                    ? null
                                    : () {
                                        setState(() {
                                          if (_settings.ayahRepeatCount > 1) {
                                            _settings = _settings.copyWith(
                                              ayahRepeatCount:
                                                  _settings.ayahRepeatCount - 1,
                                            );
                                          }
                                        });
                                        _notify();
                                      },
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'التكرارات',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _settings.ayahRepeatCount.toString(),
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
