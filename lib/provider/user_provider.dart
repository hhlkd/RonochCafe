import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ronoch_coffee/models/user_model.dart';
import 'package:ronoch_coffee/services/user_service.dart';
import 'package:ronoch_coffee/services/user_session.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;

  Future<void> loadUserFromSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final isLoggedIn = await UserSession.isLoggedIn();
      if (isLoggedIn) {
        final userData = await UserSession.getUser();
        final user = await UserService.getUserById(userData['userId'] ?? '');
        _currentUser = user;
      }
    } catch (e) {
      _error = 'Failed to load user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await UserService.login(identifier, password);
      if (user != null) {
        _currentUser = user;
        await UserSession.saveUser(user.id, user.username, user.email);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid credentials';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final registeredUser = await UserService.registerUser(user);
      _currentUser = registeredUser;
      await UserSession.saveUser(
        registeredUser.id,
        registeredUser.username,
        registeredUser.email,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await UserSession.logout();
    _currentUser = null;
    notifyListeners();
  }

  // =========== NEW METHODS FOR PROFILE EDITING ===========
  Future<bool> updateProfile(User updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedUserFromApi = await UserService.updateUser(updatedUser);

      _currentUser = updatedUserFromApi;

      await UserSession.saveUserProfile(
        userId: updatedUserFromApi.id,
        username: updatedUserFromApi.username,
        email: updatedUserFromApi.email,
        phone: updatedUserFromApi.phone,
        address: updatedUserFromApi.address,
        profileImage: updatedUserFromApi.profileImage,
        point: updatedUserFromApi.point,
        createdAt: updatedUserFromApi.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Update failed: $e';
      print('❌ Error updating profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> updateProfileImage(File imageFile) async {
    if (_currentUser == null) return null;

    try {
      final username = _currentUser!.username;
      final avatarUrl =
          'https://ui-avatars.com/api/?name=${Uri.encodeComponent(username)}&background=6F4E37&color=fff&size=200';
      final updatedUser = _currentUser!.copyWith(profileImage: avatarUrl);

      final success = await updateProfile(updatedUser);

      return success ? avatarUrl : null;
    } catch (e) {
      print('Error updating profile image: $e');
      return null;
    }
  }

  Future<void> refreshUser() async {
    if (_currentUser != null) {
      try {
        final user = await UserService.getUserById(_currentUser!.id);
        _currentUser = user;
        notifyListeners();
      } catch (e) {
        print('Refresh user error: $e');
      }
    }
  }
}
