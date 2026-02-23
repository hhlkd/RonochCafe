import 'package:flutter/material.dart';
import 'package:ronoch_coffee/models/cart_model.dart';
import 'package:ronoch_coffee/models/order.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _isCreatingOrder = false;
  String? _error;
  String? _userId;
  String? _userName;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get isCreatingOrder => _isCreatingOrder;
  String? get error => _error;
  String? get userId => _userId;
  String? get userName => _userName;

  int get totalOrders => _orders.length;
  int get completedOrders =>
      _orders.where((o) => o.status == 'completed').length;
  int get pendingOrders => _orders.where((o) => o.status == 'pending').length;
  double get totalSpent => _orders.fold(0.0, (sum, order) => sum + order.total);

  double get averageOrderValue =>
      totalOrders > 0 ? totalSpent / totalOrders : 0;

  Future<void> deleteOrder(String orderId) async {
    try {
      print('🗑️ Deleting order: $orderId');

      await MockApiService.deleteOrder(orderId);

      _orders.removeWhere((order) => order.id == orderId);
      notifyListeners();

      print('✅ Order deleted successfully');
    } catch (e) {
      print('❌ Failed to delete order: $e');
      throw Exception('Could not delete order. Please try again.');
    }
  }

  Future<void> initialize() async {
    try {
      print('🔄 Initializing OrderProvider...');
      final user = await UserSession.getUser();
      _userId = user['userId'];
      _userName = user['userName'];

      if (_userId == null || _userId!.isEmpty) {
        print('⚠️ No user ID found in session');
        return;
      }

      print('✅ OrderProvider initialized for user: $_userName (ID: $_userId)');
      await fetchOrders();
    } catch (e) {
      print('❌ Error initializing OrderProvider: $e');
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  void setUserId(String userId, {String? userName}) {
    print(
      '🔧 Setting user ID: $userId ${userName != null ? '($userName)' : ''}',
    );
    _userId = userId;
    if (userName != null) {
      _userName = userName;
    }
    notifyListeners();
  }

  Future<void> fetchOrders({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;

    if (_userId == null) {
      print('⚠️ Cannot fetch orders: No user ID');
      _error = 'Please login to view orders';
      notifyListeners();
      return;
    }

    print('📡 FETCHING orders for user ID: $_userId');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final apiOrders = await MockApiService.getUserOrders(_userId!);
      print('📦 Received ${apiOrders.length} orders from API');

      for (var order in apiOrders) {
        print(
          '   └─ Order #${order.id}: ${order.items.length} items, \$${order.total}, ${order.status}',
        );
        if (order.userId != _userId) {
          print(
            '     ⚠️ WARNING: Order belongs to user ${order.userId}, not current user $_userId',
          );
        }
      }

      _orders = _processOrders(apiOrders);
      print('✅ Displaying ${_orders.length} unique orders for $_userName');

      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ ERROR fetching orders: $e');
      _error = 'Failed to load orders: ${e.toString()}';

      try {
        print('🔄 Attempting fallback order fetch...');
        final allOrders = await MockApiService.getOrders();
        final userOrders =
            allOrders.where((order) => order.userId == _userId).toList();
        _orders = _processOrders(userOrders);
        print('✅ Fallback successful: Found ${_orders.length} orders');
      } catch (fallbackError) {
        print('❌ Fallback also failed: $fallbackError');
        _orders = [];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Order> _processOrders(List<Order> orders) {
    if (orders.isEmpty) return [];

    final uniqueOrders = <Order>[];
    final seenOrderIds = <String>{};

    for (var order in orders) {
      if (order.userId != _userId) {
        continue;
      }

      if (seenOrderIds.contains(order.id)) {
        continue;
      }

      if (order.id.isEmpty || order.items.isEmpty) {
        continue;
      }

      uniqueOrders.add(order);
      seenOrderIds.add(order.id);
    }

    return uniqueOrders;
  }

  Future<Order> createOrderFromCart({
    required Cart cart,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    if (_userId == null) {
      await _refreshUserSession();
      if (_userId == null) {
        throw Exception('Please login to place an order');
      }
    }

    if (cart.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    print('🛒 Creating order from cart for user $_userName ($_userId)');
    print('   📦 Items: ${cart.items.length}, Total: \$${cart.total}');

    _isCreatingOrder = true;
    _error = null;
    notifyListeners();

    try {
      final user = await MockApiService.getUserById(_userId!);
      if (user == null) {
        throw Exception('User not found in database');
      }

      print('👤 Order for: ${user.username} (${user.email})');
      final totalQuantity = cart.items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
      final pointsEarned = totalQuantity * 2;

      print(
        '🎯 Points to earn: $pointsEarned (${totalQuantity} drinks × 5 points)',
      );
      final orderItems =
          cart.items.map((cartItem) {
            return OrderItem(
              productId: cartItem.productId,
              name: cartItem.name,
              quantity: cartItem.quantity,
              price: cartItem.price,
              size: cartItem.size,
              sugarLevel: cartItem.sugarLevel,
              iceLevel: cartItem.iceLevel,
              imageUrl: cartItem.imageUrl,
              customizations: {
                'size': cartItem.size,
                'sugarLevel': cartItem.sugarLevel,
                'iceLevel': cartItem.iceLevel,
              },
            );
          }).toList();

      print('📝 Converted ${cart.items.length} cart items to order items');
      final order = Order(
        id: '',
        userId: _userId!,
        items: orderItems,
        total: cart.total,
        status: 'completed',
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        pointsEarned: pointsEarned,
        name: user.username,
        avatar: user.profileImage,
      );

      print('💾 Saving order to MockAPI...');

      final createdOrder = await MockApiService.createOrder(order);

      print('✅ Order saved with ID: ${createdOrder.id}');
      print(
        '   📊 Status: ${createdOrder.status}, Points: ${createdOrder.pointsEarned}',
      );
      print('🔼 Updating user points...');
      await MockApiService.addUserPoint(_userId!, pointsEarned);
      print('✅ User points updated: +$pointsEarned points');

      await Future.delayed(const Duration(milliseconds: 800));
      await fetchOrders(forceRefresh: true);
      _error = null;

      print('🎉 Order creation complete!');
      return createdOrder;
    } catch (e) {
      print('❌ ERROR creating order: $e');
      _error = 'Failed to create order: ${e.toString()}';
      notifyListeners();
      throw Exception(_error);
    } finally {
      _isCreatingOrder = false;
      notifyListeners();
    }
  }

  Future<Order> createOrder({
    required List<OrderItem> items,
    required double total,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    if (_userId == null) {
      await _refreshUserSession();
      if (_userId == null) {
        throw Exception('Please login to place an order');
      }
    }

    if (items.isEmpty) {
      throw Exception('No items in order');
    }

    _isCreatingOrder = true;
    _error = null;
    notifyListeners();

    try {
      final user = await MockApiService.getUserById(_userId!);
      if (user == null) {
        throw Exception('User not found');
      }
      final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
      final pointsEarned = totalQuantity * 2;

      final order = Order(
        id: '',
        userId: _userId!,
        items: items,
        total: total,
        status: 'completed',
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        pointsEarned: pointsEarned,
        name: user.username,
        avatar: user.profileImage,
      );

      final createdOrder = await MockApiService.createOrder(order);

      await MockApiService.addUserPoint(_userId!, pointsEarned);
      await Future.delayed(const Duration(milliseconds: 500));
      await fetchOrders(forceRefresh: true);

      return createdOrder;
    } catch (e) {
      _error = 'Failed to create order: $e';
      notifyListeners();
      throw Exception(_error);
    } finally {
      _isCreatingOrder = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      print('📝 Updating order $orderId status to: $status');

      final updatedOrder = await MockApiService.updateOrderStatus(
        orderId,
        status,
      );
      final index = _orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        notifyListeners();
        print('✅ Order status updated locally');
      }
    } catch (e) {
      print('❌ Failed to update order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  List<Order> getOrdersByStatus(String status) {
    return _orders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  List<Order> getRecentOrders({int limit = 5}) {
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _orders.take(limit).toList();
  }

  Future<Map<String, dynamic>> getOrderStats() async {
    if (_userId == null) {
      return {
        'totalOrders': 0,
        'completedOrders': 0,
        'pendingOrders': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
        'pointsEarned': 0,
      };
    }

    try {
      return await MockApiService.getUserOrderStats(_userId!);
    } catch (e) {
      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'pendingOrders': pendingOrders,
        'totalSpent': totalSpent,
        'averageOrderValue': averageOrderValue,
        'pointsEarned': _orders.fold(
          0,
          (sum, order) => sum + order.pointsEarned,
        ),
      };
    }
  }

  Future<bool> hasPendingOrders() async {
    if (_userId == null) return false;

    try {
      return await MockApiService.hasPendingOrders(_userId!);
    } catch (e) {
      return pendingOrders > 0;
    }
  }

  void clearOrders() {
    _orders.clear();
    _userId = null;
    _userName = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void cancelOrderCreation() {
    if (_isCreatingOrder) {
      _isCreatingOrder = false;
      _error = 'Order creation cancelled';
      notifyListeners();
    }
  }

  Future<void> _refreshUserSession() async {
    try {
      final user = await UserSession.getUser();
      _userId = user['userId'];
      _userName = user['userName'];

      if (_userId == null) {
        throw Exception('No user session found');
      }
    } catch (e) {
      throw Exception('Please login to continue');
    }
  }

  int get totalPointsEarned {
    return _orders.fold(0, (sum, order) => sum + order.pointsEarned);
  }

  Map<String, int> getOrdersByMonth() {
    final Map<String, int> monthlyOrders = {};

    for (var order in _orders) {
      final monthKey =
          '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
      monthlyOrders[monthKey] = (monthlyOrders[monthKey] ?? 0) + 1;
    }

    return monthlyOrders;
  }

  Map<String, int> getFavoriteProducts() {
    final Map<String, int> productCounts = {};

    for (var order in _orders) {
      for (var item in order.items) {
        productCounts[item.name] =
            (productCounts[item.name] ?? 0) + item.quantity;
      }
    }

    return productCounts;
  }

  void debugPrintOrders() {
    print('=== DEBUG: OrderProvider State ===');
    print('User ID: $_userId');
    print('User Name: $_userName');
    print('Total Orders: ${_orders.length}');
    print('Loading: $_isLoading, Creating Order: $_isCreatingOrder');
    print('Error: $_error');
    print('--- Orders List ---');

    for (var i = 0; i < _orders.length; i++) {
      final order = _orders[i];
      print('[$i] Order #${order.id}');
      print(
        '    User ID: ${order.userId} (matches current: ${order.userId == _userId})',
      );
      print('    Items: ${order.items.length}, Total: \$${order.total}');
      print('    Status: ${order.status}, Created: ${order.createdAt}');
      print('    Points: ${order.pointsEarned}');

      for (var item in order.items) {
        print(
          '    - ${item.name} × ${item.quantity} = \$${(item.price * item.quantity).toStringAsFixed(2)}',
        );
      }
    }
    print('=== END DEBUG ===');
  }
}
