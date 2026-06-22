class QrOrderResult {
  const QrOrderResult({
    required this.orderId,
    required this.clientFullName,
    required this.totalAmount,
    required this.bonusSpent,
    required this.bonusEarned,
    required this.finalAmount,
    required this.newBonusBalance,
  });

  final int orderId;
  final String clientFullName;
  final double totalAmount;
  final double bonusSpent;
  final double bonusEarned;
  final double finalAmount;
  final double newBonusBalance;

  factory QrOrderResult.fromJson(Map<String, dynamic> json) {
    return QrOrderResult(
      orderId: json['order_id'] as int,
      clientFullName: json['client_full_name'] as String? ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      bonusSpent: double.tryParse(json['bonus_spent']?.toString() ?? '') ?? 0,
      bonusEarned: double.tryParse(json['bonus_earned']?.toString() ?? '') ?? 0,
      finalAmount: double.tryParse(json['final_amount']?.toString() ?? '') ?? 0,
      newBonusBalance:
          double.tryParse(json['new_bonus_balance']?.toString() ?? '') ?? 0,
    );
  }
}
