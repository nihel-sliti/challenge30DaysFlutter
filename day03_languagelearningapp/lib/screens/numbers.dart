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
        path: 'sounds/numbers/number_one_sound.mp3'),
    Numbers(
        image: 'assets/images/numbers/number_two.png',
        nameJapanese: 'Ni',
        nameEnglish: 'two',
        path: 'sounds/numbers/number_two_sound.mp3'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Numbers'),
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
