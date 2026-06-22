import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'about_restaurant_screen.dart';
import 'bonus_history_screen.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';

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
        onTap: isLogout ? () => _logout(context) : item.onTap(context),
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
  const _MoreItem(
    this.title,
    this.icon, {
    this.routeName,
    this.message,
    this.externalUrl,
    this.screen,
    this.whatsAppPhones,
  });

  final String title;
  final IconData icon;
  final String? routeName;
  final String? message;
  final String? externalUrl;
  final Widget? screen;
  final List<_WhatsAppPhone>? whatsAppPhones;

  VoidCallback? onTap(BuildContext context) {
    if (message != null) {
      return () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message!)),
        );
      };
    }
    if (whatsAppPhones != null) {
      return () => _showWhatsAppPhones(context, whatsAppPhones!);
    }
    if (externalUrl != null) {
      return () => _openExternalUrl(context, externalUrl!);
    }
    if (screen != null) {
      return () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => screen!),
        );
      };
    }
    if (routeName == null) {
      return null;
    }
    return () => Navigator.of(context).pushNamed(routeName!);
  }

  void _showWhatsAppPhones(
    BuildContext context,
    List<_WhatsAppPhone> phones,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Написать в WhatsApp',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ...phones.map(
                  (phone) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.chat_rounded,
                          color: AppColors.textSecondary,
                        ),
                        title: Text(phone.label),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _openWhatsApp(context, phone.digits);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWhatsApp(BuildContext context, String phoneDigits) async {
    final uri = Uri.parse('https://wa.me/$phoneDigits');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть WhatsApp')),
      );
    }
  }

  Future<void> _openExternalUrl(BuildContext context, String value) async {
    final uri = Uri.parse(value);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть ссылку')),
      );
    }
  }
}

class _WhatsAppPhone {
  const _WhatsAppPhone({
    required this.label,
    required this.digits,
  });

  final String label;
  final String digits;
}

const _items = [
  _MoreItem(
    'История бонусов',
    Icons.stars_rounded,
    routeName: BonusHistoryScreen.routeName,
  ),
  _MoreItem(
    'Мои заказы',
    Icons.receipt_long_rounded,
    routeName: MyOrdersScreen.routeName,
  ),
  _MoreItem(
    'Адреса доставки',
    Icons.location_on_rounded,
    message: 'Страница в разработке',
  ),
  _MoreItem(
    'Отзывы',
    Icons.rate_review_rounded,
    externalUrl: 'https://2gis.kz/aktobe/geo/70000001032277594',
  ),
  _MoreItem(
    'О ресторане',
    Icons.info_outline_rounded,
    screen: AboutRestaurantScreen(),
  ),
  _MoreItem(
    'Поддержка',
    Icons.support_agent_rounded,
    whatsAppPhones: [
      _WhatsAppPhone(label: '+7 775 991 78 68', digits: '77759917868'),
      _WhatsAppPhone(label: '+7 747 748 00 01', digits: '77477480001'),
    ],
  ),
  _MoreItem('Выйти', Icons.logout_rounded),
];
