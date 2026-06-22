import '../models/staff_user.dart';
import 'api_service.dart';

class StaffService {
  StaffService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<StaffUser>> getStaff() async {
    final response = await _apiService.get('/staff');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid staff response.');
    }
    return data
        .whereType<Map>()
        .map((item) => StaffUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<StaffUser> createStaff({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String role,
    int? branchId,
  }) async {
    final response = await _apiService.post(
      '/staff',
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        'branch_id': branchId,
      },
    );
    return StaffUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<StaffUser> updateStaff(
    int id, {
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? role,
    int? branchId,
  }) async {
    final response = await _apiService.patch(
      '/staff/$id',
      data: {
        if (fullName != null) 'full_name': fullName.trim(),
        if (phone != null) 'phone': phone.trim(),
        if (email != null) 'email': email.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
        if (role != null) 'role': role,
        'branch_id': branchId,
      },
    );
    return StaffUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<StaffUser> activateStaff(int id) async {
    final response = await _apiService.patch('/staff/$id/activate');
    return StaffUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<StaffUser> deactivateStaff(int id) async {
    final response = await _apiService.patch('/staff/$id/deactivate');
    return StaffUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  }
}
