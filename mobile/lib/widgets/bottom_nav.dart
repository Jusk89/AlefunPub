import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Главная'),
        BottomNavigationBarItem(icon: Icon(Icons.campaign_rounded), label: 'Афиши'),
        BottomNavigationBarItem(icon: Icon(Icons.qr_code_rounded), label: 'QR'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Профиль'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz_rounded), label: 'Еще'),
      ],
    );
  }
}
