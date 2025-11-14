import 'dart:convert';
import 'package:day05_storeap/models/product_model.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class ProductService {
  final Dio dio;
  ProductService(this.dio);

  Future<List<ProductModel>> getAllProduct() async {
    try {
      final response = await dio.get(
        'https://fakestoreapi.com/products',
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> products = response.data;
        return products
            .map((product) => ProductModel.fromJson(product))
            .toList();
      } else {
        throw Exception('Failed to load products: Invalid response');
      }
    } catch (e) {
      print('API Error: $e');
      // Fallback to mock data if API fails
      return _getMockProducts();
    }
  }

  Future<dynamic> addProduct({
    required String url,
    required dynamic body,
    String? token,
  }) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers.addAll({
        'Authorization': 'Bearer $token',
      });
    }

    http.Response response = await http.post(
      Uri.parse(url),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception('Failed to add product: ${response.statusCode}');
    }
  }

  List<ProductModel> _getMockProducts() {
    return [
      ProductModel(
        id: 1,
        title: "Fjallraven - Foldsack No. 1 Backpack",
        price: 109,
        description: "Your perfect pack for everyday use and walks in forest.",
        category: "men's clothing",
        image: "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_.jpg",
        rating: Rating(rate: 3.9, count: 120),
      ),
      ProductModel(
        id: 2,
        title: "Mens Casual Premium Slim Fit T-Shirts",
        price: 22,
        description: "Slim-fitting style, contrast raglan long sleeve.",
        category: "men's clothing",
        image: "https://fakestoreapi.com/img/71-3HjGNDUL._AC_SY879_.jpg",
        rating: Rating(rate: 4.1, count: 259),
      ),
      ProductModel(
        id: 3,
        title: "Mens Cotton Jacket",
        price: 55,
        description: "Great outerwear jackets for Spring/Autumn/Winter.",
        category: "men's clothing",
        image: "https://fakestoreapi.com/img/71li-ujtlUL._AC_UX679_.jpg",
        rating: Rating(rate: 4.7, count: 500),
      ),
      ProductModel(
        id: 4,
        title: "Mens Casual Slim Fit",
        price: 15,
        description: "The color could be slightly different from picture.",
        category: "men's clothing",
        image: "https://fakestoreapi.com/img/71YXzeOuslL._AC_UY879_.jpg",
        rating: Rating(rate: 2.1, count: 430),
      ),
      ProductModel(
        id: 5,
        title: "John Hardy Women's Legends Naga Gold & Silver Dragon Bracelet",
        price: 695,
        description:
            "From our Legends Collection, Naga was inspired by mythical dragon.",
        category: "jewelery",
        image: "https://fakestoreapi.com/img/71pWzhdJNwL._AC_UL640_.jpg",
        rating: Rating(rate: 4.6, count: 400),
      ),
    ];
  }
}
