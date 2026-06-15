import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/bonus_balance.dart';
import '../providers/auth_provider.dart';
import '../services/bonus_service.dart';
import '../theme/app_colors.dart';
import 'login_screen.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  final _bonusService = BonusService();

  late Future<BonusBalance> _balanceFuture;
  bool _isRedirecting = false;

  @override
  void initState() {
    super.initState();
    _balanceFuture = _bonusService.getBalance();
  }

  Future<void> _refresh() async {
    try {
      await AuthScope.of(context, listen: false).refreshCurrentUser();
    } catch (_) {
      _redirectToLogin();
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _balanceFuture = _bonusService.getBalance();
    });
  }

  void _redirectToLogin({bool logout = false}) {
    if (_isRedirecting) {
      return;
    }

    _isRedirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      if (logout) {
        await AuthScope.of(context, listen: false).logout();
      }

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
    // TODO: Disable screenshots/screen recording on Android for the QR screen.
    // TODO: Replace permanent QR with a dynamic QR token when security rules require it.
    final authProvider = AuthScope.of(context);
    final user = authProvider.currentUser;

    if (authProvider.status == AuthStatus.unauthenticated) {
      _redirectToLogin();
    }

    if (authProvider.status == AuthStatus.checking || user == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    return FutureBuilder<BonusBalance>(
      future: _balanceFuture,
      builder: (context, snapshot) {
        final error = snapshot.error;
        if (_isUnauthorized(error)) {
          _redirectToLogin(logout: true);
        }

        final balance = snapshot.data?.balance;
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final hasError = snapshot.hasError && !_isUnauthorized(error);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            Text('Мой QR', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 18),
            _BalanceCard(
              balance: balance,
              isLoading: isLoading,
              hasError: hasError,
            ),
            const SizedBox(height: 34),
            _QrBlock(qrCode: user.qrCode),
            const SizedBox(height: 22),
            Text(
              'Покажите QR-код кассиру для начисления или списания бонусов',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 22),
            _InfoCard(
              text: hasError
                  ? 'Не удалось загрузить баланс. Проверьте подключение.'
                  : 'Баланс обновляется после завершенных заказов.',
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: isLoading ? null : _refresh,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.accentSoft,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : const Text('Обновить'),
            ),
          ],
        );
      },
    );
  }

  bool _isUnauthorized(Object? error) {
    return error is DioException && error.response?.statusCode == 401;
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.isLoading,
    required this.hasError,
  });

  final double? balance;
  final bool isLoading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final value = hasError ? '--' : _formatBalance(balance ?? 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ваш баланс', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                if (isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                else
                  Text(
                    '$value ★',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.star_rounded, size: 34),
          ),
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

class _QrBlock extends StatelessWidget {
  const _QrBlock({required this.qrCode});

  final String? qrCode;

  @override
  Widget build(BuildContext context) {
    final value = qrCode == null || qrCode!.isEmpty ? 'QR-код не создан' : qrCode!;

    return Center(
      child: Container(
        width: 286,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 220,
              height: 220,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: qrCode == null || qrCode!.isEmpty
                  ? const Icon(
                      Icons.qr_code_2_rounded,
                      size: 160,
                      color: AppColors.textPrimary,
                    )
                  : QrImageView(
                      data: value,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.textPrimary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            SelectableText(
              value,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.info_outline_rounded, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
