// services/user_session.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _userIdKey = 'userId';
  static const String _usernameKey = 'username';
  static const String _userEmailKey = 'userEmail';
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _phoneKey = 'phone';
  static const String _addressKey = 'address';
  static const String _profileImageKey = 'profileImage';
  static const String _pointKey = 'point';
  static const String _createdAtKey = 'createdAt';

  // Save user data
  static Future<void> saveUser(
    String userId,
    String username,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_userEmailKey, email);
    await prefs.setBool(_isLoggedInKey, true);
    print('💾 Saved basic user data: $username ($email)');
  }

  // Extended save method for profile updates
  static Future<void> saveUserProfile({
    required String userId,
    required String username,
    required String email,
    String phone = '',
    String address = '',
    String profileImage = '',
    int point = 0,
    String createdAt = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_userEmailKey, email);
    await prefs.setBool(_isLoggedInKey, true);

    if (phone.isNotEmpty) await prefs.setString(_phoneKey, phone);
    if (address.isNotEmpty) await prefs.setString(_addressKey, address);
    if (profileImage.isNotEmpty)
      await prefs.setString(_profileImageKey, profileImage);
    await prefs.setInt(_pointKey, point);
    if (createdAt.isNotEmpty) await prefs.setString(_createdAtKey, createdAt);

    print('💾 Saved full user profile: $username');
  }

  // Get user data - returns Map
  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'userId': prefs.getString(_userIdKey) ?? '',
      'username': prefs.getString(_usernameKey) ?? '',
      'email': prefs.getString(_userEmailKey) ?? '',
      'phone': prefs.getString(_phoneKey) ?? '',
      'address': prefs.getString(_addressKey) ?? '',
      'profileImage': prefs.getString(_profileImageKey) ?? '',
      'point': prefs.getInt(_pointKey) ?? 0,
      'createdAt': prefs.getString(_createdAtKey) ?? '',
    };
  }

  // Individual getter methods for easier access
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<int> getUserPoints() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_pointKey) ?? 0;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('🚪 User logged out - cleared session');
  }

  static Future<void> updateUserPoints(int points) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pointKey, points);
    print('📝 Updated user points: $points');
  }

  static Future<void> updateProfileImage(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, imageUrl);
  }

  static Future<void> updateAddress(String address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
  }
}
