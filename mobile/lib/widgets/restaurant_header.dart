import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RestaurantHeader extends StatelessWidget {
  const RestaurantHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.restaurant_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alefun Restaurant', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Бонусы, акции и любимые блюда', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}
