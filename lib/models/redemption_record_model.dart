class RedemptionRecord {
  final String id;
  final String userId;
  final String rewardId;
  final String rewardName;
  final String rewardImage;
  final int pointsUsed;
  final String redemptionCode;
  final String status; // pending, used, expired
  final DateTime redeemedAt;
  final DateTime validUntil;
  final String pickupLocation;
  final DateTime? collectedAt;
  final String? collectedBy;
  final String? notes;

  RedemptionRecord({
    required this.id,
    required this.userId,
    required this.rewardId,
    required this.rewardName,
    required this.rewardImage,
    required this.pointsUsed,
    required this.redemptionCode,
    required this.status,
    required this.redeemedAt,
    required this.validUntil,
    required this.pickupLocation,
    this.collectedAt,
    this.collectedBy,
    this.notes,
  });

  factory RedemptionRecord.fromJson(Map<String, dynamic> json) {
    return RedemptionRecord(
      id:
          json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      userId: json['userId']?.toString() ?? '',
      rewardId:
          json['rewardId']?.toString() ??
          json['rewardItemId']?.toString() ??
          '',
      rewardName: json['rewardName']?.toString() ?? 'Reward',
      rewardImage:
          json['rewardImage']?.toString() ?? json['imageUrl']?.toString() ?? '',
      pointsUsed:
          json['pointsUsed'] ?? json['point'] ?? json['pointsUsed'] ?? 0,
      redemptionCode: json['redemptionCode']?.toString() ?? _generateCode(),
      status: json['status']?.toString() ?? 'pending',
      redeemedAt:
          json['redeemedAt'] != null
              ? DateTime.parse(json['redeemedAt'].toString())
              : DateTime.now(),
      validUntil:
          json['validUntil'] != null
              ? DateTime.parse(json['validUntil'].toString())
              : DateTime.now().add(const Duration(days: 30)),
      pickupLocation:
          json['pickupLocation']?.toString() ??
          'Ronoch Café, Phnom Penh, Cambodia',
      collectedAt:
          json['collectedAt'] != null
              ? DateTime.parse(json['collectedAt'].toString())
              : null,
      collectedBy: json['collectedBy']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  static String _generateCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'RON${timestamp.toString().substring(8)}${random}';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'rewardId': rewardId,
      'rewardName': rewardName,
      'rewardImage': rewardImage,
      'pointsUsed': pointsUsed,
      'redemptionCode': redemptionCode,
      'status': status,
      'redeemedAt': redeemedAt.toIso8601String(),
      'validUntil': validUntil.toIso8601String(),
      'pickupLocation': pickupLocation,
      'collectedAt': collectedAt?.toIso8601String(),
      'collectedBy': collectedBy,
      'notes': notes,
    };
  }

  RedemptionRecord copyWith({
    String? id,
    String? userId,
    String? rewardId,
    String? rewardName,
    String? rewardImage,
    int? pointsUsed,
    String? redemptionCode,
    String? status,
    DateTime? redeemedAt,
    DateTime? validUntil,
    String? pickupLocation,
    DateTime? collectedAt,
    String? collectedBy,
    String? notes,
  }) {
    return RedemptionRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      rewardId: rewardId ?? this.rewardId,
      rewardName: rewardName ?? this.rewardName,
      rewardImage: rewardImage ?? this.rewardImage,
      pointsUsed: pointsUsed ?? this.pointsUsed,
      redemptionCode: redemptionCode ?? this.redemptionCode,
      status: status ?? this.status,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      validUntil: validUntil ?? this.validUntil,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      collectedAt: collectedAt ?? this.collectedAt,
      collectedBy: collectedBy ?? this.collectedBy,
      notes: notes ?? this.notes,
    );
  }

  // Helper methods
  bool get isExpired => validUntil.isBefore(DateTime.now());
  bool get isUsed => status == 'used';
  bool get isValid => !isExpired && !isUsed;
  bool get isPending => status == 'pending';

  String get formattedRedeemedDate {
    return "${redeemedAt.day}/${redeemedAt.month}/${redeemedAt.year}";
  }

  String get formattedValidUntilDate {
    return "${validUntil.day}/${validUntil.month}/${validUntil.year}";
  }

  int get daysRemaining {
    final now = DateTime.now();
    final difference = validUntil.difference(now);
    return difference.inDays;
  }
}
