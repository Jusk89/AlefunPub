import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, TokenStorage? tokenStorage})
      : _httpClient = httpClient ?? http.Client(),
        _tokenStorage = tokenStorage ?? const TokenStorage();

  final http.Client _httpClient;
  final TokenStorage _tokenStorage;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _headers({bool authorized = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authorized) {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String path, {bool authorized = false}) async {
    final response = await _httpClient.get(
      _uri(path),
      headers: await _headers(authorized: authorized),
    );
    return _decode(response);
  }

  Future<dynamic> post(
    String path, {
    required Map<String, dynamic> body,
    bool authorized = false,
  }) async {
    final response = await _httpClient.post(
      _uri(path),
      headers: await _headers(authorized: authorized),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final dynamic data = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    String message = 'Request failed';
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String) {
        message = detail;
      } else if (detail != null) {
        message = detail.toString();
      }
    }

    throw ApiException(message, response.statusCode);
  }
}
