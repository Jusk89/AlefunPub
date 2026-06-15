import 'package:flutter/material.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  int _genderIndex = 2;
  String? _syncedUserSignature;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) {
      return;
    }

    try {
      await AuthScope.of(context, listen: false).refreshCurrentUser();
    } catch (_) {
      _redirectToLogin();
    }
  }

  void _syncControllers(User user) {
    final birthDate = _formatDate(user.birthDate);
    final signature = '${user.id}|${user.fullName}|$birthDate';
    if (_syncedUserSignature == signature) {
      return;
    }

    _syncedUserSignature = signature;
    _nameController.text = user.fullName;
    _birthDateController.text = birthDate;
  }

  void _redirectToLogin() {
    if (_isRedirecting) {
      return;
    }

    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        LoginScreen.routeName,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthScope.of(context);
    final user = authProvider.currentUser;

    if (authProvider.status == AuthStatus.unauthenticated) {
      _redirectToLogin();
    }

    if (authProvider.status == AuthStatus.checking && user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    if (user == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Text('Профиль', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 22),
          const _InfoCard(
            icon: Icons.error_outline_rounded,
            label: 'Сессия',
            value: 'Войдите заново',
          ),
        ],
      );
    }

    _syncControllers(user);

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Профиль',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (authProvider.status == AuthStatus.checking)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.3),
                )
              else
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Обновить',
                ),
            ],
          ),
          const SizedBox(height: 22),
          _PhoneCard(phone: user.phone),
          const SizedBox(height: 18),
          _ProfileInput(
            label: 'Имя',
            controller: _nameController,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: user.email,
          ),
          const SizedBox(height: 18),
          Text('Пол', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 10),
          _GenderSelector(
            selectedIndex: _genderIndex,
            onChanged: (index) => setState(() => _genderIndex = index),
          ),
          const SizedBox(height: 18),
          _ProfileInput(
            label: 'Дата рождения',
            controller: _birthDateController,
            icon: Icons.cake_outlined,
            keyboardType: TextInputType.datetime,
          ),
          const SizedBox(height: 18),
          _InfoCard(
            icon: Icons.badge_outlined,
            label: 'Роль',
            value: user.role,
          ),
          const SizedBox(height: 26),
          FilledButton(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              'СОХРАНИТЬ',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text(
              'УДАЛИТЬ АККАУНТ',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.phone_rounded, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Телефон', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  phone.isEmpty ? 'Не указано' : phone,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInput extends StatelessWidget {
  const _ProfileInput({
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Не указано' : value,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Мужчина', 'Женщина', 'Не указан'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
