class Address {
  final String id;
  final String userId;
  final String label;
  final String city;
  final String district;
  final String street;
  final String fullAddress;
  final String phoneNumber;
  final String? remarks;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.city,
    required this.district,
    required this.street,
    required this.fullAddress,
    required this.phoneNumber,
    this.remarks,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'].toString(),
      userId: json['userId'].toString(),
      label: json['label'] ?? 'Home',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      street: json['street'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      remarks: json['remarks'],
      isDefault: json['isDefault'] ?? false,
      latitude:
          json['latitude'] != null
              ? double.parse(json['latitude'].toString())
              : null,
      longitude:
          json['longitude'] != null
              ? double.parse(json['longitude'].toString())
              : null,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'label': label,
      'city': city,
      'district': district,
      'street': street,
      'fullAddress': fullAddress,
      'phoneNumber': phoneNumber,
      'remarks': remarks,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? city,
    String? district,
    String? street,
    String? fullAddress,
    String? phoneNumber,
    String? remarks,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      city: city ?? this.city,
      district: district ?? this.district,
      street: street ?? this.street,
      fullAddress: fullAddress ?? this.fullAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      remarks: remarks ?? this.remarks,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
