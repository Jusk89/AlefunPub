import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      itemCount: _items.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 18 : 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text('Еще', style: Theme.of(context).textTheme.headlineMedium);
        }

        final item = _items[index - 1];
        return _MoreTile(item: item);
      },
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.item});

  final _MoreItem item;

  @override
  Widget build(BuildContext context) {
    final isLogout = item.icon == Icons.logout_rounded;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        minVerticalPadding: 14,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            item.icon,
            color: isLogout ? Colors.red : AppColors.textSecondary,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isLogout ? Colors.red : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isLogout ? Colors.red : AppColors.textSecondary,
        ),
        onTap: isLogout ? () => _logout(context) : null,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await AuthScope.of(context, listen: false).logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }
}

class _MoreItem {
  const _MoreItem(this.title, this.icon);

  final String title;
  final IconData icon;
}

const _items = [
  _MoreItem('История бонусов', Icons.stars_rounded),
  _MoreItem('Мои заказы', Icons.receipt_long_rounded),
  _MoreItem('Адреса доставки', Icons.location_on_rounded),
  _MoreItem('Отзывы', Icons.rate_review_rounded),
  _MoreItem('О ресторане', Icons.info_outline_rounded),
  _MoreItem('Поддержка', Icons.support_agent_rounded),
  _MoreItem('Выйти', Icons.logout_rounded),
];
