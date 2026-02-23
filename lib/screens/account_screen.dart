import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:ronoch_coffee/models/reward_item_model.dart';
import 'package:ronoch_coffee/models/user_model.dart';
import 'package:ronoch_coffee/provider/reward_provider.dart';
import 'package:ronoch_coffee/provider/user_provider.dart';
import 'package:ronoch_coffee/models/redemption_record_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _profileImageBase64;
  String? _currentUserId;
  bool _isRedeeming = false;
  List<RedemptionRecord> _redemptions = [];
  bool _loadingRedemptions = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.currentUser == null) {
      await userProvider.loadUserFromSession();
    }

    _checkUserStatusAndLoadImage();
    _loadRedemptions();

    final rewardProvider = Provider.of<RewardProvider>(context, listen: false);
    if (rewardProvider.rewards.isEmpty) {
      rewardProvider.fetchRewards();
    }
  }

  Future<void> _checkUserStatusAndLoadImage() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;

    if (user == null) {
      setState(() {
        _profileImageBase64 = null;
        _currentUserId = null;
      });
      return;
    }

    if (user.id != _currentUserId) {
      _currentUserId = user.id;
      await _loadLocalProfileImage(user.id);
    }
  }

  Future<void> _loadLocalProfileImage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final base64String = prefs.getString('profile_image_$userId');

      if (mounted) {
        setState(() {
          _profileImageBase64 = base64String;
        });
      }
    } catch (e) {
      print('Error loading local image: $e');
      if (mounted) {
        setState(() {
          _profileImageBase64 = null;
        });
      }
    }
  }

  Future<void> _loadRedemptions() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user == null) return;

    setState(() => _loadingRedemptions = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final redemptionData =
          prefs.getStringList('user_redemptions_${user.id}') ?? [];

      final List<RedemptionRecord> loaded =
          redemptionData
              .map((json) => RedemptionRecord.fromJson(jsonDecode(json)))
              .toList();

      loaded.sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));

      setState(() {
        _redemptions = loaded;
        _loadingRedemptions = false;
      });
    } catch (e) {
      setState(() => _loadingRedemptions = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = userProvider.currentUser;

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Updating profile...'),
              backgroundColor: Color(0xFFB08968),
            ),
          );

          final bytes = await pickedFile.readAsBytes();
          final base64String = base64Encode(bytes);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('profile_image_${user.id}', base64String);

          setState(() {
            _profileImageBase64 = base64String;
          });
          final avatarUrl =
              'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.username)}&background=B08968&color=fff&size=200';
          final updatedUser = user.copyWith(profileImage: avatarUrl);
          await userProvider.updateProfile(updatedUser);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final rewardProvider = Provider.of<RewardProvider>(context);

    if (userProvider.isLoading) {
      return _buildLoadingScreen();
    }

    if (userProvider.error != null) {
      return _buildErrorScreen(userProvider.error!);
    }

    if (!userProvider.isLoggedIn || userProvider.currentUser == null) {
      return _buildNoUserScreen();
    }

    return _buildMainScreen(userProvider, rewardProvider);
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB08968)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Loading your account...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  userProvider.loadUserFromSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB08968),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoUserScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 80,
                color: Color(0xFFB08968),
              ),
              const SizedBox(height: 20),
              const Text(
                'Not Logged In',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'You need to log in to view your account',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB08968),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainScreen(
    UserProvider userProvider,
    RewardProvider rewardProvider,
  ) {
    final user = userProvider.currentUser!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFB08968)),
            onPressed: () async {
              await userProvider.refreshUser();
              if (rewardProvider.rewards.isEmpty) {
                await rewardProvider.fetchRewards();
              }
              await _loadLocalProfileImage(user.id);
              await _loadRedemptions();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              bool confirm = await showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                      ],
                    ),
              );
              if (confirm) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('profile_image_${user.id}');
                setState(() {
                  _profileImageBase64 = null;
                  _currentUserId = null;
                });
                await userProvider.logout();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: FocusDetector(
        onFocusGained: () async {
          final user = userProvider.currentUser;
          if (user != null) {
            await userProvider.refreshUser();
            await _loadLocalProfileImage(user.id);
          }
        },
        child: Column(
          children: [
            _buildProfileHeader(user),
            _buildTabBar(),
            Expanded(
              child:
                  _selectedTab == 0
                      ? _buildRewardsContent(rewardProvider, user)
                      : _buildRedemptionHistoryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFF5F5F5),
                  backgroundImage: _getProfileImage(user),
                  child:
                      _shouldShowDefaultIcon(user)
                          ? const Icon(
                            Icons.person,
                            size: 45,
                            color: Color(0xFFB08968),
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFB08968),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Column(
            children: [
              const Text(
                "Welcome,",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "View info",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB08968),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFFB08968),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser!;
              return _buildPointsCard(user.point);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(int points) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB08968), Color(0xFF8B6B4D)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB08968).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ronoch Café",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "When Life Hurt, Coffee Heals!",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Points Balance",
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              points.toString(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
      ),
      child: Row(
        children: [
          _buildTabButton(0, Icons.card_giftcard, 'Rewards'),
          _buildTabButton(1, Icons.history, 'History'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int tabIndex, IconData icon, String label) {
    final isSelected = _selectedTab == tabIndex;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = tabIndex),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color:
                      isSelected ? const Color(0xFFB08968) : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFFB08968) : Colors.grey,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? const Color(0xFFB08968) : Colors.grey,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardsContent(RewardProvider rewardProvider, User user) {
    return RefreshIndicator(
      onRefresh: () async {
        await rewardProvider.fetchRewards();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Redeem Rewards",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Earn points by ordering and redeem them for exclusive items",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            _buildRewardsGrid(rewardProvider, user),
          ],
        ),
      ),
    );
  }

  Widget _buildRedemptionHistoryContent() {
    return RefreshIndicator(
      onRefresh: _loadRedemptions,
      child:
          _loadingRedemptions
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFB08968)),
              )
              : _redemptions.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.card_giftcard,
                      size: 80,
                      color: Color(0xFFE0E0E0),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Redemptions Yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Redeem rewards to see them here',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () => setState(() => _selectedTab = 0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB08968),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Browse Rewards',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _redemptions.length,
                itemBuilder: (context, index) {
                  final redemption = _redemptions[index];
                  return _buildRedemptionHistoryItem(redemption);
                },
              ),
    );
  }

  Widget _buildRedemptionHistoryItem(RedemptionRecord redemption) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    redemption.rewardImage.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: redemption.rewardImage,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.brown.shade300,
                                  ),
                                ),
                            errorWidget:
                                (context, url, error) => Center(
                                  child: Icon(
                                    Icons.card_giftcard,
                                    color: Colors.brown.shade300,
                                    size: 24,
                                  ),
                                ),
                          ),
                        )
                        : Center(
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.brown.shade300,
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
                      redemption.rewardName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(redemption).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getStatusColor(redemption),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            redemption.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(redemption),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd').format(redemption.redeemedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.qr_code,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              redemption.redemptionCode,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4CAF50),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showQRCodeDialog(redemption),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFB08968).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.fullscreen,
                                size: 16,
                                color: Color(0xFFB08968),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${redemption.pointsUsed}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (redemption.isUsed)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Collected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (redemption.isValid)
                    ElevatedButton(
                      onPressed: () => _markAsCollected(redemption),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB08968),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Collect',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showDeleteConfirmDialog(redemption),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear Item'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showDeleteConfirmDialog(RedemptionRecord redemption) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 60,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clear Item',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to remove "${redemption.rewardName}" from your history?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _deleteRedemption(redemption);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _showRedemptionSuccess(
    RewardItem reward,
    String code,
    UserProvider userProvider,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Redemption Successful!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '🎉 Congratulations!',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    reward.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFB08968)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your Redemption Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Save this code!',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bring this code to our café in Cambodia to claim your reward.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB08968),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Confirm ',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Redemption Failed',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB08968),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showQRCodeDialog(RedemptionRecord redemption) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Redemption QR Code',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: redemption.redemptionCode,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Redemption Code',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          redemption.redemptionCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4CAF50),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          redemption.rewardName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Points: ${redemption.pointsUsed}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(redemption).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _getStatusColor(redemption),
                            ),
                          ),
                          child: Text(
                            redemption.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getStatusColor(redemption),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB08968),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _deleteRedemption(RedemptionRecord redemption) async {
    try {
      _redemptions.removeWhere(
        (r) => r.redemptionCode == redemption.redemptionCode,
      );

      if (_currentUserId != null) {
        final prefs = await SharedPreferences.getInstance();
        final key = 'user_redemptions_$_currentUserId';
        final redemptionList =
            _redemptions.map((r) => json.encode(r.toJson())).toList();
        await prefs.setStringList(key, redemptionList);
      }

      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reward removed from history'),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to remove reward'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(RedemptionRecord record) {
    if (record.isExpired) return Colors.grey;
    if (record.isUsed) return Colors.green;
    if (record.isPending) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildRewardsGrid(RewardProvider rewardProvider, User user) {
    if (rewardProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB08968)),
          ),
        ),
      );
    }

    if (rewardProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                rewardProvider.error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => rewardProvider.fetchRewards(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB08968),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (rewardProvider.rewards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.card_giftcard, size: 60, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'No rewards available',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: rewardProvider.rewards.length,
      itemBuilder: (context, index) {
        final reward = rewardProvider.rewards[index];
        return _buildRewardItem(reward, user);
      },
    );
  }

  Widget _buildRewardItem(RewardItem reward, User user) {
    bool canRedeem = user.point >= reward.point;

    return GestureDetector(
      onTap:
          () =>
              canRedeem && !_isRedeeming
                  ? _showRedeemDialog(reward, user)
                  : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(canRedeem ? 0.08 : 0.03),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color:
                canRedeem
                    ? const Color(0xFFB08968).withOpacity(0.3)
                    : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                child:
                    reward.imageUrl.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            reward.imageUrl,
                            fit: BoxFit.contain,
                          ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.card_giftcard,
                            size: 60,
                            color: Color(0xFFB08968),
                          ),
                        ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    canRedeem ? const Color(0xFFF9F9F9) : Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    reward.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: canRedeem ? Colors.black : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star,
                        color:
                            canRedeem ? const Color(0xFFFFB74D) : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${reward.point} pts",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              canRedeem ? const Color(0xFFB08968) : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color:
                          canRedeem
                              ? const Color(0xFFB08968)
                              : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          canRedeem
                              ? "Redeem Now"
                              : "Need ${reward.point - user.point} pts",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRedeemDialog(RewardItem reward, User user) async {
    if (user.point < reward.point) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You need ${reward.point - user.point} more points!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final previewCode = _generateRedemptionCode();

    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFB08968).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child:
                            reward.imageUrl.isNotEmpty
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    reward.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.card_giftcard,
                                              size: 40,
                                              color: Color(0xFFB08968),
                                            ),
                                  ),
                                )
                                : const Icon(
                                  Icons.card_giftcard,
                                  size: 40,
                                  color: Color(0xFFB08968),
                                ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      reward.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB08968).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFB08968),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${reward.point} pts',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB08968),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Your balance',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                '${user.point} pts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      user.point >= reward.point
                                          ? Colors.green
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You will receive a unique code to pick up at our café.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Preview Code',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  previewCode,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4CAF50),
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.copy,
                                size: 18,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code copied!')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, null),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                () => Navigator.pop(context, previewCode),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB08968),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Redeem',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
    );

    if (result != null && mounted) {
      await _processRedemption(reward, user, redemptionCode: result);
    }
  }

  Future<void> _processRedemption(
    RewardItem reward,
    User user, {
    String? redemptionCode,
  }) async {
    setState(() {
      _isRedeeming = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    Provider.of<RewardProvider>(context, listen: false);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFB08968)),
                ),
              ),
            ),
      );

      final code = redemptionCode ?? _generateRedemptionCode();

      final redemptionRecord = RedemptionRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.id,
        rewardId: reward.id,
        rewardName: reward.name,
        rewardImage: reward.imageUrl,
        pointsUsed: reward.point,
        redemptionCode: code,
        status: 'pending',
        redeemedAt: DateTime.now(),
        validUntil: DateTime.now().add(const Duration(days: 30)),
        pickupLocation: 'Ronoch Café, Phnom Penh, Cambodia',
      );

      final prefs = await SharedPreferences.getInstance();
      final redemptions =
          prefs.getStringList('user_redemptions_${user.id}') ?? [];
      redemptions.add(jsonEncode(redemptionRecord.toJson()));
      await prefs.setStringList('user_redemptions_${user.id}', redemptions);

      final newPoints = user.point - reward.point;
      final updatedUser = user.copyWith(point: newPoints);
      await userProvider.updateProfile(updatedUser);

      Navigator.pop(context);

      await _showRedemptionSuccess(reward, code, userProvider);
      await _loadRedemptions();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorDialog("Redemption failed: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRedeeming = false;
        });
      }
    }
  }

  String _generateRedemptionCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'RON${timestamp.toString().substring(8)}${random}';
  }

  Future<void> _markAsCollected(RedemptionRecord redemption) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user == null) return;

    try {
      final index = _redemptions.indexWhere((r) => r.id == redemption.id);
      if (index != -1) {
        final updated = redemption.copyWith(
          status: 'used',
          collectedAt: DateTime.now(),
          collectedBy: 'User',
        );

        setState(() {
          _redemptions[index] = updated;
        });

        final prefs = await SharedPreferences.getInstance();
        final data = _redemptions.map((r) => jsonEncode(r.toJson())).toList();
        await prefs.setStringList('user_redemptions_${user.id}', data);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reward marked as collected!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider? _getProfileImage(User user) {
    try {
      if (_profileImageBase64 != null && _profileImageBase64!.isNotEmpty) {
        return MemoryImage(base64Decode(_profileImageBase64!));
      }
    } catch (e) {
      print('Error decoding profile image: $e');
      _profileImageBase64 = null;
    }

    if (user.profileImage.isNotEmpty && user.profileImage.startsWith('http')) {
      return NetworkImage(user.profileImage);
    }
    return null;
  }

  bool _shouldShowDefaultIcon(User user) {
    return _profileImageBase64 == null &&
        (user.profileImage.isEmpty || !user.profileImage.startsWith('http'));
  }
}
