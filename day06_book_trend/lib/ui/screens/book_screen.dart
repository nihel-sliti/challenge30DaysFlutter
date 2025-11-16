import 'package:day06_book_trend/bloc/books/book_bloc.dart';
import 'package:day06_book_trend/bloc/books/book_event.dart';
import 'package:day06_book_trend/bloc/books/book_state.dart';
import 'package:day06_book_trend/data/models/book_model.dart';
import 'package:day06_book_trend/data/repositories/book_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BooksScreen extends StatelessWidget {
  final BookModel? bookModel;
  BooksScreen({super.key, this.bookModel});
  // Helper method to build book images with proper error handling
  Widget _buildBookImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Icon(
              Icons.book,
              size: 32,
              color: Colors.grey[600],
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookBloc(BookRepository())..add(LoadBooks2025()),
      child: Scaffold(
        appBar: AppBar(title: Text("Best Books 2025")),
        body: BlocBuilder<BookBloc, BookState>(
          builder: (context, state) {
            if (state is BookLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (state is BookLoaded) {
              return ListView.builder(
                itemCount: state.books.length,
                itemBuilder: (_, i) {
                  final b = state.books[i];
                  return ListTile(
                    leading: b.imageLinks?.smallThumbnail != null
                        ? _buildBookImage(b.imageLinks!.smallThumbnail!)
                        : Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Icon(
                              Icons.book,
                              size: 32,
                              color: Colors.grey[600],
                            ),
                          ),
                    title: Text(b.title),
                    subtitle: Text(b.author ?? "Unknown Author"),
                  );
                },
              );
            }

            if (state is BookError) {
              return Center(child: Text("Error: ${state.message}"));
            }

            return SizedBox();
          },
        ),
      ),
    );
  }
}
