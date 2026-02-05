import 'package:flutter/foundation.dart';

@immutable
class CartItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String imageUrl;
  final String size;
  final String sugarLevel;
  final String iceLevel;

  const CartItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.imageUrl,
    this.size = 'M',
    this.sugarLevel = '0%',
    this.iceLevel = '0%',
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId'].toString(),
      name: json['name'] ?? '',
      quantity:
          json['quantity'] is int
              ? json['quantity'] as int
              : int.tryParse(json['quantity'].toString()) ?? 1,
      price:
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : (json['price'] as double?) ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      size: json['size'] ?? 'M',
      sugarLevel: json['sugarLevel'] ?? '0%',
      iceLevel: json['iceLevel'] ?? '0%',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'imageUrl': imageUrl,
      'size': size,
      'sugarLevel': sugarLevel,
      'iceLevel': iceLevel,
    };
  }

  double get subtotal => price * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? price,
    String? imageUrl,
    String? size,
    String? sugarLevel,
    String? iceLevel,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      size: size ?? this.size,
      sugarLevel: sugarLevel ?? this.sugarLevel,
      iceLevel: iceLevel ?? this.iceLevel,
    );
  }
}

@immutable
class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double total;
  final DateTime updatedAt;

  const Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.updatedAt,
  });

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      items:
          (json['items'] is List)
              ? (json['items'] as List)
                  .map((item) => CartItem.fromJson(item))
                  .toList()
              : [],
      total:
          (json['total'] is int)
              ? (json['total'] as int).toDouble()
              : (json['total'] as double?) ?? 0.0,
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Cart copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? total,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      total: total ?? this.total,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
