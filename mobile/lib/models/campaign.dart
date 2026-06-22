class Campaign {
  const Campaign({
    required this.id,
    required this.title,
    required this.description,
    required this.targetGroup,
    required this.createdAt,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.createdByUserId,
    this.updatedAt,
  });

  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final String targetGroup;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final int? createdByUserId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      targetGroup: json['target_group'] as String? ?? 'all_clients',
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      isActive: json['is_active'] as bool? ?? true,
      createdByUserId: json['created_by_user_id'] as int?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
