// lib/models/redemption_history_model.dart
import 'package:ronoch_coffee/models/redemption_record_model.dart';

class RedemptionHistory {
  final List<RedemptionRecord> records;
  final int total;
  final int pendingCount;
  final int usedCount;
  final int expiredCount;

  RedemptionHistory({
    required this.records,
    required this.total,
    required this.pendingCount,
    required this.usedCount,
    required this.expiredCount,
  });

  factory RedemptionHistory.fromJson(List<dynamic> jsonList) {
    final records =
        jsonList.map((json) => RedemptionRecord.fromJson(json)).toList();

    final pendingCount = records.where((r) => r.isPending).length;
    final usedCount = records.where((r) => r.isUsed).length;
    final expiredCount = records.where((r) => r.isExpired).length;

    return RedemptionHistory(
      records: records,
      total: records.length,
      pendingCount: pendingCount,
      usedCount: usedCount,
      expiredCount: expiredCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'records': records.map((r) => r.toJson()).toList(),
      'total': total,
      'pendingCount': pendingCount,
      'usedCount': usedCount,
      'expiredCount': expiredCount,
    };
  }
}
