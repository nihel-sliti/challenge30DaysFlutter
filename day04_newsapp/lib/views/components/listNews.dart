import 'package:day04_newsapp/model/news_model.dart';
import 'package:day04_newsapp/services/newsService.dart';
import 'package:day04_newsapp/views/components/item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Listnews extends StatefulWidget {
  const Listnews({super.key});

  @override
  State<Listnews> createState() => _ListnewsState();
}

class _ListnewsState extends State<Listnews> {
  List<NewsModel> articles = [];
  var future;
  @override
  void initState() {
    super.initState();
    future = Newsservice(Dio()).getNews();
  }

  @override
  Widget build(BuildContext context) {
    //  Newsservice(Dio()).getNews();//function fi west build bech trazen application w fi kol mara bch ya3mlha build donc fama methode esmha init state
    return FutureBuilder(
        future: future,
        builder: (context, Snapshot) {
          if (Snapshot.hasData) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(childCount: articles.length,
                  (context, index) {
                return Item(newsModel: articles[index]);
              }),
            );
          } else if (Snapshot.hasError) {
            return const SliverToBoxAdapter(
              child: Text('oops there was an error, try later'),
            );
          } else {
            return const SliverToBoxAdapter(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
        }
        //lazy chargement
        );
  }
}
