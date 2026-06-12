class User {
  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.role,
    required this.qrCode,
  });

  final int id;
  final String fullName;
  final String phone;
  final String email;
  final String role;
  final String? qrCode;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      qrCode: json['qr_code'] as String?,
    );
  }
}
