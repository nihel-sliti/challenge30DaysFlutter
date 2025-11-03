import 'package:flutter/material.dart';

void main() {
  runApp(const BusinessCard());
}

class BusinessCard extends StatelessWidget {
  const BusinessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF2B475E),
        body: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: CircleAvatar(
              radius: 210,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 200,
                backgroundImage: AssetImage('images/ninini.jpg'),
              ),
            ),
          ),
          Text(
            'Nihel Sliti',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            'Mobile and Iot developer',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.phone,
                size: 32,
                color: Color(0xFF2B475E),
              ),
              title: Text(
                '(+216) 266666666',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.email,
                size: 32,
                color: Color(0xFF2B475E),
              ),
              title: Text(
                'slitinihel023@gmail.com',
                style: TextStyle(fontSize: 24),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Image(
                  image: AssetImage('images/github_PNG40.png'),
                  height: 50,
                  width: 50,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Image(
                  image: AssetImage('images/linkedin.png'),
                  height: 50,
                  width: 50,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Image(
                  image: AssetImage('images/logo-instagram.png'),
                  height: 50,
                  width: 50,
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
