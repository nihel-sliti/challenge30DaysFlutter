class BookModel {
  final String title;
  final String? author;
  final ImageLinks? imageLinks;

  BookModel({
    required this.title,
    this.author,
    this.imageLinks,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final volume = json["volumeInfo"];
    return BookModel(
      title: volume?["title"] ?? "No Title",
      author: (volume?["authors"] != null && volume?["authors"].isNotEmpty)
          ? volume!["authors"][0]
          : null,
      imageLinks: volume?["imageLinks"] != null
          ? ImageLinks.fromJson(volume["imageLinks"])
          : null,
    );
  }
}

class ImageLinks {
  final String? smallThumbnail;
  final String? thumbnail;
  ImageLinks({required this.smallThumbnail, required this.thumbnail});
  factory ImageLinks.fromJson(dynamic jsdata) {
    return ImageLinks(
      smallThumbnail: jsdata?['smallThumbnail'],
      thumbnail: jsdata?['thumbnail'],
    );
  }
}
