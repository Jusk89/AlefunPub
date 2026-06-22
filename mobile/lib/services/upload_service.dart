import 'package:dio/dio.dart';

import 'api_service.dart';

class UploadService {
  UploadService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<String> uploadImage({
    required String filePath,
    required String folder,
  }) async {
    final response = await _apiService.postForm(
      '/upload/image',
      data: FormData.fromMap({
        'folder': folder,
        'file': await MultipartFile.fromFile(filePath),
      }),
    );

    final data = response.data;
    if (data is Map && data['image_url'] is String) {
      return data['image_url'] as String;
    }
    throw const FormatException('Invalid image upload response.');
  }
}
