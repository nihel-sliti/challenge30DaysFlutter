import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(CounterApp());
}

class CounterApp extends StatefulWidget {
  CounterApp({super.key});

  @override
  State<CounterApp> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<CounterApp> {
  int PointA = 0;
  int PointB = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange,
          title: const Text('Basketball Points Counter'),
        ),
        body: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text('Team A', style: TextStyle(fontSize: 48)),
                    SizedBox(
                      width: 10,
                    ),
                    Text('$PointA', style: TextStyle(fontSize: 52)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          PointA++;
                        });
                      },
                      child: Text('add 1 point'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          PointA += 2;
                        });
                      },
                      child: Text('add 2 point'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          PointA += 3;
                        });
                      },
                      child: Text('add 3 point'),
                    ),
                  ],
                ),
                SizedBox(
                  height: 200,
                  child: VerticalDivider(
                    thickness: 2,
                    color: Colors.grey,
                  ),
                ),
                Column(
                  children: [
                    const Text('Team B', style: TextStyle(fontSize: 48)),
                    SizedBox(
                      width: 10,
                    ),
                    Text('$PointB', style: TextStyle(fontSize: 52)),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          PointB++;
                        });
                      },
                      child: Text('add 1 point'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          PointB += 2;
                        });
                      },
                      child: Text('add 2 point'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          PointB += 3;
                        });
                      },
                      child: Text('add 3 point'),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(
              height: 100,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {
                  setState(() {
                    PointA = 0;
                    PointB = 0;
                  });
                },
                child: Text(
                  'Reset',
                  style: TextStyle(color: Colors.black),
                ))
          ],
        ),
      ),
    );
  }
}
