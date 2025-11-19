part of 'quran_audio_bloc.dart';

enum QuranAudioStatus {
  initial,
  loading,
  playing,
  stopped,
  error,
}

class QuranAudioState extends Equatable {
  QuranAudioState({
    required this.status,
    this.playingAyahIndex,
    this.surahDetail,
    this.selectedReciterKey,
    this.isSequentialMode = false,
    repeatSettings,
    this.rangeStartIndex = 0,
    this.rangeEndIndex = 0,
    this.currentRangeLoop = 0,
    this.ayahRepeatsLeft = 1,
    this.verses = const [],
    this.error,
    this.isAudioCached = false,
  }) : repeatSettings = repeatSettings ??
            RepeatSettings(
              fromAyah: 1,
              toAyah: 1,
              rangeRepeatEnabled: false,
              rangeRepeatCount: null,
              ayahRepeatEnabled: false,
              ayahRepeatCount: 1,
            );

  final QuranAudioStatus status;
  final int? playingAyahIndex;
  final SurahDetail? surahDetail;
  final int? selectedReciterKey;
  final bool isSequentialMode;
  final RepeatSettings repeatSettings;
  final int rangeStartIndex;
  final int rangeEndIndex;
  final int currentRangeLoop;
  final int ayahRepeatsLeft;
  final List<String> verses;
  final String? error;
  final bool isAudioCached;

  QuranAudioState copyWith({
    QuranAudioStatus? status,
    int? playingAyahIndex,
    SurahDetail? surahDetail,
    int? selectedReciterKey,
    bool? isSequentialMode,
    RepeatSettings? repeatSettings,
    int? rangeStartIndex,
    int? rangeEndIndex,
    int? currentRangeLoop,
    int? ayahRepeatsLeft,
    List<String>? verses,
    String? error,
    bool? isAudioCached,
  }) {
    return QuranAudioState(
      status: status ?? this.status,
      playingAyahIndex: playingAyahIndex ?? this.playingAyahIndex,
      surahDetail: surahDetail ?? this.surahDetail,
      selectedReciterKey: selectedReciterKey ?? this.selectedReciterKey,
      isSequentialMode: isSequentialMode ?? this.isSequentialMode,
      repeatSettings: repeatSettings ?? this.repeatSettings,
      rangeStartIndex: rangeStartIndex ?? this.rangeStartIndex,
      rangeEndIndex: rangeEndIndex ?? this.rangeEndIndex,
      currentRangeLoop: currentRangeLoop ?? this.currentRangeLoop,
      ayahRepeatsLeft: ayahRepeatsLeft ?? this.ayahRepeatsLeft,
      verses: verses ?? this.verses,
      error: error ?? this.error,
      isAudioCached: isAudioCached ?? this.isAudioCached,
    );
  }

  factory QuranAudioState.initial() {
    return QuranAudioState(
      status: QuranAudioStatus.initial,
      verses: [],
    );
  }

  @override
  List<Object?> get props => [
        status,
        playingAyahIndex,
        surahDetail,
        selectedReciterKey,
        isSequentialMode,
        repeatSettings,
        rangeStartIndex,
        rangeEndIndex,
        currentRangeLoop,
        ayahRepeatsLeft,
        verses,
        error,
        isAudioCached,
      ];

  @override
  String toString() =>
      'QuranAudioState(status: $status, playingAyahIndex: $playingAyahIndex, error: $error)';
}
