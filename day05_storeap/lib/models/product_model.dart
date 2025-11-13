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
  factory ProductModel.FormJson(jsondata) {
    return ProductModel(
      id: jsondata['id'],
      title: jsondata['titre'],
      // price: jsondata['price'],
      description: jsondata['description'],
      category: jsondata['category'],
      image: jsondata['image'],
      // rating: Rating.FormJson(jsondata['rating'])
    );
  }
}

class Rating {
  final double rate;
  final int count;
  Rating({required this.rate, required this.count});
  factory Rating.FormJson(jsdata) {
    return Rating(
      rate: jsdata['rate'],
      count: jsdata['count'],
    );
  }
}
