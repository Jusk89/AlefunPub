import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService})
      : _authService = authService ?? AuthService();

  final AuthService _authService;

  AuthStatus _status = AuthStatus.checking;
  User? _currentUser;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    final hasToken = await _authService.isLoggedIn();
    if (!hasToken) {
      _setUnauthenticated();
      return;
    }

    try {
      await refreshCurrentUser();
    } catch (_) {
      // Startup should settle into the unauthenticated state without crashing UI.
    }
  }

  Future<void> login(String email, String password) async {
    await _authService.login(email, password);
    await refreshCurrentUser();
  }

  Future<bool> register({
    required String fullName,
    required String phone,
    required String email,
    required String password,
    required String birthDate,
  }) async {
    final hasToken = await _authService.register(
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      birthDate: birthDate,
    );

    if (hasToken) {
      await refreshCurrentUser();
    }

    return hasToken;
  }

  Future<void> refreshCurrentUser() async {
    _status = AuthStatus.checking;
    notifyListeners();

    try {
      _currentUser = await _authService.getMe();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (_) {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _setUnauthenticated();
  }

  void _setUnauthenticated() {
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthProvider> {
  const AuthScope({
    required AuthProvider authProvider,
    required super.child,
    super.key,
  }) : super(notifier: authProvider);

  static AuthProvider of(BuildContext context, {bool listen = true}) {
    final AuthScope? scope;
    if (listen) {
      scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    } else {
      final element = context.getElementForInheritedWidgetOfExactType<AuthScope>();
      scope = element?.widget as AuthScope?;
    }

    assert(scope != null, 'AuthScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
