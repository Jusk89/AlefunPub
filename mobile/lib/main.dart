import 'package:flutter/material.dart';

import 'providers/auth_provider.dart';
import 'screens/bonus_history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/my_orders_screen.dart';
import 'screens/register_screen.dart';
import 'screens/role_router.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

void main() {
  runApp(const LoyaltyApp());
}

class LoyaltyApp extends StatefulWidget {
  const LoyaltyApp({super.key});

  @override
  State<LoyaltyApp> createState() => _LoyaltyAppState();
}

class _LoyaltyAppState extends State<LoyaltyApp> {
  late final AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _authProvider.initialize();
  }

  @override
  void dispose() {
    _authProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      authProvider: _authProvider,
      child: MaterialApp(
        title: 'Alefun Pub',
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
        home: const AuthGate(),
        routes: {
          LoginScreen.routeName: (context) => const LoginScreen(),
          RegisterScreen.routeName: (context) => const RegisterScreen(),
          MainShell.routeName: (context) => const MainShell(),
          RoleRouter.routeName: (context) => const RoleRouter(),
          BonusHistoryScreen.routeName: (context) => const BonusHistoryScreen(),
          MyOrdersScreen.routeName: (context) => const MyOrdersScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final authProvider = AuthScope.of(context);

    if (authProvider.status == AuthStatus.checking &&
        authProvider.currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return authProvider.isAuthenticated || authProvider.currentUser != null
        ? const RoleRouter()
        : const LoginScreen();
  }
}
