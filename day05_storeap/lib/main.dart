import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:day05_storeap/views/home_page_bloc.dart';
import 'package:day05_storeap/bloc/product_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ProductBloc.create()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePageBloc(),
      ),
    );
  }
}
