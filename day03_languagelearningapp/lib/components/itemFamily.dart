import 'package:audioplayers/audioplayers.dart';
import 'package:day03_languagelearningapp/components/soundButton.dart';
import 'package:day03_languagelearningapp/models/family.dart';
import 'package:day03_languagelearningapp/models/numbers.dart';
import 'package:flutter/material.dart';

class itemFamily extends StatelessWidget {
  itemFamily({
    required this.familyNumbers,
  });
  final FamilyNumbers familyNumbers;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.purple,
      child: Row(
        children: [
          Image.asset(familyNumbers.image),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  familyNumbers.nameJapanese,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  familyNumbers.nameEnglish,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Spacer(
            flex: 1,
          ),
          SoundButton(pathSound: familyNumbers.path),
        ],
      ),
    );
  }
}
