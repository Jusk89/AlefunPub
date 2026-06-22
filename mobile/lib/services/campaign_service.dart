import '../models/campaign.dart';
import 'api_service.dart';

class CampaignService {
  CampaignService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  Future<List<Campaign>> getCampaigns() async {
    final response = await _apiService.get('/campaigns');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid campaigns response.');
    }

    return data
        .whereType<Map>()
        .map((item) => Campaign.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Campaign> createCampaign({
    required String title,
    required String description,
    required String targetGroup,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    final response = await _apiService.post(
      '/campaigns',
      data: _campaignPayload(
        title: title,
        description: description,
        targetGroup: targetGroup,
        imageUrl: imageUrl,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      ),
    );
    return Campaign.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<Campaign> updateCampaign(
    int id, {
    required String title,
    required String description,
    required String targetGroup,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    final response = await _apiService.patch(
      '/campaigns/$id',
      data: _campaignPayload(
        title: title,
        description: description,
        targetGroup: targetGroup,
        imageUrl: imageUrl,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      ),
    );
    return Campaign.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteCampaign(int id) async {
    await _apiService.delete('/campaigns/$id');
  }

  Map<String, dynamic> _campaignPayload({
    required String title,
    required String description,
    required String targetGroup,
    required bool isActive,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      'target_group': targetGroup,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
    };
  }
}
