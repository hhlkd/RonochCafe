// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ronoch_coffee/models/user_model.dart';

class UserService {
  // Use the correct base URL - match it with MockApiService
  static const String baseUrl = "https://6958c2cc6c3282d9f1d5ba0a.mockapi.io";

  // Register new user
  static Future<User> registerUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromJson(data);
    } else {
      print('❌ Register failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to register user: ${response.statusCode}');
    }
  }

  // Get all users
  static Future<List<User>> getAllUsers() async {
    print('🔍 Fetching all users from: $baseUrl/users');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Accept': 'application/json'},
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Found ${data.length} users');
        return data.map((item) => User.fromJson(item)).toList();
      } else {
        print(
          '❌ Failed to load users: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getAllUsers: $e');
      rethrow;
    }
  }

  // Login user
  static Future<User?> login(String identifier, String password) async {
    print('🔐 Attempting login for identifier: $identifier');

    try {
      final users = await getAllUsers();
      print('📋 Checking ${users.length} users for login match');

      for (final user in users) {
        print('  👤 Checking user: ${user.username} (${user.email})');

        final emailMatch =
            user.email.isNotEmpty &&
            user.email.toLowerCase() == identifier.toLowerCase();
        final phoneMatch = user.phone.isNotEmpty && user.phone == identifier;
        final nameMatch =
            user.username.isNotEmpty &&
            user.username.toLowerCase() == identifier.toLowerCase();

        print('    ✅ Email match: $emailMatch');
        print('    ✅ Phone match: $phoneMatch');
        print('    ✅ Name match: $nameMatch');
        print('    🔑 Password check: ${user.password == password}');

        if ((emailMatch || phoneMatch || nameMatch) &&
            user.password == password) {
          print('✅ Login successful for: ${user.username}');
          return user;
        }
      }

      print('❌ No matching user found');
      return null;
    } catch (e) {
      print('❌ Login exception: $e');
      return null;
    }
  }

  // Get user by ID - FIXED VERSION
  static Future<User> getUserById(String userId) async {
    print('🔍 Fetching user by ID: $userId from $baseUrl/users/$userId');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId'),
        headers: {'Accept': 'application/json'},
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ User found: ${data['username']}');
        return User.fromJson(data);
      } else {
        print(
          '❌ Failed to load user: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception in getUserById: $e');
      rethrow;
    }
  }

  // Update user
  static Future<User> updateUser(User user) async {
    print('📝 Updating user: ${user.id}');

    final response = await http.put(
      Uri.parse('$baseUrl/users/${user.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toJson()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ User updated successfully');
      return User.fromJson(data);
    } else {
      print('❌ Update failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  // Check if user exists by email
  static Future<bool> checkEmailExists(String email) async {
    final users = await getAllUsers();
    return users.any((user) => user.email == email);
  }

  // Check if user exists by phone
  static Future<bool> checkPhoneExists(String phone) async {
    final users = await getAllUsers();
    return users.any((user) => user.phone == phone);
  }
}
