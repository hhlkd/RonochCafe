// lib/provider/product_provider.dart
import 'package:flutter/material.dart';
import '../services/mockapi_service.dart';
import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String _error = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      _products = await MockApiService.getProducts();
    } catch (e) {
      _error = 'Failed to load products: $e';
      print('Error loading products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get product by ID
  Product? getProductById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  List<Product> getProductsByCategory(String category) {
    if (category == 'All') return _products;
    return _products.where((p) => p.category == category).toList();
  }

  // Get popular products
  List<Product> get popularProducts {
    return _products.where((p) => p.popular == true).toList();
  }

  // Get promotion products
  List<Product> get promotionProducts {
    return _products
        .where((p) => p.promotion == true || p.discount != null)
        .toList();
  }
}
