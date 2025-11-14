class ProductModel {
  final int id;
  final String? title;
  //final int price;
  final String description;
  final String category;
  final String image;
  //final Rating rating;
  ProductModel({
    required this.id,
    required this.title,
    //  required this.price,
    required this.description,
    required this.category,
    required this.image,
    //required this.rating
  });
  factory ProductModel.fromJson(jsondata) {
    return ProductModel(
      id: jsondata['id'],
      title: jsondata['title'],
      // price: jsondata['price'],
      description: jsondata['description'] ?? 'No description available',
      category: jsondata['category'] ?? 'Unknown category',
      image: jsondata['image'] ?? '',
      // rating: Rating.fromJson(jsondata['rating'])
    );
  }
}

class Rating {
  final double rate;
  final int count;
  Rating({required this.rate, required this.count});
  factory Rating.fromJson(jsdata) {
    return Rating(
      rate: jsdata['rate'],
      count: jsdata['count'],
    );
  }
}
