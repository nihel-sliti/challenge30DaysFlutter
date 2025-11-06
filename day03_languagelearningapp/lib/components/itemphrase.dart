import 'package:audioplayers/audioplayers.dart';
import 'package:day03_languagelearningapp/components/soundButton.dart';
import 'package:day03_languagelearningapp/models/phrase.dart';
import 'package:flutter/material.dart';

class itemphrases extends StatelessWidget {
  itemphrases({
    required this.phrases,
  });
  final Phrases phrases;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.blue,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phrases.nameJapanese,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  phrases.nameEnglish,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Spacer(
            flex: 1,
          ),
          SoundButton(pathSound: phrases.path),
        ],
      ),
    );
  }
}
