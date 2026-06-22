import '../models/order.dart';
import 'api_service.dart';

class OrderService {
  OrderService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<CustomerOrder>> getMyOrders() async {
    final response = await _apiService.get('/orders/my');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid orders response.');
    }

    return data
        .whereType<Map>()
        .map((item) => CustomerOrder.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
