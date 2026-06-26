class Gift {
  const Gift({
    required this.id,
    required this.title,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.createdByUserId,
  });

  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isActive;
  final int? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Gift.fromJson(Map<String, dynamic> json) {
    return Gift(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdByUserId: json['created_by_user_id'] as int?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
