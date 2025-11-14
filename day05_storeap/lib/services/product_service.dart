import 'package:day05_storeap/models/product_model.dart';
import 'package:dio/dio.dart';

class ProductService {
  final Dio dio;
  ProductService(this.dio);
  Future<List<ProductModel>> getAllProduct() async {
    Response response = await dio.get('https://fakestoreapi.com/products');
    List<dynamic> product = response.data;
    List<ProductModel> productList = [];
    for (int i = 0; i < product.length; i++) {
      productList.add(ProductModel.fromJson(product[i]));
    }
    return productList;
  }
}
