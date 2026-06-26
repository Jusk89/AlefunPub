import '../models/gift.dart';
import 'api_service.dart';

class GiftService {
  GiftService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<Gift>> getMyUnusedGifts() async {
    final response = await _apiService.get('/gifts/my');
    return _parseGiftList(response.data);
  }

  Future<List<Gift>> getGifts() async {
    final response = await _apiService.get('/gifts');
    return _parseGiftList(response.data);
  }

  Future<Gift> createGift({
    required String title,
    required String description,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final response = await _apiService.post(
      '/gifts',
      data: _payload(
        title: title,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
      ),
    );
    return Gift.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Gift> updateGift(
    int id, {
    required String title,
    required String description,
    String? imageUrl,
    bool isActive = true,
  }) async {
    final response = await _apiService.patch(
      '/gifts/$id',
      data: _payload(
        title: title,
        description: description,
        imageUrl: imageUrl,
        isActive: isActive,
      ),
    );
    return Gift.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteGift(int id) async {
    await _apiService.delete('/gifts/$id');
  }

  Future<void> useGift(int id) async {
    await _apiService.post('/gifts/$id/use');
  }

  List<Gift> _parseGiftList(Object? data) {
    if (data is! List) {
      throw const FormatException('Invalid gifts response.');
    }
    return data
        .whereType<Map>()
        .map((item) => Gift.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _payload({
    required String title,
    required String description,
    required bool isActive,
    String? imageUrl,
  }) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      'is_active': isActive,
    };
  }
}
