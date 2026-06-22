import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import 'admin/admin_shell.dart';
import 'cashier/cashier_shell.dart';
import 'login_screen.dart';
import 'main_shell.dart';
import 'owner/owner_shell.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  static const routeName = '/role-router';

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthScope.of(context);
    final user = authProvider.currentUser;

    if (authProvider.status == AuthStatus.checking && user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null) {
      return const LoginScreen();
    }

    switch (user.role) {
      case 'cashier':
        return const CashierShell();
      case 'admin':
        return const AdminShell();
      case 'owner':
        return const OwnerShell();
      case 'client':
      default:
        return const MainShell();
    }
  }
}
