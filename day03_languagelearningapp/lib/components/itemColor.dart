import 'package:audioplayers/audioplayers.dart';
import 'package:day03_languagelearningapp/components/soundButton.dart';
import 'package:day03_languagelearningapp/models/colors.dart';
import 'package:day03_languagelearningapp/models/numbers.dart';
import 'package:flutter/material.dart';

class itemColors extends StatelessWidget {
  itemColors({
    required this.colorsModel,
  });
  final ColorsModel colorsModel;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.orange,
      child: Row(
        children: [
          Image.asset(colorsModel.image),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  colorsModel.nameJapanese,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  colorsModel.nameEnglish,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Spacer(
            flex: 1,
          ),
          SoundButton(pathSound: colorsModel.path),
        ],
      ),
    );
  }
}
