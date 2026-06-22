import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/bonus_balance.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../providers/auth_provider.dart';
import '../services/bonus_service.dart';
import '../services/menu_service.dart';
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
      children: const [
        _TopBar(),
        SizedBox(height: 18),
        _PromoBanner(),
        SizedBox(height: 24),
        _SectionTitle(title: 'Ваш первый подарок'),
        SizedBox(height: 12),
        _GiftCard(),
        SizedBox(height: 26),
        _MenuSection(),
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
              Text('Alefun Pub',
                  style: Theme.of(context).textTheme.headlineMedium),
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
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        image: const DecorationImage(
          image: AssetImage('assets/images/alefun_pub_banner.jpeg'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  color: Colors.white.withValues(alpha: 0.78),
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
            color: Colors.black.withValues(alpha: 0.05),
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
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.textPrimary,
              size: 34,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Добро пожаловать',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  'Получите подарок после первого заказа',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textSecondary),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _MenuSection extends StatefulWidget {
  const _MenuSection();

  @override
  State<_MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<_MenuSection> {
  final _menuService = MenuService();

  List<MenuCategory> _categories = [];
  List<MenuItem> _items = [];
  int? _selectedCategoryId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _menuService.getCategories();
      final activeCategories = categories
          .where((category) => category.isActive)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final selectedCategoryId = _selectedCategoryId ??
          (activeCategories.isNotEmpty ? activeCategories.first.id : null);
      final items = selectedCategoryId == null
          ? <MenuItem>[]
          : await _menuService.getItemsByCategory(selectedCategoryId);

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = activeCategories;
        _selectedCategoryId = selectedCategoryId;
        _items = items;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (error is DioException && error.response?.statusCode == 401) {
        await AuthScope.of(context, listen: false).logout();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginScreen.routeName,
          (route) => false,
        );
        return;
      }
      setState(() => _errorMessage = 'Не удалось загрузить меню');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectCategory(MenuCategory category) async {
    if (_selectedCategoryId == category.id) {
      return;
    }

    setState(() {
      _selectedCategoryId = category.id;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _menuService.getItemsByCategory(category.id);
      if (!mounted) {
        return;
      }
      setState(() => _items = items);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Не удалось загрузить блюда');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Меню'),
        const SizedBox(height: 14),
        if (_categories.isNotEmpty)
          _CategoryChips(
            categories: _categories,
            selectedCategoryId: _selectedCategoryId,
            onSelected: _selectCategory,
          ),
        if (_categories.isNotEmpty) const SizedBox(height: 18),
        if (_isLoading)
          const _MenuLoading()
        else if (_errorMessage != null)
          _MenuError(message: _errorMessage!, onRetry: _loadMenu)
        else if (_categories.isEmpty || _items.isEmpty)
          const _MenuEmpty()
        else
          _MenuGrid(items: _items),
      ],
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final List<MenuCategory> categories;
  final int? selectedCategoryId;
  final ValueChanged<MenuCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedCategoryId;
          return InkWell(
            onTap: () => onSelected(category),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  const _MenuGrid({required this.items});

  final List<MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return MenuItemCard(
          name: item.name,
          pricePoints: item.price,
          imageUrl: item.imageUrl,
        );
      },
    );
  }
}

class _MenuLoading extends StatelessWidget {
  const _MenuLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 42),
      child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
    );
  }
}

class _MenuError extends StatelessWidget {
  const _MenuError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

class _MenuEmpty extends StatelessWidget {
  const _MenuEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'Меню пусто',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
