import 'dart:convert';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String? size;
  final String? sugarLevel;
  final String? iceLevel;
  final String? imageUrl;
  final String? category;
  final Map<String, dynamic>? customizations;
  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    this.size,
    this.sugarLevel,
    this.iceLevel,
    this.imageUrl,
    this.category,
    this.customizations,
  });
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? customizationsMap;
    if (json['customizations'] != null) {
      if (json['customizations'] is Map) {
        customizationsMap = Map<String, dynamic>.from(json['customizations']);
      } else if (json['customizations'] is String &&
          json['customizations'].isNotEmpty) {
        try {
          customizationsMap = Map<String, dynamic>.from(
            jsonDecode(json['customizations']),
          );
        } catch (e) {
          customizationsMap = null;
        }
      }
    }
    String? sizeFromCustom;
    String? sugarFromCustom;
    String? iceFromCustom;
    if (customizationsMap != null) {
      sizeFromCustom = customizationsMap['size']?.toString();
      sugarFromCustom = customizationsMap['sugar']?.toString();
      iceFromCustom = customizationsMap['ice']?.toString();
    }
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      quantity:
          (json['quantity'] is int)
              ? json['quantity'] as int
              : int.tryParse(json['quantity'].toString()) ?? 1,
      price:
          (json['price'] is int)
              ? (json['price'] as int).toDouble()
              : (json['price'] as num?)?.toDouble() ?? 0.0,
      size: json['size']?.toString() ?? sizeFromCustom,
      sugarLevel: json['sugarLevel']?.toString() ?? sugarFromCustom,
      iceLevel: json['iceLevel']?.toString() ?? iceFromCustom,
      imageUrl: json['imageUrl']?.toString(),
      category: json['category']?.toString(),
      customizations: customizationsMap,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'size': size,
      'sugarLevel': sugarLevel,
      'iceLevel': iceLevel,
      'imageUrl': imageUrl,
      'category': category,
      'customizations': customizations,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double total;
  final String status;
  final String? deliveryAddress;
  final String paymentMethod;
  final DateTime createdAt;
  final int pointsEarned;
  final String? name;
  final String? avatar;
  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    this.deliveryAddress,
    required this.paymentMethod,
    required this.createdAt,
    this.pointsEarned = 0,
    this.name,
    this.avatar,
  });
  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic dateValue) {
      try {
        if (dateValue == null) return DateTime.now();
        if (dateValue is DateTime) return dateValue;
        if (dateValue is String) return DateTime.parse(dateValue);
        return DateTime.now();
      } catch (e) {
        return DateTime.now();
      }
    }

    List<OrderItem> items = [];
    if (json['items'] is List) {
      items =
          (json['items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList();
    }
    return Order(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      items: items,
      total:
          (json['total'] is int)
              ? (json['total'] as int).toDouble()
              : (json['total'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      deliveryAddress: json['deliveryAddress']?.toString(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'cash',
      createdAt: parseDate(json['createdAt']),
      pointsEarned:
          (json['pointsEarned'] is int)
              ? json['pointsEarned'] as int
              : int.tryParse(json['pointsEarned']?.toString() ?? '') ?? 0,
      name: json['name']?.toString(),
      avatar: json['avatar']?.toString(),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'pointsEarned': pointsEarned,
      'name': name,
      'avatar': avatar,
    };
  }
}
