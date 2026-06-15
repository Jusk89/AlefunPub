import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BonusBadge extends StatelessWidget {
  const BonusBadge({
    super.key,
    required this.balance,
  });

  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ваши бонусы', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('$balance', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 4),
                Text('можно списать при заказе', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.stars_rounded, size: 32),
          ),
        ],
      ),
    );
  }
}
