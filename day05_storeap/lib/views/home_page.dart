import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Icon(
            FontAwesomeIcons.cartPlus,
            color: Colors.black,
          ),
        ],
        title: Text('New Trend'),
        centerTitle: true,
      ),
    );
  }
}
