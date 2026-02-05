class AppImage {
  final String id;
  final String name;
  final String imageUrl;
  final String type;
  final String category;

  AppImage({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.category,
  });
  factory AppImage.fromJson(Map<String, dynamic> json) {
    return AppImage(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? '',
      category: json['category'] ?? '',
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'type': type,
      'category': category,
    };
  }
}
