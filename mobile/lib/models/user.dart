class User {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.createdAt,
    this.birthDate,
    this.qrCode,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final DateTime? birthDate;
  final String? qrCode;
  final DateTime createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'client',
      birthDate: _parseDate(json['birth_date']),
      qrCode: json['qr_code'] as String?,
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
