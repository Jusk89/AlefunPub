import 'package:flutter/material.dart';

import 'screens/main_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

void main() {
  runApp(const LoyaltyApp());
}

class LoyaltyApp extends StatelessWidget {
  const LoyaltyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ресторан',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          surface: AppColors.background,
        ),
        useMaterial3: true,
        textTheme: AppTextStyles.textTheme,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.textPrimary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 16,
        ),
      ),
      home: const MainShell(),
    );
  }
}
