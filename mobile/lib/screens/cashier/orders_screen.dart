import 'package:flutter/material.dart';

import '../../models/qr_order_result.dart';
import '../../providers/auth_provider.dart';
import '../../services/qr_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/backend_error.dart';
import '../login_screen.dart';

class CashierOrdersScreen extends StatefulWidget {
  const CashierOrdersScreen({super.key});

  @override
  State<CashierOrdersScreen> createState() => _CashierOrdersScreenState();
}

class _CashierOrdersScreenState extends State<CashierOrdersScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qrController = TextEditingController();
  final _branchController = TextEditingController(
    text: const String.fromEnvironment('BRANCH_ID', defaultValue: '1'),
  );
  final _amountController = TextEditingController();
  final _qrService = QrService();

  bool _useBonuses = false;
  bool _isLoading = false;
  String _paymentMethod = 'cash';
  String? _errorMessage;
  QrOrderResult? _result;

  @override
  void dispose() {
    _qrController.dispose();
    _branchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _qrService.createOrderFromQr(
        qrCode: _qrController.text,
        branchId: int.parse(_branchController.text.trim()),
        totalAmount: double.parse(_amountController.text.trim().replaceAll(',', '.')),
        paymentMethod: _paymentMethod,
        useBonuses: _useBonuses,
      );
      if (!mounted) {
        return;
      }
      setState(() => _result = result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (isUnauthorized(error)) {
        await AuthScope.of(context, listen: false).logout();
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushNamedAndRemoveUntil(LoginScreen.routeName, (_) => false);
        return;
      }
      setState(() {
        _errorMessage = backendErrorMessage(
          error,
          fallback: 'Не удалось создать заказ.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text('Заказы', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        _Panel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Заказ по QR', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _Input(
                  controller: _qrController,
                  label: 'QR-код клиента',
                  icon: Icons.qr_code_rounded,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Введите QR-код' : null,
                ),
                const SizedBox(height: 12),
                _Input(
                  controller: _branchController,
                  label: 'ID филиала',
                  icon: Icons.storefront_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) => int.tryParse(value?.trim() ?? '') == null ? 'Введите ID филиала' : null,
                ),
                const SizedBox(height: 12),
                _Input(
                  controller: _amountController,
                  label: 'Сумма заказа',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      double.tryParse((value ?? '').trim().replaceAll(',', '.')) == null ? 'Введите сумму' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey(_paymentMethod),
                  initialValue: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Оплата',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Наличные')),
                    DropdownMenuItem(value: 'card', child: Text('Карта')),
                    DropdownMenuItem(value: 'online', child: Text('Онлайн')),
                    DropdownMenuItem(value: 'mixed', child: Text('Смешанная')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _paymentMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  value: _useBonuses,
                  onChanged: (value) => setState(() => _useBonuses = value),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Списать доступные бонусы'),
                  subtitle: const Text('Backend сам рассчитает списание и начисление'),
                  activeThumbColor: AppColors.accent,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _createOrder,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('СОЗДАТЬ ЗАКАЗ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textPrimary,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        if (_result != null) _OrderResultCard(result: _result!),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _OrderResultCard extends StatelessWidget {
  const _OrderResultCard({required this.result});

  final QrOrderResult result;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Заказ #${result.orderId}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(result.clientFullName, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          _ResultRow(label: 'Сумма', value: result.totalAmount),
          _ResultRow(label: 'Списано бонусов', value: result.bonusSpent),
          _ResultRow(label: 'Начислено бонусов', value: result.bonusEarned),
          _ResultRow(label: 'К оплате', value: result.finalAmount),
          _ResultRow(label: 'Новый баланс', value: result.newBonusBalance),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value.toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
