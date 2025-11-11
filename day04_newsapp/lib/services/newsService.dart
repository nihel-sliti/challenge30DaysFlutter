import 'package:day04_newsapp/model/news_model.dart';
import 'package:dio/dio.dart';

class Newsservice {
  final Dio dio;
  Newsservice(this.dio);
  Future<List<NewsModel>> getNews() async {
    Response response = await dio.get(
        'https://newsapi.org/v2/top-headlines?sources=bbc-news&apiKey=09eaf9a225c8447d8ec9cc4c99555ce1');
    Map<String, dynamic> jsonData = response.data;
    List<dynamic> articles = jsonData['articles']; //list of map
    List<NewsModel> newsList = [];
    //list of map to list of object
    for (var article in articles) {
      NewsModel newsModel = NewsModel(
        image: article['urlToImage'],
        title: article['title'],
        subTitle: article['description'],
      );
      newsList.add(newsModel);
    }
    print(newsList);
    return newsList;
  }
}
