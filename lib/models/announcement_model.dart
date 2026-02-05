class Announcement {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String validUntil;
  final bool isActive;
  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.validUntil,
    this.isActive = true,
  });
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      validUntil: json['validUntil'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'validUntil': validUntil,
      'isActive': isActive,
    };
  }
}
