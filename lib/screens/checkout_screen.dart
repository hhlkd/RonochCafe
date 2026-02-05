import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ronoch_coffee/models/cart_model.dart';
import 'package:ronoch_coffee/provider/cart_provider.dart';
import 'package:ronoch_coffee/models/image_model.dart';
import 'package:ronoch_coffee/screens/address_screen.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? selectedPaymentId;
  List<AppImage> paymentMethods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<AppImage> methods = await MockApiService.getPaymentMethods();
      setState(() {
        paymentMethods = methods;
        if (methods.isNotEmpty) {
          selectedPaymentId = methods[0].id;
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        paymentMethods = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final totalPrice = cart.totalPrice;

    final totalQuantity = cart.items.fold(
      0,
      (sum, item) => sum + item.quantity,
    );
    final pointsEarned = totalQuantity * 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Check Out",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body:
          cart.items.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Your cart is empty",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Add items to your cart first",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddressScreen(),
                            ),
                          ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Input Location for Delivery",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Summary",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _buildCartItem(item);
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Colors.grey),
                    const SizedBox(height: 20),
                    _buildSummaryRow(
                      label: "SubTotal",
                      value: "\$${totalPrice.toStringAsFixed(2)}",
                      isBold: false,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      label: "Points Earned",
                      value: "+${pointsEarned}pts",
                      valueColor: Colors.green,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      label: "Total Drinks",
                      value: "$totalQuantity items",
                      isBold: false,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "Payment Methods",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            color: Color(0xFFA68A73),
                          ),
                        ),
                      )
                    else if (paymentMethods.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "No payment methods available",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Column(
                        children:
                            paymentMethods
                                .map(
                                  (method) => _buildPaymentMethod(
                                    method,
                                    isSelected: selectedPaymentId == method.id,
                                    onTap:
                                        () => setState(() {
                                          selectedPaymentId = method.id;
                                        }),
                                  ),
                                )
                                .toList(),
                      ),

                    const SizedBox(height: 32),
                    _buildSummaryRow(
                      label: "Total Amount",
                      value: "\$${totalPrice.toStringAsFixed(2)}",
                      isBold: true,
                    ),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      label: "Points to Earn",
                      value: "${pointsEarned}pts",
                      valueColor: Colors.green,
                      isBold: true,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            () => _processPayment(context, cart, pointsEarned),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA68A73),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Pay",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFA68A73).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              "${item.quantity}x",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA68A73),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade100,
          ),
          child:
              item.imageUrl.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFA68A73),
                              ),
                            ),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.coffee,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                    ),
                  )
                  : Center(
                    child: Icon(
                      Icons.coffee,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
                  ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              if (item.size.isNotEmpty)
                Text(
                  "Size: ${item.size}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              if (item.sugarLevel.isNotEmpty)
                Text(
                  "Sugar: ${item.sugarLevel}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              if (item.iceLevel.isNotEmpty)
                Text(
                  "Ice: ${item.iceLevel}",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 4),
              Text(
                "Points: ${item.quantity * 2}pts",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$${(item.price * item.quantity).toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${item.quantity} × \$${item.price.toStringAsFixed(2)}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: valueColor ?? Colors.black,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(
    AppImage paymentMethod, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    String paymentText = "Pay with ${paymentMethod.name}";
    if (paymentMethod.name.toUpperCase().contains('KHQR')) {
      paymentText = "Scan QR Code";
    } else if (paymentMethod.name.toUpperCase().contains('CASH')) {
      paymentText = "Pay on Delivery";
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFA68A73) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFFA68A73).withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                  : [],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child:
                  paymentMethod.imageUrl.isNotEmpty
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: paymentMethod.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          placeholder:
                              (context, url) => Container(
                                color: Colors.grey.shade50,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFA68A73),
                                  ),
                                ),
                              ),
                          errorWidget:
                              (context, url, error) => Container(
                                color: Colors.grey.shade50,
                                child: Icon(
                                  Icons.payment,
                                  color: Colors.grey.shade400,
                                  size: 24,
                                ),
                              ),
                        ),
                      )
                      : Center(
                        child: Icon(
                          Icons.payment,
                          color: Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paymentMethod.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paymentText,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFA68A73),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(
    BuildContext context,
    CartProvider cart,
    int pointsEarned,
  ) async {
    if (selectedPaymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a payment method"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final selectedMethod = paymentMethods.firstWhere(
      (method) => method.id == selectedPaymentId,
      orElse:
          () => AppImage(
            id: '',
            name: 'Unknown',
            imageUrl: '',
            type: 'payment_method',
            category: 'Unknown',
          ),
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedMethod.imageUrl.isNotEmpty)
                      Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: selectedMethod.imageUrl,
                            fit: BoxFit.contain,
                            errorWidget:
                                (context, url, error) => Center(
                                  child: Icon(
                                    Icons.payment,
                                    color: Colors.grey.shade400,
                                    size: 30,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    const CircularProgressIndicator(
                      color: Color(0xFFA68A73),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Processing with ${selectedMethod.name}...",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You'll earn $pointsEarned points",
                      style: const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${cart.items.length} items • \$${cart.totalPrice.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
    try {
      final user = await UserSession.getUser();
      final currentUserId = user['userId'];

      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception("User not logged in. Please login again.");
      }
      // ignore: avoid_print
      print('👤 Current logged-in user ID: $currentUserId');
      final userDetails = await MockApiService.getUserById(currentUserId);
      if (userDetails == null) {
        throw Exception("User not found in database. Please login again.");
      }
      // ignore: avoid_print
      print('✅ User verified: ${userDetails.username} (ID: ${userDetails.id})');
      final orderItems =
          cart.items.map((item) {
            return {
              'productId': item.productId,
              'name': item.name,
              'quantity': item.quantity,
              'price': item.price,
              'total': item.price * item.quantity,
              'imageUrl': item.imageUrl,
              'size': item.size,
              'sugarLevel': item.sugarLevel,
              'iceLevel': item.iceLevel,
              'points': item.quantity * 2, // 2 points per item
            };
          }).toList();
      final orderData = {
        'userId': currentUserId,
        'userName': userDetails.username,
        'userEmail': userDetails.email,
        'userPhone': userDetails.phone,
        'items': orderItems,
        'total': cart.totalPrice,
        'pointsEarned': pointsEarned,
        'paymentMethod': selectedMethod.name,
        'paymentMethodId': selectedMethod.id,
        'paymentMethodLogo': selectedMethod.imageUrl,
        'status': 'completed',
        'deliveryAddress': 'Pickup at store',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      print('📦 Order data for user $currentUserId:');
      print('   User: ${userDetails.username}');
      print('   Items: ${orderItems.length}');
      print('   Total: \$${cart.totalPrice}');
      print('   Points: $pointsEarned');
      final response = await http.post(
        Uri.parse('${MockApiService.baseUrl}/orders'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(orderData),
      );
      if (response.statusCode == 201) {
        print('✅ Order saved successfully for user $currentUserId!');
        try {
          final currentPoints = userDetails.point;
          final newPoints = currentPoints + pointsEarned;
          await MockApiService.updateUserPoint(currentUserId, newPoints);
          print('✅ User points updated: $currentPoints → $newPoints');
        } catch (pointsError) {
          print('⚠️ Could not update user points: $pointsError');
        }
      } else {
        print('❌ Failed to save order. Status: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception("Failed to save order. Status: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Error processing payment: $e');
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    cart.clearCart();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Payment Successful!"),
                  Text(
                    "Paid with ${selectedMethod.name} • Earned $pointsEarned points",
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }
}
