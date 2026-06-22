import 'package:flutter/material.dart';

import '../../models/staff_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/backend_error.dart';
import '../login_screen.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({
    super.key,
    required this.canCreateAdmins,
  });

  final bool canCreateAdmins;

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _staffService = StaffService();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _branchController = TextEditingController();

  List<StaffUser> _staff = [];
  StaffUser? _editingStaff;
  late String _selectedRole;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.canCreateAdmins ? 'admin' : 'cashier';
    _load();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _branchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staff = await _staffService.getStaff();
      if (!mounted) {
        return;
      }
      setState(() => _staff = staff);
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось загрузить сотрудников.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (fullName.length < 2 || phone.length < 5 || email.isEmpty) {
      setState(() => _errorMessage = 'Заполните имя, телефон и email.');
      return;
    }
    if (_editingStaff == null && password.length < 8) {
      setState(() => _errorMessage = 'Пароль должен быть минимум 8 символов.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final branchId = int.tryParse(_branchController.text.trim());
      if (_editingStaff == null) {
        await _staffService.createStaff(
          fullName: fullName,
          phone: phone,
          email: email,
          password: password,
          role: _selectedRole,
          branchId: branchId,
        );
      } else {
        await _staffService.updateStaff(
          _editingStaff!.id,
          fullName: fullName,
          phone: phone,
          email: email,
          password: password,
          role: _selectedRole,
          branchId: branchId,
        );
      }
      _clearForm();
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось сохранить сотрудника.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _toggleActive(StaffUser user) async {
    if (user.role == 'owner') {
      setState(() => _errorMessage = 'Аккаунт владельца нельзя отключить здесь.');
      return;
    }
    setState(() => _errorMessage = null);
    try {
      if (user.isActive) {
        await _staffService.deactivateStaff(user.id);
      } else {
        await _staffService.activateStaff(user.id);
      }
      await _load();
    } catch (error) {
      await _handleError(error, fallback: 'Не удалось изменить статус сотрудника.');
    }
  }

  void _edit(StaffUser user) {
    if (user.role == 'owner') {
      setState(() => _errorMessage = 'Аккаунт владельца нельзя редактировать здесь.');
      return;
    }
    setState(() {
      _editingStaff = user;
      _fullNameController.text = user.fullName;
      _phoneController.text = user.phone;
      _emailController.text = user.email;
      _passwordController.clear();
      _branchController.text = user.branchId?.toString() ?? '';
      _selectedRole = user.role;
    });
  }

  void _clearForm() {
    setState(() {
      _editingStaff = null;
      _fullNameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _passwordController.clear();
      _branchController.clear();
      _selectedRole = widget.canCreateAdmins ? 'admin' : 'cashier';
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
    final roleItems = [
      if (widget.canCreateAdmins) const DropdownMenuItem(value: 'admin', child: Text('Админ')),
      const DropdownMenuItem(value: 'cashier', child: Text('Кассир')),
      const DropdownMenuItem(value: 'courier', child: Text('Курьер')),
    ];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Text('Персонал', style: Theme.of(context).textTheme.headlineMedium),
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
                Text(
                  _editingStaff == null ? 'Создать сотрудника' : 'Редактировать сотрудника',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                _StaffInput(controller: _fullNameController, label: 'Полное имя', icon: Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _StaffInput(controller: _phoneController, label: 'Телефон', icon: Icons.phone_outlined),
                const SizedBox(height: 12),
                _StaffInput(controller: _emailController, label: 'Email', icon: Icons.mail_outline_rounded),
                const SizedBox(height: 12),
                _StaffInput(
                  controller: _passwordController,
                  label: _editingStaff == null ? 'Пароль' : 'Новый пароль, если нужно',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                _StaffInput(
                  controller: _branchController,
                  label: 'ID филиала',
                  icon: Icons.storefront_rounded,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_selectedRole),
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Роль',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  items: roleItems,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(_editingStaff == null ? 'СОЗДАТЬ' : 'СОХРАНИТЬ'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                      ),
                    ),
                    if (_editingStaff != null) ...[
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
          const SizedBox(height: 18),
          if (_staff.isEmpty)
            const _EmptyState()
          else
            ..._staff.map(
              (user) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StaffTile(
                  user: user,
                  onEdit: () => _edit(user),
                  onToggleActive: () => _toggleActive(user),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaffInput extends StatelessWidget {
  const _StaffInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
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

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.user,
    required this.onEdit,
    required this.onToggleActive,
  });

  final StaffUser user;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: user.isActive ? AppColors.accentSoft : AppColors.card,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.badge_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text('${user.role} - ${user.isActive ? 'активен' : 'отключен'}', style: Theme.of(context).textTheme.bodyMedium),
                Text(user.email, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (user.role != 'owner') ...[
            IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded)),
            TextButton(
              onPressed: onToggleActive,
              child: Text(user.isActive ? 'Отключить' : 'Включить'),
            ),
          ],
        ],
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
      child: const Text('Сотрудников пока нет. Создайте первого сотрудника выше.'),
    );
  }
}
