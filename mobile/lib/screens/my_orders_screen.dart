import 'package:flutter/material.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/orders_provider.dart';
import '../theme/app_colors.dart';
import '../utils/backend_error.dart';
import 'login_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  static const routeName = '/my-orders';

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  late final OrdersProvider _provider;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _provider = OrdersProvider();
    _load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _provider.load();
    } catch (error) {
      if (isUnauthorized(error)) {
        await _redirectToLogin();
      }
    }
  }

  Future<void> _redirectToLogin() async {
    if (_isRedirecting || !mounted) {
      return;
    }

    _isRedirecting = true;
    await AuthScope.of(context, listen: false).logout();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Мои заказы'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.isLoading && _provider.orders.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (_provider.errorMessage != null && _provider.orders.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: _OrdersError(
                message: _provider.errorMessage!,
                onRetry: _load,
              ),
            );
          }

          if (_provider.orders.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: const _OrdersEmpty(),
            );
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              itemCount: _provider.orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _OrderCard(order: _provider.orders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final status = _statusMeta(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Заказ #${order.id}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(order.createdAt),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          _AmountRow(label: 'Сумма', value: order.totalAmount),
          _AmountRow(
            label: 'Бонусы начислены',
            value: order.bonusEarned,
            color: AppColors.success,
            prefix: '+',
          ),
          _AmountRow(
            label: 'Бонусы списаны',
            value: order.bonusSpent,
            color: Colors.red,
            prefix: order.bonusSpent > 0 ? '-' : '',
          ),
          const Divider(height: 24),
          Text('Блюда', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (order.items.isEmpty)
            Text('Позиции не указаны',
                style: Theme.of(context).textTheme.bodyMedium)
          else
            ...order.items.map((item) => _OrderDishRow(item: item)),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.${value.year} $hour:$minute';
  }
}

class _OrderDishRow extends StatelessWidget {
  const _OrderDishRow({required this.item});

  final CustomerOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${item.name} x${item.quantity}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatAmount(item.totalPrice > 0 ? item.totalPrice : item.price),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.color,
    this.prefix = '',
  });

  final String label;
  final double value;
  final Color? color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            '$prefix${_formatAmount(value)}',
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final _StatusMeta status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: status.color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: status.color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersEmpty extends StatelessWidget {
  const _OrdersEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 80, 18, 28),
      children: [
        const Icon(Icons.receipt_long_rounded,
            size: 64, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          'Вы пока не сделали ни одного заказа',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 80, 18, 28),
      children: [
        const Icon(Icons.wifi_off_rounded,
            size: 64, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text(
            'ПОВТОРИТЬ',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _StatusMeta {
  const _StatusMeta({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

_StatusMeta _statusMeta(String status) {
  switch (status) {
    case 'created':
    case 'pending':
      return const _StatusMeta(
        label: 'created',
        color: AppColors.textSecondary,
        icon: Icons.schedule_rounded,
      );
    case 'paid':
    case 'confirmed':
      return const _StatusMeta(
        label: 'paid',
        color: Color(0xFF2D7FF9),
        icon: Icons.payments_outlined,
      );
    case 'cooking':
    case 'preparing':
      return const _StatusMeta(
        label: 'cooking',
        color: Color(0xFFE59A00),
        icon: Icons.soup_kitchen_rounded,
      );
    case 'ready':
      return const _StatusMeta(
        label: 'ready',
        color: Color(0xFF7C4DFF),
        icon: Icons.room_service_rounded,
      );
    case 'completed':
      return const _StatusMeta(
        label: 'completed',
        color: AppColors.success,
        icon: Icons.check_circle_outline_rounded,
      );
    case 'cancelled':
      return const _StatusMeta(
        label: 'cancelled',
        color: Colors.red,
        icon: Icons.cancel_outlined,
      );
    default:
      return _StatusMeta(
        label: status,
        color: AppColors.textSecondary,
        icon: Icons.receipt_long_rounded,
      );
  }
}

String _formatAmount(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toStringAsFixed(2);
}
