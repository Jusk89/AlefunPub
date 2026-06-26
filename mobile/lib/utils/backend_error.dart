import 'package:dio/dio.dart';

String backendErrorMessage(Object error, {String fallback = 'Ошибка запроса.'}) {
  if (error is StateError && error.message.isNotEmpty) {
    return error.message;
  }
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (error.response?.statusCode == 401) {
      return 'Сессия истекла. Войдите снова.';
    }
  }
  return fallback;
}

bool isUnauthorized(Object error) {
  return error is DioException && error.response?.statusCode == 401;
}
