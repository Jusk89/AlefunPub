import 'package:flutter/material.dart';

import '../models/bonus_transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/bonus_history_provider.dart';
import '../theme/app_colors.dart';
import '../utils/backend_error.dart';
import 'login_screen.dart';

class BonusHistoryScreen extends StatefulWidget {
  const BonusHistoryScreen({super.key});

  static const routeName = '/bonus-history';

  @override
  State<BonusHistoryScreen> createState() => _BonusHistoryScreenState();
}

class _BonusHistoryScreenState extends State<BonusHistoryScreen> {
  late final BonusHistoryProvider _provider;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _provider = BonusHistoryProvider();
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
        title: const Text('История бонусов'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.isLoading && _provider.transactions.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (_provider.errorMessage != null &&
              _provider.transactions.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: _BonusHistoryError(
                message: _provider.errorMessage!,
                onRetry: _load,
              ),
            );
          }

          if (_provider.transactions.isEmpty) {
            return RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: const _BonusHistoryEmpty(),
            );
          }

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              itemCount: _provider.transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _BonusTransactionCard(
                  transaction: _provider.transactions[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _BonusTransactionCard extends StatelessWidget {
  const _BonusTransactionCard({required this.transaction});

  final BonusTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isEarned
        ? AppColors.success
        : transaction.isSpent
            ? Colors.red
            : AppColors.textSecondary;
    final sign = transaction.isEarned
        ? '+'
        : transaction.isSpent
            ? '-'
            : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              transaction.isEarned
                  ? Icons.add_circle_outline_rounded
                  : transaction.isSpent
                      ? Icons.remove_circle_outline_rounded
                      : Icons.stars_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.displayType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  transaction.orderId == null
                      ? 'Без заказа'
                      : 'Заказ #${transaction.orderId}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(transaction.createdAt),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Text(
            '$sign${_formatAmount(transaction.amount)} ★',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day.$month.${value.year} $hour:$minute';
  }
}

class _BonusHistoryEmpty extends StatelessWidget {
  const _BonusHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 80, 18, 28),
      children: [
        const Icon(Icons.stars_rounded,
            size: 64, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          'У вас пока нет бонусов',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

class _BonusHistoryError extends StatelessWidget {
  const _BonusHistoryError({
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
