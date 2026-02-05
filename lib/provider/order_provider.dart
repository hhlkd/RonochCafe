import 'package:flutter/material.dart';
import 'package:ronoch_coffee/models/cart_model.dart';
import 'package:ronoch_coffee/models/order.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class OrderProvider with ChangeNotifier {
  // State variables
  List<Order> _orders = [];
  bool _isLoading = false;
  bool _isCreatingOrder = false;
  String? _error;
  String? _userId;
  String? _userName;

  // Getters
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

  /// Initialize the provider with current user from session
  Future<void> initialize() async {
    try {
      print('🔄 Initializing OrderProvider...');

      // Get user from session
      final user = await UserSession.getUser();
      _userId = user['userId'];
      _userName = user['userName'];

      if (_userId == null || _userId!.isEmpty) {
        print('⚠️ No user ID found in session');
        return;
      }

      print('✅ OrderProvider initialized for user: $_userName (ID: $_userId)');

      // Load orders for this user
      await fetchOrders();
    } catch (e) {
      print('❌ Error initializing OrderProvider: $e');
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  /// Set user ID manually (for registration/login flows)
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

  /// Fetch orders for the current user from MockAPI
  Future<void> fetchOrders({bool forceRefresh = false}) async {
    // Skip if already loading
    if (_isLoading && !forceRefresh) return;

    // Validate user is logged in
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
      // Fetch orders from MockAPI
      final apiOrders = await MockApiService.getUserOrders(_userId!);
      print('📦 Received ${apiOrders.length} orders from API');

      // Log order details for debugging
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

      // Process and deduplicate orders
      _orders = _processOrders(apiOrders);
      print('✅ Displaying ${_orders.length} unique orders for $_userName');

      // Sort by creation date (newest first)
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('❌ ERROR fetching orders: $e');
      _error = 'Failed to load orders: ${e.toString()}';

      // Fallback: Try to get all orders and filter manually
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

  /// Process and deduplicate orders
  List<Order> _processOrders(List<Order> orders) {
    if (orders.isEmpty) return [];

    final uniqueOrders = <Order>[];
    final seenOrderIds = <String>{};

    for (var order in orders) {
      // Filter out orders that don't belong to current user
      if (order.userId != _userId) {
        continue;
      }

      // Skip duplicates
      if (seenOrderIds.contains(order.id)) {
        continue;
      }

      // Validate order has required fields
      if (order.id.isEmpty || order.items.isEmpty) {
        continue;
      }

      uniqueOrders.add(order);
      seenOrderIds.add(order.id);
    }

    return uniqueOrders;
  }

  /// Create a new order from cart items
  Future<Order> createOrderFromCart({
    required Cart cart,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    // Validate user
    if (_userId == null) {
      await _refreshUserSession();
      if (_userId == null) {
        throw Exception('Please login to place an order');
      }
    }

    // Validate cart
    if (cart.items.isEmpty) {
      throw Exception('Cart is empty');
    }

    print('🛒 Creating order from cart for user $_userName ($_userId)');
    print('   📦 Items: ${cart.items.length}, Total: \$${cart.total}');

    _isCreatingOrder = true;
    _error = null;
    notifyListeners();

    try {
      // Get user details from MockAPI
      final user = await MockApiService.getUserById(_userId!);
      if (user == null) {
        throw Exception('User not found in database');
      }

      print('👤 Order for: ${user.username} (${user.email})');

      // Calculate points (2 points per drink)
      final totalQuantity = cart.items.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
      final pointsEarned = totalQuantity * 2;

      print(
        '🎯 Points to earn: $pointsEarned (${totalQuantity} drinks × 5 points)',
      );

      // Convert cart items to order items
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

      // Create order object
      final order = Order(
        id: '', // Let MockAPI generate ID
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

      // Save order to MockAPI
      final createdOrder = await MockApiService.createOrder(order);

      print('✅ Order saved with ID: ${createdOrder.id}');
      print(
        '   📊 Status: ${createdOrder.status}, Points: ${createdOrder.pointsEarned}',
      );

      // Update user points in MockAPI
      print('🔼 Updating user points...');
      await MockApiService.addUserPoint(_userId!, pointsEarned);
      print('✅ User points updated: +$pointsEarned points');

      // Refresh orders list to include the new order
      await Future.delayed(const Duration(milliseconds: 800));
      await fetchOrders(forceRefresh: true);

      // Clear any existing error
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

  /// Create a direct order (without cart)
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
      // Get user details
      final user = await MockApiService.getUserById(_userId!);
      if (user == null) {
        throw Exception('User not found');
      }

      // Calculate points
      final totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
      final pointsEarned = totalQuantity * 2;

      // Create order
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

      // Save to MockAPI
      final createdOrder = await MockApiService.createOrder(order);

      // Update user points
      await MockApiService.addUserPoint(_userId!, pointsEarned);

      // Refresh orders
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

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      print('📝 Updating order $orderId status to: $status');

      final updatedOrder = await MockApiService.updateOrderStatus(
        orderId,
        status,
      );

      // Update local state
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

  /// Get order by ID
  Order? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders
        .where((order) => order.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// Get recent orders (limit number)
  List<Order> getRecentOrders({int limit = 5}) {
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _orders.take(limit).toList();
  }

  /// Get order statistics
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
      // Fallback to local calculation
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

  /// Check if user has pending orders
  Future<bool> hasPendingOrders() async {
    if (_userId == null) return false;

    try {
      return await MockApiService.hasPendingOrders(_userId!);
    } catch (e) {
      // Fallback to local check
      return pendingOrders > 0;
    }
  }

  /// Clear all orders (for logout)
  void clearOrders() {
    _orders.clear();
    _userId = null;
    _userName = null;
    _error = null;
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cancel order creation (if needed)
  void cancelOrderCreation() {
    if (_isCreatingOrder) {
      _isCreatingOrder = false;
      _error = 'Order creation cancelled';
      notifyListeners();
    }
  }

  /// Refresh user session
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

  /// Get total points earned from all orders
  int get totalPointsEarned {
    return _orders.fold(0, (sum, order) => sum + order.pointsEarned);
  }

  /// Get order count by month
  Map<String, int> getOrdersByMonth() {
    final Map<String, int> monthlyOrders = {};

    for (var order in _orders) {
      final monthKey =
          '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}';
      monthlyOrders[monthKey] = (monthlyOrders[monthKey] ?? 0) + 1;
    }

    return monthlyOrders;
  }

  /// Get favorite products (most ordered)
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

  /// Debug function to print order details
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
