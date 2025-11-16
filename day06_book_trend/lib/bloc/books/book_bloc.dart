import 'package:day06_book_trend/bloc/books/book_event.dart';
import 'package:day06_book_trend/bloc/books/book_state.dart';
import 'package:day06_book_trend/data/repositories/book_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BookBloc extends Bloc<BookEvent, BookState> {
  final BookRepository repo;

  BookBloc(this.repo) : super(BookInitial()) {
    on<LoadBooks2025>((event, emit) async {
      emit(BookLoading());
      try {
        final books = await repo.fetch2025Books();
        emit(BookLoaded(books));
      } catch (e) {
        emit(BookError(e.toString()));
      }
    });
  }
}
