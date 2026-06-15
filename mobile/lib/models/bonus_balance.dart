class BonusBalance {
  const BonusBalance({
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
  });

  final double balance;
  final double totalEarned;
  final double totalSpent;

  factory BonusBalance.fromJson(Map<String, dynamic> json) {
    return BonusBalance(
      balance: _readAmount(json['balance']),
      totalEarned: _readAmount(json['total_earned']),
      totalSpent: _readAmount(json['total_spent']),
    );
  }

  static double _readAmount(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
