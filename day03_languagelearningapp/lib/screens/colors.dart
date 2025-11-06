import 'package:day03_languagelearningapp/components/item.dart';
import 'package:day03_languagelearningapp/components/itemColor.dart';
import 'package:day03_languagelearningapp/models/colors.dart';
import 'package:day03_languagelearningapp/models/numbers.dart';
import 'package:flutter/material.dart';

class colors extends StatelessWidget {
  colors({super.key});
  final List<ColorsModel> colorsList = const [
    ColorsModel(
      image: 'assets/images/colors/color_black.png',
      nameJapanese: 'kuro', // 黒
      nameEnglish: 'black',
      path: 'sounds/colors/black.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/color_brown.png',
      nameJapanese: 'chairo', // 茶色
      nameEnglish: 'brown',
      path: 'sounds/colors/brown.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/color_dusty_yellow.png',
      nameJapanese: 'kawaita kiiro', // 乾いた黄色 (approx "dusty yellow")
      nameEnglish: 'dusty yellow',
      path: 'sounds/colors/dusty yellow.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/color_gray.png',
      nameJapanese: 'haiiro', // 灰色
      nameEnglish: 'gray',
      path: 'sounds/colors/gray.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/color_green.png',
      nameJapanese: 'midori', // 緑
      nameEnglish: 'green',
      path: 'sounds/colors/green.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/color_red.png',
      nameJapanese: 'aka', // 赤
      nameEnglish: 'red',
      path: 'sounds/colors/red.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/color_white.png',
      nameJapanese: 'shiro', // 白
      nameEnglish: 'white',
      path: 'sounds/colors/white.wav',
    ),
    ColorsModel(
      image: 'assets/images/colors/yellow.png',
      nameJapanese: 'kiiro', // 黄色
      nameEnglish: 'yellow',
      path: 'sounds/colors/yellow.wav',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Colors',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xff46322B),
      ),
      body: ListView.builder(
        itemCount: colorsList.length,
        itemBuilder: (context, index) {
          return itemColors(colorsModel: colorsList[index]);
        },
      ),
    );
    ;
  }
}
