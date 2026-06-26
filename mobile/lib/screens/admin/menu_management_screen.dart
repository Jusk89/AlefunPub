import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/menu_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/backend_error.dart';
import '../login_screen.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _menuService = MenuService();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  final _categoryNameController = TextEditingController();
  final _categorySortController = TextEditingController(text: '0');
  final _dishNameController = TextEditingController();
  final _dishDescriptionController = TextEditingController();
  final _dishPriceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  MenuCategory? _editingCategory;
  MenuItem? _editingItem;
  int? _selectedCategoryId;
  bool _categoryActive = true;
  bool _itemAvailable = true;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _categoryNameController.dispose();
    _categorySortController.dispose();
    _dishNameController.dispose();
    _dishDescriptionController.dispose();
    _dishPriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _menuService.getCategories();
      final items = await _menuService.getItems();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories;
        _items = items;
        _selectedCategoryId ??= categories.isNotEmpty ? categories.first.id : null;
      });
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось загрузить меню.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCategory() async {
    final name = _categoryNameController.text.trim();
    if (name.length < 2) {
      setState(() => _errorMessage = 'Введите название категории.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final sortOrder = int.tryParse(_categorySortController.text.trim()) ?? 0;
      if (_editingCategory == null) {
        await _menuService.createCategory(
          name: name,
          sortOrder: sortOrder,
          isActive: _categoryActive,
        );
      } else {
        await _menuService.updateCategory(
          _editingCategory!.id,
          name: name,
          sortOrder: sortOrder,
          isActive: _categoryActive,
        );
      }
      _clearCategoryForm();
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось сохранить категорию.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteCategory(MenuCategory category) async {
    setState(() => _errorMessage = null);
    try {
      await _menuService.deleteCategory(category.id);
      if (_editingCategory?.id == category.id) {
        _clearCategoryForm();
      }
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось удалить категорию.');
    }
  }

  Future<void> _saveItem() async {
    final name = _dishNameController.text.trim();
    final price = double.tryParse(_dishPriceController.text.trim().replaceAll(',', '.'));
    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      setState(() => _errorMessage = 'Сначала создайте категорию.');
      return;
    }
    if (name.length < 2 || price == null) {
      setState(() => _errorMessage = 'Введите название блюда и цену.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_editingItem == null) {
        await _menuService.createItem(
          categoryId: categoryId,
          name: name,
          price: price,
          description: _dishDescriptionController.text,
          imageUrl: _imageUrlController.text,
          isAvailable: _itemAvailable,
        );
      } else {
        await _menuService.updateItem(
          _editingItem!.id,
          categoryId: categoryId,
          name: name,
          price: price,
          description: _dishDescriptionController.text,
          imageUrl: _imageUrlController.text,
          isAvailable: _itemAvailable,
        );
      }
      _clearItemForm();
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось сохранить блюдо.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    setState(() => _errorMessage = null);
    try {
      await _menuService.deleteItem(item.id);
      if (_editingItem?.id == item.id) {
        _clearItemForm();
      }
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось удалить блюдо.');
    }
  }

  Future<void> _uploadDishImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final imageUrl = await _uploadService.uploadPickedImage(
        image: image,
        folder: 'menu',
      );
      if (!mounted) {
        return;
      }
      setState(() => _imageUrlController.text = imageUrl);
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось загрузить изображение.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _editCategory(MenuCategory category) {
    setState(() {
      _editingCategory = category;
      _categoryNameController.text = category.name;
      _categorySortController.text = category.sortOrder.toString();
      _categoryActive = category.isActive;
    });
  }

  void _editItem(MenuItem item) {
    setState(() {
      _editingItem = item;
      _selectedCategoryId = item.categoryId;
      _dishNameController.text = item.name;
      _dishDescriptionController.text = item.description ?? '';
      _dishPriceController.text = item.price.toStringAsFixed(0);
      _imageUrlController.text = item.imageUrl ?? '';
      _itemAvailable = item.isAvailable;
    });
  }

  void _clearCategoryForm() {
    setState(() {
      _editingCategory = null;
      _categoryNameController.clear();
      _categorySortController.text = '0';
      _categoryActive = true;
    });
  }

  void _clearItemForm() {
    setState(() {
      _editingItem = null;
      _dishNameController.clear();
      _dishDescriptionController.clear();
      _dishPriceController.clear();
      _imageUrlController.clear();
      _itemAvailable = true;
    });
  }

  Future<void> _handleError(Object error, {required String fallback}) async {
    if (!mounted) {
      return;
    }
    if (isUnauthorized(error)) {
      await AuthScope.of(context, listen: false).logout();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
      return;
    }
    setState(() => _errorMessage = backendErrorMessage(error, fallback: fallback));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Text('Управление меню', style: Theme.of(context).textTheme.headlineMedium),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          _SectionCard(
            title: _editingCategory == null ? 'Категория' : 'Редактирование категории',
            child: Column(
              children: [
                _AdminInput(controller: _categoryNameController, label: 'Название категории', icon: Icons.category_rounded),
                const SizedBox(height: 12),
                _AdminInput(
                  controller: _categorySortController,
                  label: 'Порядок сортировки',
                  icon: Icons.sort_rounded,
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: _categoryActive,
                  onChanged: (value) => setState(() => _categoryActive = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Активна'),
                  activeThumbColor: AppColors.accent,
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveCategory,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_editingCategory == null ? 'ДОБАВИТЬ' : 'СОХРАНИТЬ'),
                        style: _buttonStyle(),
                      ),
                    ),
                    if (_editingCategory != null) ...[
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        onPressed: _clearCategoryForm,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ..._categories.map(
                  (category) => _ListRow(
                    title: category.name,
                    subtitle: '${category.isActive ? 'Активна' : 'Скрыта'} - sort ${category.sortOrder}',
                    onEdit: () => _editCategory(category),
                    onDelete: () => _deleteCategory(category),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: _editingItem == null ? 'Блюдо' : 'Редактирование блюда',
            child: Column(
              children: [
                _ImagePreview(imageUrl: _imageUrlController.text),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _uploadDishImage,
                  icon: _isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_library_rounded),
                  label: const Text('ВЫБРАТЬ ФОТО'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                const SizedBox(height: 12),
                _AdminInput(controller: _imageUrlController, label: 'URL изображения', icon: Icons.link_rounded),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  key: ValueKey(_selectedCategoryId),
                  initialValue: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Категория',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  items: _categories
                      .map((category) => DropdownMenuItem(value: category.id, child: Text(category.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: 12),
                _AdminInput(controller: _dishNameController, label: 'Название блюда', icon: Icons.restaurant_menu_rounded),
                const SizedBox(height: 12),
                _AdminInput(controller: _dishDescriptionController, label: 'Описание', icon: Icons.notes_rounded),
                const SizedBox(height: 12),
                _AdminInput(
                  controller: _dishPriceController,
                  label: 'Цена',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  value: _itemAvailable,
                  onChanged: (value) => setState(() => _itemAvailable = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Доступно'),
                  activeThumbColor: AppColors.accent,
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveItem,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_editingItem == null ? 'ДОБАВИТЬ' : 'СОХРАНИТЬ'),
                        style: _buttonStyle(),
                      ),
                    ),
                    if (_editingItem != null) ...[
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        onPressed: _clearItemForm,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ..._items.map(
                  (item) => _ListRow(
                    title: item.name,
                    subtitle: '${item.price.toStringAsFixed(0)} - ${item.isAvailable ? 'доступно' : 'скрыто'}',
                    onEdit: () => _editItem(item),
                    onDelete: () => _deleteItem(item),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiService.resolveImageUrl(imageUrl);
    return Container(
      height: 150,
      width: double.infinity,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: resolved.isEmpty
          ? const Icon(Icons.image_outlined, size: 42, color: AppColors.textSecondary)
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
            ),
    );
  }
}

class _AdminInput extends StatelessWidget {
  const _AdminInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

ButtonStyle _buttonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.textPrimary,
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}
