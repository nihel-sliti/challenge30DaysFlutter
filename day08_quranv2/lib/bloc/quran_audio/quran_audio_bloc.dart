import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:quran_app/data/models/repeat_settings.dart';
import 'package:quran_app/data/models/surah_models.dart';
import 'package:quran_app/data/service/quran_service.dart';

part 'quran_audio_event.dart';
part 'quran_audio_state.dart';

class QuranAudioBloc extends Bloc<QuranAudioEvent, QuranAudioState> {
  final QuranService _quranService;
  final AudioPlayer _audioPlayer;

  // Cache pour les URLs audio
  final Map<int, Map<int, AudioReciter>> _ayahAudioCache = {};

  QuranAudioBloc({
    required QuranService quranService,
    required AudioPlayer audioPlayer,
  })  : _quranService = quranService,
        _audioPlayer = audioPlayer,
        super(QuranAudioState.initial()) {
    on<QuranAudioEvent>((event, emit) async {
      if (event is QuranAudioPlayAyahEvent) {
        await _onPlayAyah(event, emit);
      } else if (event is QuranAudioPlaySequentialEvent) {
        await _onPlaySequential(event, emit);
      } else if (event is QuranAudioStopPlaybackEvent) {
        await _onStopPlayback(emit);
      } else if (event is QuranAudioOnAudioCompletedEvent) {
        await _onAudioCompleted(emit);
      } else if (event is QuranAudioUpdateRepeatSettingsEvent) {
        _onUpdateRepeatSettings(event, emit);
      } else if (event is QuranAudioCacheAyahAudioEvent) {
        await _onCacheAyahAudio(event, emit);
      }
    });

    // Écouter les événements de fin de lecture
    _audioPlayer.onPlayerComplete.listen((_) {
      add(const QuranAudioOnAudioCompletedEvent());
    });
  }

  Future<void> _onPlayAyah(
    QuranAudioPlayAyahEvent event,
    Emitter<QuranAudioState> emit,
  ) async {
    emit(state.copyWith(
      status: QuranAudioStatus.loading,
      playingAyahIndex: event.index,
      error: null,
    ));

    try {
      final ayahNo = event.index + 1;

      // Vérifier le cache
      Map<int, AudioReciter>? audioMap = _ayahAudioCache[ayahNo];

      if (audioMap == null) {
        audioMap = await _quranService.getAyahAudio(event.surahNo, ayahNo);
        if (audioMap.isEmpty) {
          throw Exception('Aucun audio trouvé pour ce verset.');
        }
        _ayahAudioCache[ayahNo] = audioMap;
      }

      final reciterKey = event.reciterKey ?? audioMap.keys.first;
      final reciter = audioMap[reciterKey] ?? audioMap.values.first;

      await _audioPlayer.stop();
      await _audioPlayer.play(
        UrlSource(
          reciter.originalUrl.isNotEmpty ? reciter.originalUrl : reciter.url,
        ),
      );

      emit(state.copyWith(
        status: QuranAudioStatus.playing,
        surahDetail: event.surahDetail,
        selectedReciterKey: reciterKey,
        isSequentialMode: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: QuranAudioStatus.error,
        error: e.toString(),
        playingAyahIndex: null,
      ));
    }
  }

  Future<void> _onPlaySequential(
    QuranAudioPlaySequentialEvent event,
    Emitter<QuranAudioState> emit,
  ) async {
    final total = event.verses.length;
    final start = event.repeatSettings.fromAyah.clamp(1, total) - 1;
    final end = event.repeatSettings.toAyah.clamp(1, total) - 1;

    emit(state.copyWith(
      repeatSettings: event.repeatSettings,
      rangeStartIndex: start,
      rangeEndIndex: end,
      currentRangeLoop: 0,
      ayahRepeatsLeft: event.repeatSettings.ayahRepeatEnabled
          ? event.repeatSettings.ayahRepeatCount
          : 1,
    ));

    await _onPlayAyah(
      QuranAudioPlayAyahEvent(
        surahNo: event.surahNo,
        index: start,
        reciterKey: event.reciterKey,
        surahDetail: event.surahDetail,
      ),
      emit,
    );

    emit(state.copyWith(
      isSequentialMode: true,
      status: QuranAudioStatus.playing,
    ));
  }

  Future<void> _onStopPlayback(Emitter<QuranAudioState> emit) async {
    await _audioPlayer.stop();
    emit(state.copyWith(
      status: QuranAudioStatus.stopped,
      playingAyahIndex: null,
      isSequentialMode: false,
      currentRangeLoop: 0,
      ayahRepeatsLeft: state.repeatSettings.ayahRepeatEnabled
          ? state.repeatSettings.ayahRepeatCount
          : 1,
    ));
  }

  Future<void> _onAudioCompleted(Emitter<QuranAudioState> emit) async {
    if (!state.isSequentialMode || state.playingAyahIndex == null) {
      emit(state.copyWith(
        status: QuranAudioStatus.stopped,
        playingAyahIndex: null,
      ));
      return;
    }

    final totalVerses = state.verses.length;
    if (state.playingAyahIndex! < 0 || state.playingAyahIndex! >= totalVerses) {
      emit(state.copyWith(
        status: QuranAudioStatus.stopped,
        playingAyahIndex: null,
        isSequentialMode: false,
      ));
      return;
    }

    // 1) Répétition d'ayah
    if (state.repeatSettings.ayahRepeatEnabled && state.ayahRepeatsLeft > 1) {
      emit(state.copyWith(ayahRepeatsLeft: state.ayahRepeatsLeft - 1));

      add(QuranAudioPlayAyahEvent(
        surahNo: state.surahDetail!.surahNo,
        index: state.playingAyahIndex!,
        reciterKey: state.selectedReciterKey,
        surahDetail: state.surahDetail,
      ));
      return;
    }

    final newAyahRepeatsLeft = state.repeatSettings.ayahRepeatEnabled
        ? state.repeatSettings.ayahRepeatCount
        : 1;

    emit(state.copyWith(ayahRepeatsLeft: newAyahRepeatsLeft));

    // 2) Verset suivant dans le range
    var nextIndex = state.playingAyahIndex! + 1;

    if (nextIndex > state.rangeEndIndex) {
      // Fin du range
      if (state.repeatSettings.rangeRepeatEnabled) {
        if (state.repeatSettings.rangeRepeatCount == null) {
          // infini
          nextIndex = state.rangeStartIndex;
          emit(state.copyWith(currentRangeLoop: state.currentRangeLoop + 1));
        } else {
          if (state.currentRangeLoop + 1 >=
              state.repeatSettings.rangeRepeatCount!) {
            emit(state.copyWith(
              status: QuranAudioStatus.stopped,
              playingAyahIndex: null,
              isSequentialMode: false,
            ));
            return;
          } else {
            emit(state.copyWith(currentRangeLoop: state.currentRangeLoop + 1));
            nextIndex = state.rangeStartIndex;
          }
        }
      } else {
        emit(state.copyWith(
          status: QuranAudioStatus.stopped,
          playingAyahIndex: null,
          isSequentialMode: false,
        ));
        return;
      }
    }

    add(QuranAudioPlayAyahEvent(
      surahNo: state.surahDetail!.surahNo,
      index: nextIndex,
      reciterKey: state.selectedReciterKey,
      surahDetail: state.surahDetail,
    ));
  }

  Future<void> _onUpdateRepeatSettings(
    QuranAudioUpdateRepeatSettingsEvent event,
    Emitter<QuranAudioState> emit,
  ) async {
    emit(state.copyWith(repeatSettings: event.settings));
  }

  Future<void> _onCacheAyahAudio(
    QuranAudioCacheAyahAudioEvent event,
    Emitter<QuranAudioState> emit,
  ) async {
    try {
      final audioMap =
          await _quranService.getAyahAudio(event.surahNo, event.ayahNo);
      _ayahAudioCache[event.ayahNo] = audioMap;
      emit(state.copyWith(isAudioCached: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _audioPlayer.dispose();
    return super.close();
  }
}
