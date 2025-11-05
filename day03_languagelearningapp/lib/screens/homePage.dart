import 'package:day03_languagelearningapp/components/Category.dart';
import 'package:day03_languagelearningapp/screens/Family.dart';
import 'package:day03_languagelearningapp/screens/Phrases.dart';
import 'package:day03_languagelearningapp/screens/numbers.dart';
import 'package:day03_languagelearningapp/screens/colors.dart';
import 'package:flutter/material.dart';

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Toku',
              style: TextStyle(
                color: Colors.white,
              )),
          backgroundColor: Color(0xff46322B),
        ),
        body: Column(
          children: [
            Category(
                text: 'Numbers',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return NumbersPage();
                  }));
                }),
            Category(
                text: 'Colors',
                color: Colors.green,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return colors();
                  }));
                }),
            Category(
                text: 'Family',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return Family();
                  }));
                }),
            Category(
                text: 'Phrases',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (BuildContext context) {
                    return Phrases();
                  }));
                }),
          ],
        ));
  }
}
