import 'package:day04_newsapp/model/news_model.dart';
import 'package:flutter/material.dart';

class Item extends StatelessWidget {
  Item({super.key, required this.newsModel});
  NewsModel newsModel;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          width: double.infinity,
          clipBehavior: Clip.antiAlias, // pour respecter le borderRadius
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(
                  newsModel.image ??
                      'https://via.placeholder.com/600x400?text=No+Image',
                ),
                fit: BoxFit.cover,
              )),
        ),
        Text(
          newsModel.title,
          maxLines: 2,
          textAlign: TextAlign.start,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(
          height: 2,
        ),
        Text(
          newsModel.subTitle!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 8,
          ),
        ),
      ],
    );
  }
}
