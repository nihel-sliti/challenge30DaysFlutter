class RepeatSettings {
  int fromAyah;
  int toAyah;
  bool rangeRepeatEnabled;
  int? rangeRepeatCount; // null = infini
  bool ayahRepeatEnabled;
  int ayahRepeatCount;

  RepeatSettings({
    required this.fromAyah,
    required this.toAyah,
    this.rangeRepeatEnabled = false,
    this.rangeRepeatCount,
    this.ayahRepeatEnabled = false,
    this.ayahRepeatCount = 1,
  });

  RepeatSettings copyWith({
    int? fromAyah,
    int? toAyah,
    bool? rangeRepeatEnabled,
    int? rangeRepeatCount,
    bool? ayahRepeatEnabled,
    int? ayahRepeatCount,
  }) {
    return RepeatSettings(
      fromAyah: fromAyah ?? this.fromAyah,
      toAyah: toAyah ?? this.toAyah,
      rangeRepeatEnabled: rangeRepeatEnabled ?? this.rangeRepeatEnabled,
      rangeRepeatCount: rangeRepeatCount ?? this.rangeRepeatCount,
      ayahRepeatEnabled: ayahRepeatEnabled ?? this.ayahRepeatEnabled,
      ayahRepeatCount: ayahRepeatCount ?? this.ayahRepeatCount,
    );
  }
}
