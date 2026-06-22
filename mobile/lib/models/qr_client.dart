class QrClient {
  const QrClient({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.currentBonusBalance,
  });

  final int id;
  final String fullName;
  final String phone;
  final double currentBonusBalance;

  factory QrClient.fromJson(Map<String, dynamic> json) {
    return QrClient(
      id: json['id'] as int,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      currentBonusBalance:
          double.tryParse(json['current_bonus_balance']?.toString() ?? '') ?? 0,
    );
  }
}
