import '../models/menu_category.dart';
import '../models/menu_item.dart';
import 'api_service.dart';

class MenuService {
  MenuService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  static const int defaultRestaurantId = int.fromEnvironment(
    'RESTAURANT_ID',
    defaultValue: 1,
  );

  final ApiService _apiService;

  Future<List<MenuCategory>> getCategories() async {
    final response = await _apiService.get('/menu/categories');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid categories response.');
    }
    return data
        .whereType<Map>()
        .map((item) => MenuCategory.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<MenuCategory> createCategory({
    required String name,
    int restaurantId = defaultRestaurantId,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    final response = await _apiService.post(
      '/menu/categories',
      data: {
        'restaurant_id': restaurantId,
        'name': name.trim(),
        'sort_order': sortOrder,
        'is_active': isActive,
      },
    );
    return MenuCategory.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<MenuCategory> updateCategory(
    int id, {
    required String name,
    int? restaurantId,
    int? sortOrder,
    bool? isActive,
  }) async {
    final response = await _apiService.patch(
      '/menu/categories/$id',
      data: {
        'name': name.trim(),
        if (restaurantId != null) 'restaurant_id': restaurantId,
        if (sortOrder != null) 'sort_order': sortOrder,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return MenuCategory.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteCategory(int id) async {
    await _apiService.delete('/menu/categories/$id');
  }

  Future<List<MenuItem>> getItems() async {
    final response = await _apiService.get('/menu/items');
    final data = response.data;
    if (data is! List) {
      throw const FormatException('Invalid menu items response.');
    }
    return data
        .whereType<Map>()
        .map((item) => MenuItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<MenuItem>> getItemsByCategory(int categoryId) async {
    final items = await getItems();
    return items
        .where((item) => item.categoryId == categoryId && item.isAvailable)
        .toList();
  }

  Future<MenuItem> createItem({
    required int categoryId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    int restaurantId = defaultRestaurantId,
    bool isAvailable = true,
  }) async {
    final response = await _apiService.post(
      '/menu/items',
      data: {
        'restaurant_id': restaurantId,
        'category_id': categoryId,
        'name': name.trim(),
        'description': description?.trim(),
        'price': price,
        'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
        'is_available': isAvailable,
      },
    );
    return MenuItem.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<MenuItem> updateItem(
    int id, {
    required int categoryId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
    int restaurantId = defaultRestaurantId,
    bool? isAvailable,
  }) async {
    final response = await _apiService.patch(
      '/menu/items/$id',
      data: {
        'restaurant_id': restaurantId,
        'category_id': categoryId,
        'name': name.trim(),
        'description': description?.trim(),
        'price': price,
        'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
        if (isAvailable != null) 'is_available': isAvailable,
      },
    );
    return MenuItem.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<void> deleteItem(int id) async {
    await _apiService.delete('/menu/items/$id');
  }
}
