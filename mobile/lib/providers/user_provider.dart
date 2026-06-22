import 'package:flutter/material.dart';

import '../models/user.dart';

class UserProvider extends ChangeNotifier {
  User? _user;

  User? get user => _user;
  String get role => _user?.role ?? 'client';
  bool get isCashier => role == 'cashier';
  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  void clear() {
    _user = null;
    notifyListeners();
  }
}
