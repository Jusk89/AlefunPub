import 'package:flutter/material.dart';

import '../../models/campaign.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/campaign_service.dart';
import '../../services/upload_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/backend_error.dart';
import '../login_screen.dart';

class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  State<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends State<AdminCampaignsScreen> {
  final _campaignService = CampaignService();
  final _uploadService = UploadService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _imagePathController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  List<Campaign> _campaigns = [];
  Campaign? _editingCampaign;
  String _targetGroup = 'all_clients';
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
    _imagePathController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final campaigns = await _campaignService.getCampaigns();
      if (!mounted) {
        return;
      }
      setState(() => _campaigns = campaigns);
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось загрузить афиши.');
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
      setState(() => _errorMessage = 'Введите название и описание афиши.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      if (_editingCampaign == null) {
        await _campaignService.createCampaign(
          title: title,
          description: description,
          imageUrl: _imageUrlController.text,
          targetGroup: _targetGroup,
          startDate: _parseDate(_startDateController.text),
          endDate: _parseDate(_endDateController.text),
          isActive: _isActive,
        );
      } else {
        await _campaignService.updateCampaign(
          _editingCampaign!.id,
          title: title,
          description: description,
          imageUrl: _imageUrlController.text,
          targetGroup: _targetGroup,
          startDate: _parseDate(_startDateController.text),
          endDate: _parseDate(_endDateController.text),
          isActive: _isActive,
        );
      }
      _clearForm();
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось сохранить афишу.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _delete(Campaign campaign) async {
    setState(() => _errorMessage = null);
    try {
      await _campaignService.deleteCampaign(campaign.id);
      if (_editingCampaign?.id == campaign.id) {
        _clearForm();
      }
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось удалить афишу.');
    }
  }

  Future<void> _uploadImage() async {
    final path = _imagePathController.text.trim();
    if (path.isEmpty) {
      setState(() => _errorMessage = 'Введите путь к файлу изображения.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final imageUrl = await _uploadService.uploadImage(filePath: path, folder: 'campaigns');
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

  void _edit(Campaign campaign) {
    setState(() {
      _editingCampaign = campaign;
      _titleController.text = campaign.title;
      _descriptionController.text = campaign.description;
      _imageUrlController.text = campaign.imageUrl ?? '';
      _startDateController.text = _formatInputDate(campaign.startDate);
      _endDateController.text = _formatInputDate(campaign.endDate);
      _targetGroup = campaign.targetGroup;
      _isActive = campaign.isActive;
    });
  }

  void _clearForm() {
    setState(() {
      _editingCampaign = null;
      _titleController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      _imagePathController.clear();
      _startDateController.clear();
      _endDateController.clear();
      _targetGroup = 'all_clients';
      _isActive = true;
    });
  }

  DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return DateTime.tryParse(trimmed);
  }

  String _formatInputDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
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
          Text('Афиши', style: Theme.of(context).textTheme.headlineMedium),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _CampaignImageBox(imageUrl: _imageUrlController.text),
                const SizedBox(height: 14),
                _CampaignInput(controller: _imagePathController, label: 'Путь к файлу для загрузки', icon: Icons.folder_open_rounded),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isUploading ? null : _uploadImage,
                  icon: _isUploading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_rounded),
                  label: const Text('ЗАГРУЗИТЬ ИЗОБРАЖЕНИЕ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
                const SizedBox(height: 12),
                _CampaignInput(controller: _imageUrlController, label: 'URL изображения', icon: Icons.link_rounded),
                const SizedBox(height: 12),
                _CampaignInput(controller: _titleController, label: 'Название', icon: Icons.campaign_rounded),
                const SizedBox(height: 12),
                _CampaignInput(controller: _descriptionController, label: 'Описание', icon: Icons.notes_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _CampaignInput(controller: _startDateController, label: 'Начало YYYY-MM-DD', icon: Icons.event_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _CampaignInput(controller: _endDateController, label: 'Конец YYYY-MM-DD', icon: Icons.event_available_rounded)),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_targetGroup),
                  initialValue: _targetGroup,
                  decoration: InputDecoration(
                    labelText: 'Целевая группа',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all_clients', child: Text('Все клиенты')),
                    DropdownMenuItem(value: 'inactive_clients', child: Text('Неактивные клиенты')),
                    DropdownMenuItem(value: 'birthday_clients', child: Text('Дни рождения')),
                    DropdownMenuItem(value: 'vip_clients', child: Text('VIP клиенты')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _targetGroup = value);
                    }
                  },
                ),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Активна'),
                  activeThumbColor: AppColors.accent,
                ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_editingCampaign == null ? 'СОЗДАТЬ' : 'СОХРАНИТЬ'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    if (_editingCampaign != null) ...[
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        onPressed: _clearForm,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_campaigns.isEmpty)
            const _EmptyState()
          else
            ..._campaigns.map(
              (campaign) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CampaignPreview(
                  campaign: campaign,
                  onEdit: () => _edit(campaign),
                  onDelete: () => _delete(campaign),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CampaignImageBox extends StatelessWidget {
  const _CampaignImageBox({required this.imageUrl});

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
          ? const Icon(Icons.image_rounded, size: 42, color: AppColors.textSecondary)
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

class _CampaignInput extends StatelessWidget {
  const _CampaignInput({
    required this.controller,
    required this.label,
    required this.icon,
  });

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

class _CampaignPreview extends StatelessWidget {
  const _CampaignPreview({
    required this.campaign,
    required this.onEdit,
    required this.onDelete,
  });

  final Campaign campaign;
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
        leading: const Icon(Icons.campaign_rounded),
        title: Text(campaign.title),
        subtitle: Text('${campaign.isActive ? 'Активна' : 'Скрыта'} - ${campaign.targetGroup}'),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text('Афиш пока нет. Создайте первую афишу выше.'),
    );
  }
}
