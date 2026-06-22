class StaffUser {
  const StaffUser({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.branchId,
    this.lastLoginAt,
    this.createdByUserId,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final int? branchId;
  final bool isActive;
  final DateTime? lastLoginAt;
  final int? createdByUserId;
  final DateTime createdAt;

  factory StaffUser.fromJson(Map<String, dynamic> json) {
    return StaffUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role'] as String? ?? 'cashier',
      branchId: json['branch_id'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      lastLoginAt: _parseDate(json['last_login_at']),
      createdByUserId: json['created_by_user_id'] as int?,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
