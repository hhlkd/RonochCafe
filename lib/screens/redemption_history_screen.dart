// lib/screens/redemption_history_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ronoch_coffee/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ronoch_coffee/provider/user_provider.dart';
import 'package:ronoch_coffee/models/redemption_record_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RedemptionHistoryScreen extends StatefulWidget {
  const RedemptionHistoryScreen({super.key});

  @override
  State<RedemptionHistoryScreen> createState() =>
      _RedemptionHistoryScreenState();
}

class _RedemptionHistoryScreenState extends State<RedemptionHistoryScreen> {
  List<RedemptionRecord> _redemptions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRedemptions();
  }

  Future<void> _loadRedemptions() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<RedemptionRecord> get _filteredRedemptions {
    switch (_selectedFilter) {
      case 'pending':
        return _redemptions.where((r) => r.isPending).toList();
      case 'used':
        return _redemptions.where((r) => r.isUsed).toList();
      case 'expired':
        return _redemptions.where((r) => r.isExpired).toList();
      default:
        return _redemptions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Rewards',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D2D2D),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D2D2D)),
        actions: [
          if (!_isLoading && _redemptions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFFB08968)),
              onPressed: _loadRedemptions,
            ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildContent(user),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Color(0xFFB08968)),
          const SizedBox(height: 20),
          Text(
            'Loading your rewards...',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(User? user) {
    if (user == null) {
      return _buildEmptyState('Please login to view rewards');
    }

    if (_redemptions.isEmpty) {
      return _buildEmptyState('No rewards redeemed yet');
    }

    return Column(
      children: [
        _buildStatsCard(),
        _buildFilterRow(),
        Expanded(child: _buildRewardsList()),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F5F0),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.card_giftcard,
                size: 60,
                color: Color(0xFFB08968),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Redeem rewards in your account',
              style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB08968),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Browse Rewards',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    final pending = _redemptions.where((r) => r.isPending).length;
    final used = _redemptions.where((r) => r.isUsed).length;
    final totalPoints = _redemptions.fold<int>(
      0,
      (sum, r) => sum + r.pointsUsed,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8F0E5), Color(0xFFF5E6D3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.05),
            blurRadius: 20,
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
                Text(
                  'Rewards Summary',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_redemptions.length} Items',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pending pending • $used collected',
                  style: TextStyle(fontSize: 13, color: Colors.brown.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.brown.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB74D),
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  totalPoints.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D4037),
                  ),
                ),
                Text(
                  'points spent',
                  style: TextStyle(fontSize: 10, color: Colors.brown.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    final filters = [
      {'value': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
      {'value': 'pending', 'label': 'Pending', 'icon': Icons.pending_actions},
      {'value': 'used', 'label': 'Collected', 'icon': Icons.check_circle},
      {'value': 'expired', 'label': 'Expired', 'icon': Icons.timer_off},
    ];

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == (filter['value'] as String);

          return GestureDetector(
            onTap:
                () =>
                    setState(() => _selectedFilter = filter['value'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFB08968) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected
                          ? const Color(0xFFB08968)
                          : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: const Color(0xFFB08968).withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : const Color(0xFFB08968),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected ? Colors.white : const Color(0xFF5D4037),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsList() {
    final filtered = _filteredRedemptions;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_alt_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No ${_selectedFilter} rewards',
              style: const TextStyle(fontSize: 16, color: Color(0xFF999999)),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedFilter = 'all'),
              child: const Text(
                'Show All Rewards',
                style: TextStyle(color: Color(0xFFB08968)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRedemptions,
      backgroundColor: Colors.white,
      color: const Color(0xFFB08968),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final redemption = filtered[index];
          return _buildRewardCard(redemption);
        },
      ),
    );
  }

  Widget _buildRewardCard(RedemptionRecord redemption) {
    final daysRemaining = redemption.daysRemaining;
    final isUsed = redemption.isUsed;
    final isValid = redemption.isValid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showRewardDetails(redemption),
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(redemption),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusDotColor(redemption),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(redemption),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusTextColor(redemption),
                          ),
                        ),
                        const Spacer(),
                        if (isValid && daysRemaining <= 7 && daysRemaining > 0)
                          Row(
                            children: [
                              Icon(
                                Icons.timer,
                                size: 12,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$daysRemaining days left',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        if (isUsed)
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                      ],
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reward Image
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F5F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child:
                              redemption.rewardImage.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
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
                                              size: 32,
                                            ),
                                          ),
                                    ),
                                  )
                                  : Center(
                                    child: Icon(
                                      Icons.card_giftcard,
                                      color: Colors.brown.shade300,
                                      size: 32,
                                    ),
                                  ),
                        ),

                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                redemption.rewardName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D2D2D),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 8),

                              // Points
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber.shade700,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${redemption.pointsUsed} pts',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Date
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'MMM dd',
                                    ).format(redemption.redeemedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Redemption Code
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Redemption Code',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      redemption.redemptionCode,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isValid
                                                ? const Color(0xFF4CAF50)
                                                : Colors.grey.shade500,
                                        letterSpacing: 1.5,
                                        fontFamily: 'Monospace',
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

                  // Action Buttons
                  if (isValid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showRewardDetails(redemption),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFF666666),
                              ),
                              label: const Text(
                                'View Details',
                                style: TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showCollectDialog(redemption),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB08968),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Mark Collected',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(RedemptionRecord record) {
    if (record.isExpired) return Colors.grey.shade100;
    if (record.isUsed) return Colors.green.shade50;
    if (record.isPending) return Colors.orange.shade50;
    return Colors.blue.shade50;
  }

  Color _getStatusDotColor(RedemptionRecord record) {
    if (record.isExpired) return Colors.grey;
    if (record.isUsed) return Colors.green;
    if (record.isPending) return Colors.orange;
    return Colors.blue;
  }

  String _getStatusText(RedemptionRecord record) {
    if (record.isExpired) return 'EXPIRED';
    if (record.isUsed) return 'COLLECTED';
    if (record.isPending) return 'PENDING PICKUP';
    return 'READY FOR PICKUP';
  }

  Color _getStatusTextColor(RedemptionRecord record) {
    if (record.isExpired) return Colors.grey.shade600;
    if (record.isUsed) return Colors.green.shade700;
    if (record.isPending) return Colors.orange.shade700;
    return Colors.blue.shade700;
  }

  void _showRewardDetails(RedemptionRecord redemption) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildRewardDetailsSheet(redemption),
    );
  }

  Widget _buildRewardDetailsSheet(RedemptionRecord redemption) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Reward Header
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F5F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    redemption.rewardImage.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: redemption.rewardImage,
                            fit: BoxFit.cover,
                          ),
                        )
                        : Center(
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.brown.shade300,
                            size: 28,
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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${redemption.pointsUsed} points',
                          style: TextStyle(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Redemption Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8F0E5), Color(0xFFF5E6D3)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0D1BA)),
            ),
            child: Column(
              children: [
                const Text(
                  'REDEMPTION CODE',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8B6B4D),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  redemption.redemptionCode,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5D4037),
                    letterSpacing: 2,
                    fontFamily: 'Monospace',
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Show this code at Ronoch Café to claim your reward',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF8B6B4D)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Details Grid
          const Text(
            'Reward Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D2D2D),
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
            children: [
              _buildDetailItem(
                icon: Icons.calendar_today,
                label: 'Redeemed',
                value: DateFormat('MMM dd, yyyy').format(redemption.redeemedAt),
              ),
              _buildDetailItem(
                icon: Icons.event_available,
                label: 'Valid Until',
                value: DateFormat('MMM dd, yyyy').format(redemption.validUntil),
              ),
              _buildDetailItem(
                icon: Icons.location_on,
                label: 'Location',
                value: 'Phnom Penh',
              ),
              _buildDetailItem(
                icon: Icons.timer,
                label: 'Status',
                value: _getStatusText(redemption),
                valueColor: _getStatusTextColor(redemption),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB08968),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: valueColor ?? const Color(0xFF2D2D2D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectDialog(RedemptionRecord redemption) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Mark as Collected?',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D2D2D),
              ),
            ),
            content: const Text(
              'Have you collected this reward at our café? This will mark it as collected in your history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF666666)),
                ),
              ),
              ElevatedButton(
                onPressed: () => _markAsCollected(redemption),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB08968),
                ),
                child: const Text('Yes, Collected'),
              ),
            ],
          ),
    );
  }

  Future<void> _markAsCollected(RedemptionRecord redemption) async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    Navigator.pop(context); // Close dialog

    // Update local state
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

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      final data = _redemptions.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList('user_redemptions_${user.id}', data);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reward marked as collected!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
