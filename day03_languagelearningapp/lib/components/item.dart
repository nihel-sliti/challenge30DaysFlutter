import 'package:audioplayers/audioplayers.dart';
import 'package:day03_languagelearningapp/models/numbers.dart';
import 'package:flutter/material.dart';

class item extends StatelessWidget {
  item({
    required this.number,
  });
  final Numbers number;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.orange,
      child: Row(
        children: [
          Image.asset(number.image),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  number.nameJapanese,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  number.nameEnglish,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Spacer(
            flex: 1,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: () {
                final player = AudioPlayer();
                player.play(AssetSource(number.path));
              },
              icon: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
