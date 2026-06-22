import 'package:flutter/material.dart';

import 'campaigns_screen.dart';
import 'menu_management_screen.dart';
import 'profile_screen.dart';
import 'staff_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    this.isOwner = false,
  });

  final bool isOwner;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      const MenuManagementScreen(),
      const AdminCampaignsScreen(),
      StaffScreen(canCreateAdmins: widget.isOwner),
      AdminProfileScreen(isOwner: widget.isOwner),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_rounded), label: 'Меню'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign_rounded), label: 'Афиши'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_rounded), label: 'Персонал'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        ],
      ),
    );
  }
}
