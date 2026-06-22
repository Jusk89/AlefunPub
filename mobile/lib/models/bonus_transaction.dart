class BonusTransaction {
  const BonusTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.orderId,
  });

  final int id;
  final String type;
  final double amount;
  final int? orderId;
  final DateTime createdAt;

  factory BonusTransaction.fromJson(Map<String, dynamic> json) {
    return BonusTransaction(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      orderId: json['order_id'] as int?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  bool get isEarned => type == 'earn' || type == 'earned';
  bool get isSpent => type == 'spend' || type == 'spent';

  String get displayType {
    if (isEarned) {
      return 'earned';
    }
    if (isSpent) {
      return 'spent';
    }
    if (type == 'expire') {
      return 'expired';
    }
    return type.isEmpty ? 'manual' : type;
  }
}
