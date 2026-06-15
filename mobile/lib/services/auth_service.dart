import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  AuthService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<void> login(String email, String password) async {
    final response = await _apiService.post(
      '/auth/login',
      data: {
        'email': email.trim(),
        'password': password,
      },
    );

    final token = _extractToken(response.data);
    await ApiService.saveToken(token);
  }

  Future<bool> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String birthDate,
  }) async {
    final response = await _apiService.post(
      '/auth/register',
      data: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'birth_date': birthDate.trim(),
      },
    );

    final data = response.data;
    if (data is Map && data['access_token'] is String) {
      await ApiService.saveToken(data['access_token'] as String);
      return true;
    }

    return false;
  }

  Future<User> getMe() async {
    final response = await _apiService.get('/auth/me');
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Invalid user response.');
    }

    return User.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> logout() {
    return ApiService.clearToken();
  }

  Future<bool> isLoggedIn() {
    return ApiService.hasToken();
  }

  String _extractToken(Object? data) {
    if (data is Map && data['access_token'] is String) {
      return data['access_token'] as String;
    }

    throw const FormatException('Token not found in auth response.');
  }
}
