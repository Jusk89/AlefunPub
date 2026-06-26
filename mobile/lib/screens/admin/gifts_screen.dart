import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/gift.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/gift_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/backend_error.dart';
import '../login_screen.dart';

class GiftsScreen extends StatefulWidget {
  const GiftsScreen({super.key});

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final _giftService = GiftService();
  final _uploadService = UploadService();
  final _imagePicker = ImagePicker();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  List<Gift> _gifts = [];
  Gift? _editingGift;
  bool _isActive = true;
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
    _titleController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final gifts = await _giftService.getGifts();
      if (!mounted) {
        return;
      }
      setState(() => _gifts = gifts);
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось загрузить подарки.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.length < 2 || description.length < 2) {
      setState(() => _errorMessage = 'Введите название и описание подарка.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_editingGift == null) {
        await _giftService.createGift(
          title: title,
          description: description,
          imageUrl: _imageUrlController.text,
          isActive: _isActive,
        );
      } else {
        await _giftService.updateGift(
          _editingGift!.id,
          title: title,
          description: description,
          imageUrl: _imageUrlController.text,
          isActive: _isActive,
        );
      }
      _clearForm();
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось сохранить подарок.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete(Gift gift) async {
    setState(() => _errorMessage = null);
    try {
      await _giftService.deleteGift(gift.id);
      if (_editingGift?.id == gift.id) {
        _clearForm();
      }
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось удалить подарок.');
    }
  }

  Future<void> _uploadImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (image == null) {
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final imageUrl = await _uploadService.uploadPickedImage(image: image, folder: 'gifts');
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

  void _edit(Gift gift) {
    setState(() {
      _editingGift = gift;
      _titleController.text = gift.title;
      _descriptionController.text = gift.description;
      _imageUrlController.text = gift.imageUrl ?? '';
      _isActive = gift.isActive;
    });
  }

  void _clearForm() {
    setState(() {
      _editingGift = null;
      _titleController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _isActive = true;
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
          Text('Подарки', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Создавать и менять подарки может только owner.', style: Theme.of(context).textTheme.bodyMedium),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          _GiftFormCard(
            imageUrl: _imageUrlController.text,
            titleController: _titleController,
            descriptionController: _descriptionController,
            imageUrlController: _imageUrlController,
            isActive: _isActive,
            isSaving: _isSaving,
            isUploading: _isUploading,
            isEditing: _editingGift != null,
            onActiveChanged: (value) => setState(() => _isActive = value),
            onUpload: _uploadImage,
            onSave: _save,
            onCancelEdit: _clearForm,
          ),
          const SizedBox(height: 16),
          if (_gifts.isEmpty)
            const _EmptyGifts()
          else
            ..._gifts.map(
              (gift) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GiftPreview(
                  gift: gift,
                  onEdit: () => _edit(gift),
                  onDelete: () => _delete(gift),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GiftFormCard extends StatelessWidget {
  const _GiftFormCard({
    required this.imageUrl,
    required this.titleController,
    required this.descriptionController,
    required this.imageUrlController,
    required this.isActive,
    required this.isSaving,
    required this.isUploading,
    required this.isEditing,
    required this.onActiveChanged,
    required this.onUpload,
    required this.onSave,
    required this.onCancelEdit,
  });

  final String imageUrl;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController imageUrlController;
  final bool isActive;
  final bool isSaving;
  final bool isUploading;
  final bool isEditing;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onUpload;
  final VoidCallback onSave;
  final VoidCallback onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _ImageBox(imageUrl: imageUrl),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isUploading ? null : onUpload,
            icon: isUploading
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
          _Input(controller: imageUrlController, label: 'URL изображения', icon: Icons.link_rounded),
          const SizedBox(height: 12),
          _Input(controller: titleController, label: 'Название', icon: Icons.card_giftcard_rounded),
          const SizedBox(height: 12),
          _Input(controller: descriptionController, label: 'Описание', icon: Icons.notes_rounded),
          SwitchListTile(
            value: isActive,
            onChanged: onActiveChanged,
            contentPadding: EdgeInsets.zero,
            title: const Text('Активен'),
            activeThumbColor: AppColors.accent,
          ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(isEditing ? 'СОХРАНИТЬ' : 'СОЗДАТЬ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
              if (isEditing) ...[
                const SizedBox(width: 10),
                IconButton.outlined(onPressed: onCancelEdit, icon: const Icon(Icons.close_rounded)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiService.resolveImageUrl(imageUrl);
    return Container(
      height: 156,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: resolved.isEmpty
          ? const Icon(Icons.card_giftcard_rounded, size: 42, color: AppColors.textSecondary)
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

class _Input extends StatelessWidget {
  const _Input({required this.controller, required this.label, required this.icon});

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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

class _GiftPreview extends StatelessWidget {
  const _GiftPreview({required this.gift, required this.onEdit, required this.onDelete});

  final Gift gift;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.card_giftcard_rounded),
        title: Text(gift.title),
        subtitle: Text(gift.isActive ? 'Активен' : 'Скрыт'),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
          ],
        ),
      ),
    );
  }
}

class _EmptyGifts extends StatelessWidget {
  const _EmptyGifts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text('Подарков пока нет.'),
    );
  }
}
