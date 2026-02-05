import 'package:flutter/foundation.dart';
import 'package:ronoch_coffee/models/cart_model.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  int _userPoints = 0;
  bool _isSyncing = false;
  String? _currentUserId;

  List<CartItem> get items => _items;
  int get userPoints => _userPoints;
  bool get isSyncing => _isSyncing;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  Future<void> initCart(String userId) async {
    _currentUserId = userId;
    await _loadCartFromApi();
  }

  Future<void> _loadCartFromApi() async {
    if (_currentUserId == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final cart = await MockApiService.getUserCart(_currentUserId!);
      if (cart != null) {
        _items = cart.items;
        notifyListeners();
      }

      final user = await MockApiService.getUserById(_currentUserId!);
      if (user != null) {
        _userPoints = user.point;
      }
    } catch (e) {
      debugPrint("Error loading cart from API: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _saveCartToApi() async {
    if (_currentUserId == null) return;

    try {
      _isSyncing = true;
      notifyListeners();

      final total = _items.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
      final cartData = {
        'userId': _currentUserId!,
        'items': _items.map((item) => item.toJson()).toList(),
        'total': total,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      final existingCart = await MockApiService.getUserCart(_currentUserId!);
      if (existingCart != null) {
        await MockApiService.updateCart(
          existingCart.id,
          Cart.fromJson(cartData),
        );
      } else {
        await MockApiService.createCart(Cart.fromJson(cartData));
      }
    } catch (e) {
      debugPrint("Error saving cart to API: $e");
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(
    String productId,
    String name,
    double price,
    String imageUrl, {
    int quantity = 1,
    String size = 'M',
    String sugarLevel = '0%',
    String iceLevel = '0%',
  }) async {
    final existingIndex = _items.indexWhere(
      (item) =>
          item.productId == productId &&
          item.size == size &&
          item.sugarLevel == sugarLevel &&
          item.iceLevel == iceLevel,
    );

    if (existingIndex >= 0) {
      final existingItem = _items[existingIndex];
      _items[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      _items.add(
        CartItem(
          productId: productId,
          name: name,
          quantity: quantity,
          price: price,
          imageUrl: imageUrl,
          size: size,
          sugarLevel: sugarLevel,
          iceLevel: iceLevel,
        ),
      );
    }
    await _saveCartToApi();
    notifyListeners();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final item = _items[index];
      _items[index] = item.copyWith(quantity: newQuantity);

      await _saveCartToApi();
      notifyListeners();
    }
  }

  Future<void> removeFromCart(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    await _saveCartToApi();
    notifyListeners();
  }

  Future<void> clearCart() async {
    _items.clear();
    if (_currentUserId != null) {
      try {
        final cart = await MockApiService.getUserCart(_currentUserId!);
        if (cart != null) {
          await MockApiService.deleteCart(cart.id);
        }
      } catch (e) {
        debugPrint("Error clearing cart from API: $e");
      }
    }
    notifyListeners();
  }

  Future<void> completePurchase() async {
    if (_currentUserId == null) return;
    const int pointsAwarded = 10;
    try {
      await MockApiService.addUserPoint(_currentUserId!, pointsAwarded);
      _userPoints += pointsAwarded;
      await clearCart();
    } catch (e) {
      debugPrint("Purchase completion failed: $e");
    }
  }

  bool get hasItems => _items.isNotEmpty;
}
