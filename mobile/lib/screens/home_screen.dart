import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/bonus_balance.dart';
import '../providers/auth_provider.dart';
import '../services/bonus_service.dart';
import '../theme/app_colors.dart';
import '../widgets/menu_item_card.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      children: [
        const _TopBar(),
        const SizedBox(height: 18),
        const _PromoBanner(),
        const SizedBox(height: 24),
        Text('Ваш первый подарок', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const _GiftCard(),
        const SizedBox(height: 26),
        Text('Меню', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 14),
        const _CategoryChips(),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return MenuItemCard(
              name: item.name,
              pricePoints: item.pricePoints,
              icon: item.icon,
            );
          },
        ),
      ],
    );
  }
}

class _TopBar extends StatefulWidget {
  const _TopBar();

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  final _bonusService = BonusService();

  late Future<BonusBalance> _balanceFuture;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _balanceFuture = _bonusService.getBalance();
  }

  void _redirectToLogin() {
    if (_isRedirecting) {
      return;
    }

    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      await AuthScope.of(context, listen: false).logout();

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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alefun Pub', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'ул. Братьев Жубановых, 344',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        FutureBuilder<BonusBalance>(
          future: _balanceFuture,
          builder: (context, snapshot) {
            final error = snapshot.error;
            if (error is DioException && error.response?.statusCode == 401) {
              _redirectToLogin();
            }

            final isLoading = snapshot.connectionState != ConnectionState.done;
            final hasError = snapshot.hasError &&
                !(error is DioException && error.response?.statusCode == 401);

            return _HeaderBonusBadge(
              balance: snapshot.data?.balance,
              isLoading: isLoading,
              hasError: hasError,
            );
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
      ],
    );
  }
}

class _HeaderBonusBadge extends StatelessWidget {
  const _HeaderBonusBadge({
    required this.balance,
    required this.isLoading,
    required this.hasError,
  });

  final double? balance;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              hasError ? '--' : _formatBalance(balance ?? 0),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(width: 4),
          const Icon(Icons.star_rounded, size: 18, color: AppColors.accent),
        ],
      ),
    );
  }

  String _formatBalance(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(2);
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: 24,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(90),
              ),
              child: const Icon(Icons.local_pizza_rounded, size: 92, color: AppColors.textPrimary),
            ),
          ),
          Positioned(
            right: 42,
            bottom: 16,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(Icons.sports_bar_rounded, size: 62, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Новое меню',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              const Text(
                'Соберите\nвечер в Alefun',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Закуски, напитки и горячие блюда для компании',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GiftCard extends StatelessWidget {
  const _GiftCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: AppColors.textPrimary, size: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Добро пожаловать', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text('Получите подарок после первого заказа', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? AppColors.accent : AppColors.border),
            ),
            child: Text(
              _categories[index],
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuMock {
  const _MenuMock({
    required this.name,
    required this.pricePoints,
    required this.icon,
  });

  final String name;
  final int pricePoints;
  final IconData icon;
}

const _categories = [
  'Наборы в стол',
  'Закуски',
  'Салаты',
  'Напитки',
  'Десерты',
];

const _menuItems = [
  _MenuMock(name: 'Сет к пиву', pricePoints: 3200, icon: Icons.tapas_rounded),
  _MenuMock(name: 'Крылья BBQ', pricePoints: 2600, icon: Icons.set_meal_rounded),
  _MenuMock(name: 'Цезарь', pricePoints: 2400, icon: Icons.eco_rounded),
  _MenuMock(name: 'Брускетты', pricePoints: 2100, icon: Icons.bakery_dining_rounded),
  _MenuMock(name: 'Лимонад', pricePoints: 1100, icon: Icons.local_drink_rounded),
  _MenuMock(name: 'Чизкейк', pricePoints: 1500, icon: Icons.cake_rounded),
];
