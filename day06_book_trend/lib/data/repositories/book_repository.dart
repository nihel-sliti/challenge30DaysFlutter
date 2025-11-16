import 'package:day06_book_trend/data/models/book_model.dart';
import 'package:day06_book_trend/data/services/book_service.dart';

class BookRepository {
  final BookService _service = BookService();

  Future<List<BookModel>> fetch2025Books() async {
    try {
      final data = await _service.getBestBooks2025();
      return data.map((e) => BookModel.fromJson(e)).toList();
    } catch (e) {
      // Re-throw the exception to let the BLoC handle it
      // The BookService already provides user-friendly error messages
      rethrow;
    }
  }
}
