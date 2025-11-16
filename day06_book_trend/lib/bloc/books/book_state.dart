import 'package:day06_book_trend/data/models/book_model.dart';

abstract class BookState {}

class BookInitial extends BookState {}

class BookLoading extends BookState {}

class BookLoaded extends BookState {
  final List<BookModel> books;

  BookLoaded(this.books);
}

class BookError extends BookState {
  final String message;

  BookError(this.message);
}
