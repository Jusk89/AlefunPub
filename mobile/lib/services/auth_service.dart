import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';

class AuthService {
  AuthService({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(tokenStorage: tokenStorage),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    ) as Map<String, dynamic>;

    await _tokenStorage.saveToken(data['access_token'] as String);
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      '/auth/register',
      body: {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  Future<User> me() async {
    final data = await _apiClient.get('/auth/me', authorized: true) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<void> logout() {
    return _tokenStorage.clear();
  }
}
