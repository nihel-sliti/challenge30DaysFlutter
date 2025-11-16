import 'package:dio/dio.dart';

class BookService {
  final Dio _dio;

  BookService() : _dio = Dio() {
    // Configure default settings
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
  }

  Future<List<dynamic>> getBestBooks2025() async {
    try {
      final response = await _dio.get(
        'https://www.googleapis.com/books/v1/volumes?q=best+books+2025',
      );

      if (response.statusCode == 200) {
        return response.data["items"] ?? [];
      } else {
        throw Exception(
            'Failed to load books: Status code ${response.statusCode}');
      }
    } on DioException catch (e) {
      // Handle Dio specific errors
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
          throw Exception(
              'Connection timeout. Please check your internet connection.');
        case DioExceptionType.sendTimeout:
          throw Exception('Request timeout. Please try again.');
        case DioExceptionType.receiveTimeout:
          throw Exception('Response timeout. Please try again.');
        case DioExceptionType.badResponse:
          final statusCode = e.response?.statusCode;
          if (statusCode != null) {
            switch (statusCode) {
              case 400:
                throw Exception('Bad request. Please check your input.');
              case 401:
                throw Exception('Unauthorized. Please check your credentials.');
              case 403:
                throw Exception(
                    'Forbidden. You don\'t have permission to access this resource.');
              case 404:
                throw Exception('Books not found.');
              case 500:
                throw Exception(
                    'Internal server error. Please try again later.');
              case 502:
                throw Exception('Bad gateway. Please try again later.');
              case 503:
                throw Exception('Service unavailable. Please try again later.');
              default:
                throw Exception(
                    'Server error: $statusCode. Please try again later.');
            }
          }
          throw Exception('Server error occurred. Please try again later.');
        case DioExceptionType.cancel:
          throw Exception('Request was cancelled.');
        case DioExceptionType.connectionError:
          throw Exception(
              'No internet connection. Please check your network settings.');
        case DioExceptionType.unknown:
          throw Exception('An unexpected error occurred: ${e.message}');
        default:
          throw Exception(
              'An error occurred while fetching books: ${e.message}');
      }
    } catch (e) {
      // Handle any other unexpected errors
      throw Exception('An unexpected error occurred: ${e.toString()}');
    }
  }
}
