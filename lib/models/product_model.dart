class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final bool isAvailable;
  final List<String> ingredients;
  final int calories;
  final double rating;
  final String? section;
  final bool? popular;
  final bool? promotion;
  final double? discount;
  final Map<String, dynamic>? customizations;
  final double? finalPrice;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.isAvailable = true,
    required this.ingredients,
    required this.calories,
    required this.rating,
    this.section,
    this.popular,
    this.promotion,
    this.discount,
    this.customizations,
    this.finalPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price:
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : (json['price'] as double?) ?? 0.0,
      category: json['category'] ?? 'Coffee',
      imageUrl: json['imageUrl'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      ingredients:
          (json['ingredients'] is List)
              ? List<String>.from(json['ingredients'] ?? [])
              : [],
      calories:
          (json['calories'] is int)
              ? json['calories'] as int
              : int.tryParse(json['calories'].toString()) ?? 0,
      rating:
          (json['rating'] is int)
              ? (json['rating'] as int).toDouble()
              : (json['rating'] as double?) ?? 0.0,
      section: json['section'],
      popular: json['popular'],
      promotion: json['promotion'],
      discount:
          json['discount'] != null
              ? (json['discount'] is int)
                  ? (json['discount'] as int).toDouble()
                  : (json['discount'] as double?) ?? 0.0
              : null, // Parse discount
      customizations:
          json['customizations'] != null
              ? Map<String, dynamic>.from(json['customizations'])
              : null,
      finalPrice:
          json['finalPrice'] != null
              ? (json['finalPrice'] is int
                  ? (json['finalPrice'] as int).toDouble()
                  : json['finalPrice'] as double?)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'ingredients': ingredients,
      'calories': calories,
      'rating': rating,
      'section': section,
      'popular': popular,
      'promotion': promotion,
      'discount': discount,
      'customizations': customizations,
      'finalPrice': finalPrice,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    bool? isAvailable,
    List<String>? ingredients,
    int? calories,
    double? rating,
    String? section,
    bool? popular,
    bool? promotion,
    double? discount,
    Map<String, dynamic>? customizations,
    double? finalPrice,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      ingredients: ingredients ?? this.ingredients,
      calories: calories ?? this.calories,
      rating: rating ?? this.rating,
      section: section ?? this.section,
      popular: popular ?? this.popular,
      promotion: promotion ?? this.promotion,
      discount: discount ?? this.discount,
      customizations: customizations ?? this.customizations,
      finalPrice: finalPrice ?? this.finalPrice,
    );
  }
}
