import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class QrScreen extends StatelessWidget {
  const QrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Disable screenshots/screen recording on Android for the QR screen.
    // TODO: Replace this mock permanent QR with a dynamic QR token when security rules require it.
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        Text('Мой QR', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        const _BalanceCard(),
        const SizedBox(height: 34),
        const _QrBlock(),
        const SizedBox(height: 22),
        Text(
          'Покажите QR-код кассиру для начисления или списания бонусов',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 22),
        const _ExpiringBonusCard(),
        const SizedBox(height: 22),
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Text('Обновить'),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
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
                Text('1250 ★', style: Theme.of(context).textTheme.headlineLarge),
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
}

class _QrBlock extends StatelessWidget {
  const _QrBlock();

  @override
  Widget build(BuildContext context) {
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
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 174,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text('MOCK-QR-CLIENT-001', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ExpiringBonusCard extends StatelessWidget {
  const _ExpiringBonusCard();

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
            child: const Icon(Icons.schedule_rounded, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '200 ★ сгорят 15 июля',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
