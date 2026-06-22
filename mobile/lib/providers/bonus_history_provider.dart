import 'package:flutter/foundation.dart';

import '../models/bonus_transaction.dart';
import '../services/bonus_service.dart';

class BonusHistoryProvider extends ChangeNotifier {
  BonusHistoryProvider({BonusService? bonusService})
      : _bonusService = bonusService ?? BonusService();

  final BonusService _bonusService;

  bool _isLoading = false;
  String? _errorMessage;
  List<BonusTransaction> _transactions = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BonusTransaction> get transactions => List.unmodifiable(_transactions);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _bonusService.getHistory();
    } catch (error) {
      _errorMessage = 'Не удалось загрузить историю бонусов';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
