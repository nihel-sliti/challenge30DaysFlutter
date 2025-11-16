class ProductModel {
  final int id;
  final String? title;
  final double price;
  final String description;
  final String category;
  final String image;
  final Rating rating; //  plus de ?

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.image,
    required this.rating,
  });

  factory ProductModel.fromJson(jsondata) {
    return ProductModel(
      id: jsondata['id'],
      title: jsondata['title'],
      price: (jsondata['price'] is num)
          ? (jsondata['price'] as num).toDouble()
          : double.tryParse(jsondata['price'].toString()) ?? 0.0,
      description: jsondata['description'] ?? 'No description available',
      category: jsondata['category'] ?? 'Unknown category',
      image: jsondata['image'] ?? '',
      rating: Rating.fromJson(jsondata['rating'] ?? {'rate': 0.0, 'count': 0}),
    );
  }
}

class Rating {
  final double rate;
  final int count; // tu peux le mettre non-nullable aussi

  Rating({required this.rate, required this.count});

  factory Rating.fromJson(jsdata) {
    return Rating(
      rate: (jsdata['rate'] is num)
          ? (jsdata['rate'] as num).toDouble()
          : double.tryParse(jsdata['rate'].toString()) ?? 0.0,
      count: (jsdata['count'] ?? 0) as int,
    );
  }
}
