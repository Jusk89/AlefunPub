import '../models/qr_client.dart';
import '../models/qr_order_result.dart';
import 'api_service.dart';

class QrService {
  QrService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<QrClient> lookupClient(String qrCode) async {
    final response = await _apiService.post(
      '/qr/lookup',
      data: {'qr_code': qrCode.trim()},
    );
    return QrClient.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<QrOrderResult> createOrderFromQr({
    required String qrCode,
    required int branchId,
    required double totalAmount,
    required String paymentMethod,
    required bool useBonuses,
  }) async {
    final response = await _apiService.post(
      '/orders/from-qr',
      data: {
        'qr_code': qrCode.trim(),
        'branch_id': branchId,
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'use_bonuses': useBonuses,
      },
    );
    return QrOrderResult.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
