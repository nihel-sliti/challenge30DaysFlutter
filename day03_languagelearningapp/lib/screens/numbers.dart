import 'package:day03_languagelearningapp/components/item.dart';
import 'package:day03_languagelearningapp/models/numbers.dart';
import 'package:flutter/material.dart';

class NumbersPage extends StatelessWidget {
  NumbersPage({super.key});
  final List<Numbers> numbers = const [
    Numbers(
      image: 'assets/images/numbers/number_one.png',
      nameJapanese: 'ichi',
      nameEnglish: 'one',
      path: 'sounds/numbers/number_one_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_two.png',
      nameJapanese: 'ni',
      nameEnglish: 'two',
      path: 'sounds/numbers/number_two_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_three.png',
      nameJapanese: 'san',
      nameEnglish: 'three',
      path: 'sounds/numbers/number_three_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_four.png',
      nameJapanese: 'yon', // ou 'shi'
      nameEnglish: 'four',
      path: 'sounds/numbers/number_four_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_five.png',
      nameJapanese: 'go',
      nameEnglish: 'five',
      path: 'sounds/numbers/number_five_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_six.png',
      nameJapanese: 'roku',
      nameEnglish: 'six',
      path: 'sounds/numbers/number_six_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_seven.png',
      nameJapanese: 'nana', // ou 'shichi'
      nameEnglish: 'seven',
      path: 'sounds/numbers/number_seven_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_eight.png',
      nameJapanese: 'hachi',
      nameEnglish: 'eight',
      path: 'sounds/numbers/number_eight_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_nine.png',
      nameJapanese: 'kyuu',
      nameEnglish: 'nine',
      path: 'sounds/numbers/number_nine_sound.mp3',
    ),
    Numbers(
      image: 'assets/images/numbers/number_ten.png',
      nameJapanese: 'juu',
      nameEnglish: 'ten',
      path: 'sounds/numbers/number_ten_sound.mp3',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Numbers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xff46322B),
      ),
      body: ListView.builder(
        itemCount: numbers.length,
        itemBuilder: (context, index) {
          return item(number: numbers[index]);
        },
      ),
    );
  }
}
