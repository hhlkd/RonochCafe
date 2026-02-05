// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:ronoch_coffee/models/user_model.dart';
// import 'package:ronoch_coffee/services/user_session.dart';

// class PointsService {
//   static const String _baseUrl = 'https://6958c2cc.mockapi.io';
//   static const int _pointsPerOrder = 2;

//   // Award points when order is completed
//   static Future<void> awardPointsForOrder(String orderId) async {
//     try {
//       final userId = await UserSession.getUser();
//       if (userId == null) return;

//       // Get current user
//       final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
//       if (response.statusCode == 200) {
//         final user = User.fromJson(jsonDecode(response.body));

//         // Update user points
//         final updatedUser = user.copyWith(
//           points: user.points + _pointsPerOrder,
//         );

//         // Save to API
//         await http.put(
//           Uri.parse('$_baseUrl/users/$userId'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode(updatedUser.toJson()),
//         );

//         // Save to local session
//         await UserSession.updateUserPoints(updatedUser.points);

//         // Record point transaction
//         await _recordPointTransaction(
//           userId: userId,
//           points: _pointsPerOrder,
//           type: 'earned',
//           description: 'Points earned for order #$orderId',
//           orderId: orderId,
//         );
//       }
//     } catch (e) {
//       print('Error awarding points: $e');
//     }
//   }

//   // Use points for redemption
//   static Future<bool> redeemPoints(int pointsToRedeem, String itemName) async {
//     try {
//       final userId = await UserSession.getUserId();
//       if (userId == null) return false;

//       // Get current user
//       final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
//       if (response.statusCode == 200) {
//         final user = User.fromJson(jsonDecode(response.body));

//         // Check if user has enough points
//         if (user.points < pointsToRedeem) {
//           return false;
//         }

//         // Deduct points
//         final updatedUser = user.copyWith(points: user.points - pointsToRedeem);

//         // Save to API
//         await http.put(
//           Uri.parse('$_baseUrl/users/$userId'),
//           headers: {'Content-Type': 'application/json'},
//           body: jsonEncode(updatedUser.toJson()),
//         );

//         // Save to local session
//         await UserSession.updateUserPoints(updatedUser.points);

//         // Record redemption transaction
//         await _recordPointTransaction(
//           userId: userId,
//           points: -pointsToRedeem, // Negative for redemption
//           type: 'redeemed',
//           description: 'Redeemed $itemName',
//         );

//         return true;
//       }
//     } catch (e) {
//       print('Error redeeming points: $e');
//     }
//     return false;
//   }

//   // Record point transaction history
//   static Future<void> _recordPointTransaction({
//     required String userId,
//     required int points,
//     required String type,
//     required String description,
//     String? orderId,
//   }) async {
//     try {
//       final transaction = {
//         'userId': userId,
//         'points': points,
//         'type': type, // 'earned' or 'redeemed'
//         'description': description,
//         'orderId': orderId,
//         'createdAt': DateTime.now().toIso8601String(),
//       };

//       await http.post(
//         Uri.parse('$_baseUrl/pointTransactions'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(transaction),
//       );
//     } catch (e) {
//       print('Error recording transaction: $e');
//     }
//   }

//   // Get user's point history
//   static Future<List<Map<String, dynamic>>> getPointHistory() async {
//     try {
//       final userId = await UserSession.getUserId();
//       if (userId == null) return [];

//       final response = await http.get(
//         Uri.parse('$_baseUrl/pointTransactions?userId=$userId'),
//       );

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         return List<Map<String, dynamic>>.from(data);
//       }
//     } catch (e) {
//       print('Error getting point history: $e');
//     }
//     return [];
//   }
// }
