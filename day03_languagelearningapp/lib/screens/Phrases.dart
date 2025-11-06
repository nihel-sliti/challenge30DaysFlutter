import 'package:day03_languagelearningapp/components/itemphrase.dart';
import 'package:day03_languagelearningapp/models/phrase.dart';
import 'package:flutter/material.dart';

class PhrasesPage extends StatelessWidget {
  PhrasesPage({super.key});
  final List<Phrases> phrases = const [
    Phrases(
      nameJapanese: 'Kimasu ka?', // 来ますか？
      nameEnglish: 'Are you coming?',
      path: 'sounds/phrases/are_you_coming.wav',
    ),
    Phrases(
      nameJapanese: 'Kōdoku wasurenai de', // 購読忘れないで
      nameEnglish: 'Don’t forget to subscribe',
      path: 'sounds/phrases/dont_forget_to_subscribe.wav',
    ),
    Phrases(
      nameJapanese: 'Kibun wa dō?', // 気分はどう？
      nameEnglish: 'How are you feeling?',
      path: 'sounds/phrases/how_are_you_feeling.wav',
    ),
    Phrases(
      nameJapanese: 'Anime ga daisuki', // アニメが大好き
      nameEnglish: 'I love anime',
      path: 'sounds/phrases/i_love_anime.wav',
    ),
    Phrases(
      nameJapanese: 'Puroguramingu ga daisuki', // プログラミングが大好き
      nameEnglish: 'I love programming',
      path: 'sounds/phrases/i_love_programming.wav',
    ),
    Phrases(
      nameJapanese: 'Puroguramingu wa kantan', // プログラミングは簡単
      nameEnglish: 'Programming is easy',
      path: 'sounds/phrases/programming_is_easy.wav',
    ),
    Phrases(
      nameJapanese: 'Onamae wa?', // お名前は？
      nameEnglish: 'What is your name?',
      path: 'sounds/phrases/what_is_your_name.wav',
    ),
    Phrases(
      nameJapanese: 'Doko e iku no?', // どこへ行くの？
      nameEnglish: 'Where are you going?',
      path: 'sounds/phrases/where_are_you_going.wav',
    ),
    Phrases(
      nameJapanese: 'Hai, ikimasu', // はい、行きます
      nameEnglish: 'Yes, I’m coming',
      path: 'sounds/phrases/yes_im_coming.wav',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Phrases',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xff46322B),
      ),
      body: ListView.builder(
        itemCount: phrases.length,
        itemBuilder: (context, index) {
          return itemphrases(phrases: phrases[index]);
        },
      ),
    );
  }
}
