import 'package:flutter/material.dart';
import 'package:ronoch_coffee/models/reward_item_model.dart';
import 'package:ronoch_coffee/services/mockapi_service.dart';

class RewardProvider with ChangeNotifier {
  List<RewardItem> _rewards = [];
  bool _isLoading = false;
  String? _error;
  bool _isRedeeming = false;

  List<RewardItem> get rewards => _rewards;
  bool get isLoading => _isLoading;
  bool get isRedeeming => _isRedeeming;
  String? get error => _error;

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

  Future<bool> redeemReward(String rewardId, String userId) async {
    if (_isRedeeming) return false;

    _isRedeeming = true;
    notifyListeners();

    try {
      print('🎁 Redeeming reward $rewardId for user $userId');
      final success = await MockApiService.redeemRewardItem(userId, rewardId);

      if (success) {
        // Refresh rewards list
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

  // Get reward by ID
  RewardItem? getRewardById(String rewardId) {
    try {
      return _rewards.firstWhere((reward) => reward.id == rewardId);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
