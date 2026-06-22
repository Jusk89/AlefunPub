import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class OrdersProvider extends ChangeNotifier {
  OrdersProvider({OrderService? orderService})
      : _orderService = orderService ?? OrderService();

  final OrderService _orderService;

  bool _isLoading = false;
  String? _errorMessage;
  List<CustomerOrder> _orders = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<CustomerOrder> get orders => List.unmodifiable(_orders);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderService.getMyOrders();
    } catch (_) {
      _errorMessage = 'Не удалось загрузить заказы';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
