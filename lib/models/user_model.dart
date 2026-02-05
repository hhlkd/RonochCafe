class User {
  final String id;
  final String username;
  final String email;
  final String phone;
  final String password;
  final String address;
  final String profileImage;
  final int point;
  final String createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.address,
    required this.profileImage,
    required this.point,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      address: json['address'] ?? '',
      profileImage: json['profileImage'] ?? '',
      point:
          json['point'] is int
              ? json['point'] as int
              : int.tryParse(json['point']?.toString() ?? '0') ?? 0,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone': phone,
      'password': password,
      'address': address,
      'profileImage': profileImage,
      'point': point,
      'createdAt': createdAt,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? phone,
    String? password,
    String? address,
    String? profileImage,
    int? point,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
      point: point ?? this.point,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
