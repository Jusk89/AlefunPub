import 'package:flutter/material.dart';

import 'orders_screen.dart';
import 'profile_screen.dart';
import 'scan_qr_screen.dart';

class CashierShell extends StatefulWidget {
  const CashierShell({super.key});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ScanQrScreen(),
    CashierOrdersScreen(),
    CashierProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'QR'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Заказы'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
    );
  }
}
