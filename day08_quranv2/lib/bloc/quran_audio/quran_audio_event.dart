part of 'quran_audio_bloc.dart';

abstract class QuranAudioEvent extends Equatable {
  const QuranAudioEvent();

  @override
  List<Object?> get props => [];
}

class QuranAudioPlayAyahEvent extends QuranAudioEvent {
  final int surahNo;
  final int index;
  final int? reciterKey;
  final SurahDetail? surahDetail;

  const QuranAudioPlayAyahEvent({
    required this.surahNo,
    required this.index,
    this.reciterKey,
    this.surahDetail,
  });

  @override
  List<Object?> get props => [surahNo, index, reciterKey, surahDetail];
}

class QuranAudioPlaySequentialEvent extends QuranAudioEvent {
  final int surahNo;
  final List<String> verses;
  final RepeatSettings repeatSettings;
  final int? reciterKey;
  final SurahDetail? surahDetail;

  const QuranAudioPlaySequentialEvent({
    required this.surahNo,
    required this.verses,
    required this.repeatSettings,
    this.reciterKey,
    this.surahDetail,
  });

  @override
  List<Object?> get props =>
      [surahNo, verses, repeatSettings, reciterKey, surahDetail];
}

class QuranAudioStopPlaybackEvent extends QuranAudioEvent {
  const QuranAudioStopPlaybackEvent();
}

class QuranAudioOnAudioCompletedEvent extends QuranAudioEvent {
  const QuranAudioOnAudioCompletedEvent();
}

class QuranAudioUpdateRepeatSettingsEvent extends QuranAudioEvent {
  final RepeatSettings settings;

  const QuranAudioUpdateRepeatSettingsEvent({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}

class QuranAudioCacheAyahAudioEvent extends QuranAudioEvent {
  final int surahNo;
  final int ayahNo;

  const QuranAudioCacheAyahAudioEvent({
    required this.surahNo,
    required this.ayahNo,
  });

  @override
  List<Object> get props => [surahNo, ayahNo];
}
