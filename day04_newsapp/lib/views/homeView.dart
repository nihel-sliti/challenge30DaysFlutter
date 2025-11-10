import 'package:day04_newsapp/views/components/category.dart';
import 'package:day04_newsapp/views/components/item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class homeView extends StatelessWidget {
  homeView({super.key});
  List<Category> category = [
    Category(
        imagePath: 'assets/images/GeneralNews.jpg', nameCategory: 'General'),
    Category(
        imagePath: 'assets/images/GeneralNews.jpg', nameCategory: 'Sports'),
    Category(
        imagePath: 'assets/images/GeneralNews.jpg', nameCategory: 'Beauty'),
    Category(
        imagePath: 'assets/images/GeneralNews.jpg', nameCategory: 'Bourse'),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0, //pour le shadow
        backgroundColor: Colors.transparent,
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'News',
              style: TextStyle(color: Colors.black),
            ),
            Text(
              'Cloud',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            // bch tkhali l'ecran il kol t3ml scroll sinon bil colum bch tkhali partie parka t3ml scroll
            physics:
                BouncingScrollPhysics(), // bch may3mlch aka khat lazra9 mn louta ki youfew items t3k

            slivers: [
              //slivers  homa bithomm child
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 95,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: category.length,
                    itemBuilder: (context, index) {
                      return category[index];
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 32,
                ),
              ),
              SliverList(
                  delegate: SliverChildBuilderDelegate(childCount: 10,
                      (context, index) {
                return Item();
              })), //lazy chargement
            ],
          )),
    );
  }
}
// ki tabda tkhdm b akther men liste lzmk expanded 
// SliverToBoxAdapter(
//               child: ListView.builder(
//                shrinkWrap: true,
//              physics: const NeverScrollableScrollPhysics(),
//               itemCount: 10,
//               itemBuilder: (context, index) {
//                return Item();
//               },
//            ),
//           )
