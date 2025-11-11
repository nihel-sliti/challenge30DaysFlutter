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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getGenralNews();
  }

  Future<void> getGenralNews() async {
    articles = await Newsservice(Dio()).getNews();
  }

  @override
  Widget build(BuildContext context) {
    //  Newsservice(Dio()).getNews();//function fi west build bech trazen application w fi kol mara bch ya3mlha build donc fama methode esmha init state
    return SliverList(
      delegate: SliverChildBuilderDelegate(childCount: articles.length,
          (context, index) {
        return Item(newsModel: articles[index]);
      }),
    );
    //lazy chargement
  }
}
