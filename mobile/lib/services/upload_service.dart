import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class UploadService {
  UploadService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<String> uploadImage({
    required String filePath,
    required String folder,
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    return _uploadMultipart(
      folder: folder,
      file: await MultipartFile.fromFile(filePath, filename: fileName),
    );
  }

  Future<String> uploadPickedImage({
    required XFile image,
    required String folder,
  }) async {
    final fileName = image.name.isNotEmpty
        ? image.name
        : image.path.split(RegExp(r'[\\/]')).last;
    final file = kIsWeb
        ? MultipartFile.fromBytes(await image.readAsBytes(), filename: fileName)
        : await MultipartFile.fromFile(image.path, filename: fileName);
    return _uploadMultipart(folder: folder, file: file);
  }

  Future<String> _uploadMultipart({
    required String folder,
    required MultipartFile file,
  }) async {
    final response = await _apiService.postForm(
      '/upload/image',
      data: FormData.fromMap({
        'folder': folder,
        'file': file,
      }),
    );

    final data = response.data;
    if (data is Map && data['image_url'] is String) {
      return data['image_url'] as String;
    }
    throw const FormatException('Invalid image upload response.');
  }
}
