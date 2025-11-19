import 'package:audioplayers/audioplayers.dart';
import 'package:day08_quranv2/data/service/quran_service.dart';
import 'package:day08_quranv2/bloc/quran_audio/quran_audio_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class QuranAudioProvider extends ChangeNotifier {
  late final QuranAudioBloc audioBloc;
  late final AudioPlayer audioPlayer;
  late final QuranService quranService;

  QuranAudioProvider({
    required this.quranService,
    required this.audioPlayer,
  }) {
    audioBloc = QuranAudioBloc(
      quranService: quranService,
      audioPlayer: audioPlayer,
    );
  }

  @override
  void dispose() {
    audioBloc.close();
    super.dispose();
  }
}

// Extension pour faciliter l'utilisation du BLOC dans les widgets
extension BuildContextExtension on BuildContext {
  QuranAudioBloc get audioBloc => read<QuranAudioBloc>();
}
