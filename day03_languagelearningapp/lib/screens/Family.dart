import 'package:day03_languagelearningapp/components/itemFamily.dart';
import 'package:day03_languagelearningapp/models/family.dart';
import 'package:flutter/material.dart';

class Family extends StatelessWidget {
  Family({super.key});
  final List<FamilyNumbers> familyNumbers = const [
    FamilyNumbers(
      image: 'assets/images/family_members/family_father.png',
      nameJapanese: 'chichi',
      nameEnglish: 'father',
      path: 'sounds/family_members/father.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_mother.png',
      nameJapanese: 'haha',
      nameEnglish: 'mother',
      path: 'sounds/family_members/mother.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_son.png',
      nameJapanese: 'musuko',
      nameEnglish: 'son',
      path: 'sounds/family_members/son.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_daughter.png',
      nameJapanese: 'musume',
      nameEnglish: 'daughter',
      path: 'sounds/family_members/daughter.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_older_brother.png',
      nameJapanese: 'ani',
      nameEnglish: 'older brother',
      path: 'sounds/family_members/older_bother.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_younger_brother.png',
      nameJapanese: 'otōto',
      nameEnglish: 'younger brother',
      path: 'sounds/family_members/younger_brohter.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_older_sister.png',
      nameJapanese: 'ane',
      nameEnglish: 'older sister',
      path: 'sounds/family_members/older_sister.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_younger_sister.png',
      nameJapanese: 'imōto',
      nameEnglish: 'younger sister',
      path: 'sounds/family_members/younger_sister.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_grandfather.png',
      nameJapanese: 'ojiisan',
      nameEnglish: 'grand father',
      path: 'sounds/family_members/grand_father.wav',
    ),
    FamilyNumbers(
      image: 'assets/images/family_members/family_grandmother.png',
      nameJapanese: 'obaasan',
      nameEnglish: 'grand mother',
      path: 'sounds/family_members/grand_mother.wav',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Family Members',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xff46322B),
      ),
      body: ListView.builder(
        itemCount: familyNumbers.length,
        itemBuilder: (context, index) {
          return itemFamily(familyNumbers: familyNumbers[index]);
        },
      ),
    );
  }
}
