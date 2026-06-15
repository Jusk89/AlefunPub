import '../models/bonus_balance.dart';
import 'api_service.dart';

class BonusService {
  BonusService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  // The current backend in this workspace expects restaurant_id.
  // Set RESTAURANT_ID=0 if the deployed backend exposes a user-wide balance.
  static const int defaultRestaurantId = int.fromEnvironment(
    'RESTAURANT_ID',
    defaultValue: 1,
  );

  final ApiService _apiService;

  Future<BonusBalance> getBalance() async {
    final response = await _apiService.get(
      '/bonuses/balance',
      queryParameters: defaultRestaurantId > 0
          ? {'restaurant_id': defaultRestaurantId}
          : null,
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid bonus balance response.');
    }

    return BonusBalance.fromJson(Map<String, dynamic>.from(data));
  }
}
