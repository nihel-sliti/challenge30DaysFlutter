import 'package:flutter/material.dart';

class Category extends StatelessWidget {
  Category({required this.imagePath, required this.nameCategory});
  String imagePath;
  String nameCategory;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        height: 95,
        width: 150,
        decoration: BoxDecoration(
          image:
              DecorationImage(image: AssetImage(imagePath), fit: BoxFit.fill),
          color: Colors.amberAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
            child: Text(
          nameCategory,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        )),
      ),
    );
  }
}
