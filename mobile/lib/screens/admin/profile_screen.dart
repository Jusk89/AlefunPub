import 'package:flutter/material.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../login_screen.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({
    super.key,
    this.isOwner = false,
  });

  final bool isOwner;

  Future<void> _logout(BuildContext context) async {
    await AuthScope.of(context, listen: false).logout();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthScope.of(context).currentUser;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text(isOwner ? 'Профиль владельца' : 'Профиль админа', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        _InfoCard(label: 'Имя', value: user?.fullName ?? ''),
        const SizedBox(height: 12),
        _InfoCard(label: 'Телефон', value: user?.phone ?? ''),
        const SizedBox(height: 12),
        _InfoCard(label: 'Email', value: user?.email ?? ''),
        const SizedBox(height: 12),
        _InfoCard(label: 'Роль', value: user?.role ?? (isOwner ? 'owner' : 'admin')),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            isOwner
                ? 'Владелец может управлять админами и настройками ресторана.'
                : 'Админ может управлять меню, афишами, кассирами и курьерами.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (isOwner) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Настройки ресторана', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 14),
                const _SettingRow(title: 'Процент бонусов', value: '5%'),
                const _SettingRow(title: 'QR режим', value: 'Постоянный QR'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('ВЫЙТИ'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

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
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text(value, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
