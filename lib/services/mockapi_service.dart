import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ronoch_coffee/models/order.dart';
import 'package:ronoch_coffee/models/redemption_record_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/cart_model.dart';
import '../models/announcement_model.dart';
import '../models/address_model.dart';
import '../models/image_model.dart';
import '../models/reward_item_model.dart';

class MockApiService {
  static const String baseUrl = "https://6958c2cc6c3282d9f1d5ba0a.mockapi.io";

  // ============ USERS ============
  static Future<List<User>> getUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => User.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<Order> createOrderWithPoints({
    required String userId,
    required List<CartItem> cartItems,
    required double total,
    required String paymentMethod,
    required String deliveryAddress,
  }) async {
    try {
      final totalQuantity = cartItems.fold(
        0,
        (sum, item) => sum + item.quantity,
      );
      final pointsEarned = totalQuantity * 5;
      final orderItems =
          cartItems.map((cartItem) {
            return OrderItem(
              productId: cartItem.productId,
              name: cartItem.name,
              quantity: cartItem.quantity,
              price: cartItem.price,
              size: cartItem.size,
              sugarLevel: cartItem.sugarLevel,
              iceLevel: cartItem.iceLevel,
            );
          }).toList();
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        items: orderItems,
        total: total,
        status: 'completed',
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );

      final createdOrder = await createOrder(order);

      await addUserPoint(userId, pointsEarned);

      return createdOrder;
    } catch (e) {
      print('Error creating order with points: $e');
      rethrow;
    }
  }

  static int calculatePointsFromCart(List<CartItem> cartItems) {
    final totalQuantity = cartItems.fold(0, (sum, item) => sum + item.quantity);
    return totalQuantity * 5; // 5 points per drink
  }

  static int calculatePointsForItem(CartItem item) {
    return item.quantity * 5; // 5 points per drink
  }

  static Future<User?> login(String email, String password) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));

      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);

        for (var user in users) {
          if (user['email'] == email && user['password'] == password) {
            return User.fromJson(user);
          }
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  static Future<User> register(
    String username,
    String email,
    String phone,
    String password,
    String address,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address,
        'profileImage': '',
        'point': 0,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Register failed: ${response.statusCode}');
    }
  }

  static Future<User> updateUser(String userId, User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Update user failed');
    }
  }

  static Future<void> updateUserPoint(String userId, int point) async {
    try {
      print('🔄 Updating user points for $userId to $point');
      final user = await getUserById(userId);
      if (user == null) {
        print('❌ User not found for point update');
        return;
      }
      final updatedUser = User(
        id: user.id,
        username: user.username,
        email: user.email,
        phone: user.phone,
        password: user.password,
        address: user.address,
        profileImage: user.profileImage,
        point: point,
        createdAt: user.createdAt,
      );
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedUser.toJson()),
      );

      if (response.statusCode == 200) {
        print('✅ User points updated successfully in API');
      } else {
        print('❌ Failed to update user points: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error in updateUserPoint: $e');
    }
  }

  static Future<void> addUserPoint(String userId, int pointsToAdd) async {
    final user = await getUserById(userId);
    if (user != null) {
      final newPoint = user.point + pointsToAdd;
      await updateUserPoint(userId, newPoint);
    }
  }

  static Future<User?> getUserById(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  // ============ PRODUCTS ============
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Product.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get products error: $e');
      return [];
    }
  }

  static Future<Product?> getProductById(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
      );
      if (response.statusCode == 200) {
        return Product.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get product error: $e');
      return null;
    }
  }

  static Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getProducts();
    return products.where((product) => product.category == category).toList();
  }

  static Future<List<Product>> getPopularProducts() async {
    final products = await getProducts();
    return products.where((product) => product.popular == true).toList();
  }

  static Future<List<Product>> getPromotionProducts() async {
    final products = await getProducts();
    return products
        .where((product) => product.discount != null && product.discount! > 0)
        .toList();
  }

  // ============ ORDERS ============
  static Future<List<Order>> getOrders() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Order.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get orders error: $e');
      return [];
    }
  }

  static Future<List<Order>> getUserOrders(String userId) async {
    try {
      print('🔍 Fetching orders for user ID: $userId');

      final response = await http.get(Uri.parse('$baseUrl/orders'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print('📦 Total orders in API: ${data.length}');

        final List<Order> allOrders = [];
        for (var item in data) {
          try {
            final order = Order.fromJson(item);
            allOrders.add(order);
          } catch (e) {
            print('❌ Error parsing order: $e');
          }
        }
        final userOrders =
            allOrders.where((order) => order.userId == userId).toList();
        print('✅ Found ${userOrders.length} orders for user $userId');

        return userOrders;
      } else {
        print('❌ Failed to fetch orders. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Exception in getUserOrders: $e');
      return [];
    }
  }

  static Future<Order> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(order.toJson()),
    );

    if (response.statusCode == 201) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Create order failed: ${response.statusCode}');
    }
  }

  static Future<Order?> getOrderById(String orderId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/orders/$orderId'));
      if (response.statusCode == 200) {
        return Order.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get order error: $e');
      return null;
    }
  }

  static Future<Order> updateOrderStatus(String orderId, String status) async {
    final order = await getOrderById(orderId);
    if (order == null) {
      throw Exception('Order not found');
    }

    final updatedOrder = Order(
      id: order.id,
      userId: order.userId,
      items: order.items,
      total: order.total,
      status: status,
      deliveryAddress: order.deliveryAddress,
      paymentMethod: order.paymentMethod,
      createdAt: order.createdAt,
    );

    final response = await http.put(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedOrder.toJson()),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Update order status failed: ${response.statusCode}');
    }
  }

  // ============ CARTS ============
  static Future<List<Cart>> getCarts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/carts'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Cart.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get carts error: $e');
      return [];
    }
  }

  static Future<Cart?> getUserCart(String userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/carts'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final carts = data.map((e) => Cart.fromJson(e)).toList();
        for (var cart in carts) {
          if (cart.userId == userId) {
            return cart;
          }
        }
        return null;
      }
      return null;
    } catch (e) {
      print('Get user cart error: $e');
      return null;
    }
  }

  static Future<Cart> createCart(Cart cart) async {
    final response = await http.post(
      Uri.parse('$baseUrl/carts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cart.toJson()),
    );

    if (response.statusCode == 201) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Create cart failed');
    }
  }

  static Future<Cart> updateCart(String cartId, Cart cart) async {
    final response = await http.put(
      Uri.parse('$baseUrl/carts/$cartId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(cart.toJson()),
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Update cart failed');
    }
  }

  static Future<void> deleteCart(String cartId) async {
    final response = await http.delete(Uri.parse('$baseUrl/carts/$cartId'));

    if (response.statusCode != 200) {
      throw Exception('Delete cart failed');
    }
  }

  static Future<void> clearUserCart(String userId) async {
    try {
      final cart = await getUserCart(userId);
      if (cart != null) {
        await deleteCart(cart.id);
      }
    } catch (e) {
      print('Clear user cart error: $e');
    }
  }

  // ============ ANNOUNCEMENTS ============
  static Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/announcements'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Announcement.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get announcements error: $e');
      return [];
    }
  }

  static Future<List<Announcement>> getActiveAnnouncements() async {
    final announcements = await getAnnouncements();
    return announcements.where((ann) => ann.isActive).toList();
  }

  // ============ ADDRESSES ============
  static Future<List<Address>> getAddresses() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/addresses'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => Address.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get addresses error: $e');
      return [];
    }
  }

  static Future<List<Address>> getUserAddresses(String userId) async {
    try {
      final addresses = await getAddresses();
      return addresses.where((address) => address.userId == userId).toList();
    } catch (e) {
      print('Get user addresses error: $e');
      return [];
    }
  }

  static Future<Address> createAddress(Address address) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(address.toJson()),
    );

    if (response.statusCode == 201) {
      return Address.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Create address failed');
    }
  }

  static Future<void> deleteAddress(String addressId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/addresses/$addressId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Delete address failed');
    }
  }

  static Future<void> updateAddress(String addressId, Address address) async {
    final response = await http.put(
      Uri.parse('$baseUrl/addresses/$addressId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(address.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Update address failed');
    }
  }

  // ============ IMAGES ============
  static Future<List<AppImage>> getImages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/images'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => AppImage.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get images error: $e');
      return [];
    }
  }

  static Future<List<AppImage>> getImagesByType(String type) async {
    final images = await getImages();
    return images.where((image) => image.type == type).toList();
  }

  static Future<List<AppImage>> getSliderImages() async {
    return await getImagesByType('slider');
  }

  static Future<List<AppImage>> getBannerImages() async {
    return await getImagesByType('banner');
  }

  static Future<List<AppImage>> getCategoryImages() async {
    return await getImagesByType('category');
  }

  // ============ REWARD ITEMS ============
  static Future<List<RewardItem>> getRewardItems() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reward_items'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => RewardItem.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get reward items error: $e');
      return [];
    }
  }

  // ============ REDEMPTION RECORDS ============
  static Future<List<RedemptionRecord>> getRedemptionRecords() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/redemption_records'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((e) => RedemptionRecord.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Get redemption records error: $e');
      return [];
    }
  }

  static Future<RedemptionRecord?> getRedemptionRecordById(
    String recordId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/redemption_records/$recordId'),
      );

      if (response.statusCode == 200) {
        return RedemptionRecord.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get redemption record error: $e');
      return null;
    }
  }

  static Future<RedemptionRecord> createRedemptionRecord(
    RedemptionRecord record,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/redemption_records'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode == 201) {
      return RedemptionRecord.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Create redemption record failed: ${response.statusCode}',
      );
    }
  }

  static Future<RedemptionRecord> updateRedemptionRecord(
    String recordId,
    RedemptionRecord record,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/redemption_records/$recordId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(record.toJson()),
    );

    if (response.statusCode == 200) {
      return RedemptionRecord.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Update redemption record failed: ${response.statusCode}',
      );
    }
  }

  static Future<void> deleteRedemptionRecord(String recordId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/redemption_records/$recordId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Delete redemption record failed');
    }
  }

  static Future<List<RedemptionRecord>> getUserRedemptionRecords(
    String userId,
  ) async {
    try {
      final records = await getRedemptionRecords();
      return records.where((record) => record.userId == userId).toList();
    } catch (e) {
      print('Get user redemption records error: $e');
      return [];
    }
  }

  static Future<RedemptionRecord> markRedemptionAsCollected(
    String recordId,
    String collectedBy,
    String? notes,
  ) async {
    try {
      final record = await getRedemptionRecordById(recordId);

      if (record == null) {
        throw Exception('Redemption record not found');
      }

      final updatedRecord = record.copyWith(
        status: 'used',
        collectedAt: DateTime.now(),
        collectedBy: collectedBy,
        notes: notes,
      );

      return await updateRedemptionRecord(recordId, updatedRecord);
    } catch (e) {
      print('Mark redemption as collected error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserRedemptionStats(
    String userId,
  ) async {
    try {
      final records = await getUserRedemptionRecords(userId);

      final totalRedemptions = records.length;
      final pendingRedemptions = records.where((r) => r.isPending).length;
      final usedRedemptions = records.where((r) => r.isUsed).length;
      final expiredRedemptions = records.where((r) => r.isExpired).length;
      final totalPointsSpent = records.fold<int>(
        0,
        (sum, record) => sum + record.pointsUsed,
      );

      // Get active redemptions (valid and pending)
      final activeRedemptions =
          records.where((r) => r.isValid && r.isPending).toList();

      // Group by reward
      final Map<String, int> rewardCounts = {};
      for (var record in records) {
        rewardCounts[record.rewardName] =
            (rewardCounts[record.rewardName] ?? 0) + 1;
      }

      return {
        'totalRedemptions': totalRedemptions,
        'pendingRedemptions': pendingRedemptions,
        'usedRedemptions': usedRedemptions,
        'expiredRedemptions': expiredRedemptions,
        'totalPointsSpent': totalPointsSpent,
        'activeRedemptions': activeRedemptions,
        'rewardCounts': rewardCounts,
        'mostRedeemedReward':
            rewardCounts.isNotEmpty
                ? rewardCounts.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key
                : null,
      };
    } catch (e) {
      print('Get user redemption stats error: $e');
      return {
        'totalRedemptions': 0,
        'pendingRedemptions': 0,
        'usedRedemptions': 0,
        'expiredRedemptions': 0,
        'totalPointsSpent': 0,
        'activeRedemptions': [],
        'rewardCounts': {},
        'mostRedeemedReward': null,
      };
    }
  }

  static Future<RewardItem?> getRewardItemById(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reward_items/$itemId'),
      );
      if (response.statusCode == 200) {
        return RewardItem.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Get reward item error: $e');
      return null;
    }
  }

  static Future<bool> redeemRewardItem(
    String userId,
    String rewardItemId,
  ) async {
    try {
      print('🔄 Starting redemption process...');
      print('👤 User ID: $userId');
      print('🎁 Reward Item ID: $rewardItemId');

      // 1. Get user and reward item
      final user = await getUserById(userId);
      final rewardItem = await getRewardItemById(rewardItemId);

      print('📊 User: ${user?.username} with ${user?.point} points');
      print(
        '🎯 Reward: ${rewardItem?.name} costing ${rewardItem?.point} points',
      );

      if (user == null) {
        print('❌ User not found');
        return false;
      }

      if (rewardItem == null) {
        print('❌ Reward item not found');
        return false;
      }

      // 2. Check if user has enough points
      if (user.point < rewardItem.point) {
        print('❌ Insufficient points: ${user.point} < ${rewardItem.point}');
        return false;
      }

      // 3. Calculate new points
      final newPoint = user.point - rewardItem.point;
      print('✅ New points after deduction: $newPoint');

      // 4. Update user points (this should work as it updates the user directly)
      await updateUserPoint(userId, newPoint);
      print('✅ User points updated successfully');

      // 5. Try to create redemption record - but don't fail if endpoint doesn't exist
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/reward_redemptions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'rewardItemId': rewardItemId,
            'rewardName': rewardItem.name,
            'pointsUsed': rewardItem.point,
            'redeemedAt': DateTime.now().toIso8601String(),
          }),
        );

        if (response.statusCode == 201) {
          print('✅ Redemption record created successfully');
          return true;
        } else {
          print(
            '⚠️ Could not create redemption record (status: ${response.statusCode}), but points were deducted',
          );
          // Still return true because points were deducted
          return true;
        }
      } catch (e) {
        print('⚠️ Redemption record endpoint might not exist: $e');
        print('ℹ️ But user points were still updated');
        return true; // Return true because points were updated
      }
    } catch (e) {
      print('❌ Redeem reward error: $e');
      return false;
    }
  }

  static Future<bool> simpleRedeemReward(
    String userId,
    String rewardItemId,
  ) async {
    try {
      print('🔄 Using simple redemption method...');

      // Get user from API
      final userResponse = await http.get(Uri.parse('$baseUrl/users/$userId'));
      if (userResponse.statusCode != 200) {
        print('❌ User not found');
        return false;
      }

      final userData = jsonDecode(userResponse.body);
      final user = User.fromJson(userData);

      // Get reward item from API
      final rewardResponse = await http.get(
        Uri.parse('$baseUrl/reward_items/$rewardItemId'),
      );
      if (rewardResponse.statusCode != 200) {
        print('❌ Reward item not found');
        return false;
      }

      final rewardData = jsonDecode(rewardResponse.body);
      final rewardItem = RewardItem.fromJson(rewardData);

      // Check points
      if (user.point < rewardItem.point) {
        print('❌ Insufficient points: ${user.point} < ${rewardItem.point}');
        return false;
      }

      // Calculate new points
      final newPoints = user.point - rewardItem.point;

      // Update user directly
      userData['point'] = newPoints;

      final updateResponse = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      if (updateResponse.statusCode == 200) {
        print('✅ Simple redemption successful!');
        print('📊 User now has $newPoints points');
        return true;
      } else {
        print('❌ Failed to update user: ${updateResponse.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Simple redemption error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getUserRewardHistory(
    String userId,
  ) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reward_redemptions'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data
            .where((record) => record['userId'] == userId)
            .cast<Map<String, dynamic>>()
            .toList();
      }
      return [];
    } catch (e) {
      print('Get reward history error: $e');
      return [];
    }
  }

  // ============ HELPER METHODS ============
  static Future<bool> checkEmailExists(String email) async {
    final users = await getUsers();
    return users.any((user) => user.email == email);
  }

  static Future<bool> checkPhoneExists(String phone) async {
    final users = await getUsers();
    return users.any((user) => user.phone == phone);
  }

  static Future<Order> createOrderFromCart({
    required String userId,
    required Cart cart,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
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
          );
        }).toList();

    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: orderItems,
      total: cart.total,
      status: 'pending',
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    // Create order in API
    final createdOrder = await createOrder(order);

    // Clear user cart
    await clearUserCart(userId);

    // Award points based on order total (1 point per $10 spent)
    final pointsToAdd = (cart.total ~/ 10).toInt();
    if (pointsToAdd > 0) {
      await addUserPoint(userId, pointsToAdd);
    }

    return createdOrder;
  }

  static Future<Order> createDirectOrder({
    required String userId,
    required List<OrderItem> items,
    required double total,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      items: items,
      total: total,
      status: 'pending',
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );

    final createdOrder = await createOrder(order);

    // Award points
    final pointsToAdd = (total ~/ 10).toInt();
    if (pointsToAdd > 0) {
      await addUserPoint(userId, pointsToAdd);
    }

    return createdOrder;
  }

  static Future<Map<String, dynamic>> getUserOrderStats(String userId) async {
    try {
      final orders = await getUserOrders(userId);

      final totalOrders = orders.length;
      final completedOrders =
          orders.where((o) => o.status == 'completed').length;
      final pendingOrders = orders.where((o) => o.status == 'pending').length;
      final totalSpent = orders.fold(0.0, (sum, order) => sum + order.total);
      final averageOrderValue = totalOrders > 0 ? totalSpent / totalOrders : 0;

      return {
        'totalOrders': totalOrders,
        'completedOrders': completedOrders,
        'pendingOrders': pendingOrders,
        'totalSpent': totalSpent,
        'averageOrderValue': averageOrderValue,
      };
    } catch (e) {
      print('Get order stats error: $e');
      return {
        'totalOrders': 0,
        'completedOrders': 0,
        'pendingOrders': 0,
        'totalSpent': 0.0,
        'averageOrderValue': 0.0,
      };
    }
  }

  static Future<Address> saveUserAddress(Address address) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addresses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(address.toJson()),
    );

    if (response.statusCode == 201) {
      return Address.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Save address failed: ${response.statusCode}');
    }
  }

  static Future<List<AppImage>> getPaymentMethods() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/images'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        final images = data.map((e) => AppImage.fromJson(e)).toList();
        return images.where((image) => image.type == 'payment_method').toList();
      }
      return [];
    } catch (e) {
      print('Get payment methods error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getHomeScreenData(String userId) async {
    try {
      final announcements = await getActiveAnnouncements();
      final products = await getProducts();
      final user = await getUserById(userId);
      final cart = await getUserCart(userId);
      final rewardItems = await getRewardItems();
      final sliderImages = await getSliderImages();

      // Get popular and promotion products
      final popularProducts = products.where((p) => p.popular == true).toList();
      final promotionProducts =
          products.where((p) => p.discount != null && p.discount! > 0).toList();

      return {
        'announcements': announcements,
        'products': products,
        'popularProducts': popularProducts,
        'promotionProducts': promotionProducts,
        'user': user,
        'cart': cart,
        'rewardItems': rewardItems,
        'sliderImages': sliderImages,
      };
    } catch (e) {
      print('Error loading home data: $e');
      return {
        'announcements': [],
        'products': [],
        'popularProducts': [],
        'promotionProducts': [],
        'user': null,
        'cart': null,
        'rewardItems': [],
        'sliderImages': [],
      };
    }
  }

  static Future<Map<String, List<Product>>> getCategorizedProducts() async {
    try {
      final products = await getProducts();

      final coffeeProducts =
          products
              .where((p) => p.category.toLowerCase().contains('coffee'))
              .toList();

      final teaProducts =
          products
              .where((p) => p.category.toLowerCase().contains('tea'))
              .toList();

      final pastryProducts =
          products
              .where(
                (p) =>
                    p.category.toLowerCase().contains('pastry') ||
                    p.category.toLowerCase().contains('dessert'),
              )
              .toList();

      final snackProducts =
          products
              .where((p) => p.category.toLowerCase().contains('snack'))
              .toList();

      final noodleProducts =
          products
              .where((p) => p.category.toLowerCase().contains('noodle'))
              .toList();

      return {
        'Coffee': coffeeProducts,
        'Tea': teaProducts,
        'Pastries': pastryProducts,
        'Snacks': snackProducts,
        'Noodles': noodleProducts,
      };
    } catch (e) {
      print('Error loading categorized products: $e');
      return {};
    }
  }

  static Future<bool> hasPendingOrders(String userId) async {
    try {
      final orders = await getUserOrders(userId);
      return orders.any(
        (order) => order.status == 'pending' || order.status == 'processing',
      );
    } catch (e) {
      print('Check pending orders error: $e');
      return false;
    }
  }

  static Future<List<Order>> getRecentOrders(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final orders = await getUserOrders(userId);
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders.take(limit).toList();
    } catch (e) {
      print('Get recent orders error: $e');
      return [];
    }
  }
}
