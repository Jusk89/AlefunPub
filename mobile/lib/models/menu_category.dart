class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
  });

  final int id;
  final String name;
  final int sortOrder;
  final bool isActive;

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
