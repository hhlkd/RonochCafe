class RewardItem {
  final String id;
  final String name;
  final String imageUrl;
  final String type;
  final String color;
  final int point; // Note: This is "point" (singular) not "pointsRequired"

  RewardItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.color,
    required this.point,
  });

  factory RewardItem.fromJson(Map<String, dynamic> json) {
    return RewardItem(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: json['type'] ?? '',
      color: json['color'] ?? '',
      point:
          json['point'] is int
              ? json['point'] as int
              : int.tryParse(json['point']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'type': type,
      'color': color,
      'point': point,
    };
  }
}
