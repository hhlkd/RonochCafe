// ✅ ក្នុង lib/provider/reward_provider.dart

import 'package:flutter/material.dart';
import 'package:ronoch_coffee/models/reward_item_model.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';

class RewardProvider with ChangeNotifier {
  List<RewardItem> _rewards = [];
  bool _isLoading = false;
  String? _error;
  bool _isRedeeming = false;
  int _userPoints = 0; // ✅ เพิ่ม user points tracking

  List<RewardItem> get rewards => _rewards;
  bool get isLoading => _isLoading;
  bool get isRedeeming => _isRedeeming;
  String? get error => _error;
  int get userPoints => _userPoints; // ✅ Getter for points

  Future<void> fetchRewards() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('🔄 Fetching rewards from API...');
      final rewards = await MockApiService.getRewardItems();
      _rewards = rewards;
      print('✅ Loaded ${rewards.length} rewards');
    } catch (e) {
      _error = 'Failed to load rewards: $e';
      print('❌ Error fetching rewards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NEW METHOD: Update user points after purchase
  Future<void> updateUserPoints(int newPoints) async {
    try {
      print('💰 Updating points to: $newPoints');

      _userPoints = newPoints;
      notifyListeners(); // ✅ NOTIFY UI IMMEDIATELY

      print('✅ Points updated and UI notified');
    } catch (e) {
      print('❌ Error updating points: $e');
      _error = 'Failed to update points: $e';
      notifyListeners();
    }
  }

  // ✅ NEW METHOD: Add points to existing
  Future<void> addPoints(int pointsToAdd) async {
    try {
      print('➕ Adding $pointsToAdd points');

      _userPoints += pointsToAdd;
      notifyListeners(); // ✅ NOTIFY UI IMMEDIATELY

      print('✅ Points added: $_userPoints total');
    } catch (e) {
      print('❌ Error adding points: $e');
      _error = 'Failed to add points: $e';
      notifyListeners();
    }
  }

  // ✅ NEW METHOD: Load user points
  Future<void> loadUserPoints(String userId) async {
    try {
      print('📊 Loading user points for: $userId');

      final user = await MockApiService.getUserById(userId);
      if (user != null) {
        _userPoints = user.point;
        notifyListeners();
        print('✅ Points loaded: $_userPoints');
      }
    } catch (e) {
      print('❌ Error loading points: $e');
      _error = 'Failed to load points: $e';
      notifyListeners();
    }
  }

  Future<bool> redeemReward(String rewardId, String userId) async {
    if (_isRedeeming) return false;

    _isRedeeming = true;
    notifyListeners();

    try {
      print('🎁 Redeeming reward $rewardId for user $userId');
      final success = await MockApiService.redeemRewardItem(userId, rewardId);

      if (success) {
        await fetchRewards();
        print('✅ Reward redeemed successfully');
        _isRedeeming = false;
        notifyListeners();
        return true;
      } else {
        print('❌ Failed to redeem reward');
        _error = 'Failed to redeem reward. Please try again.';
        _isRedeeming = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ Error redeeming reward: $e');
      _error = 'Redeem failed: $e';
      _isRedeeming = false;
      notifyListeners();
      return false;
    }
  }

  RewardItem? getRewardById(String rewardId) {
    try {
      return _rewards.firstWhere((reward) => reward.id == rewardId);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
