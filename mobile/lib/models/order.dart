class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.bonusEarned,
    required this.bonusSpent,
    required this.finalAmount,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String status;
  final double totalAmount;
  final double bonusEarned;
  final double bonusSpent;
  final double finalAmount;
  final DateTime createdAt;
  final List<CustomerOrderItem> items;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return CustomerOrder(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '') ?? 0,
      bonusEarned: double.tryParse(json['bonus_earned']?.toString() ?? '') ?? 0,
      bonusSpent: double.tryParse(json['bonus_spent']?.toString() ?? '') ?? 0,
      finalAmount: double.tryParse(json['final_amount']?.toString() ?? '') ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => CustomerOrderItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList()
          : const [],
    );
  }
}

class CustomerOrderItem {
  const CustomerOrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  final int id;
  final String name;
  final double price;
  final int quantity;
  final double totalPrice;

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) {
    return CustomerOrderItem(
      id: json['id'] as int,
      name: json['name_snapshot'] as String? ?? '',
      price: double.tryParse(json['price_snapshot']?.toString() ?? '') ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0,
    );
  }
}
