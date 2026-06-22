import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/qr_client.dart';
import '../../providers/auth_provider.dart';
import '../../services/qr_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/backend_error.dart';
import '../login_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final _qrController = TextEditingController();
  final _qrService = QrService();

  QrClient? _client;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final qrCode = _qrController.text.trim();
    if (qrCode.isEmpty) {
      setState(() => _errorMessage = 'Введите или отсканируйте QR-код клиента.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = await _qrService.lookupClient(qrCode);
      if (!mounted) {
        return;
      }
      setState(() => _client = client);
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
        _client = null;
        _errorMessage = backendErrorMessage(
          error,
          fallback: 'Не удалось найти клиента по QR-коду.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCamera() async {
    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _QrScannerPage()),
    );
    if (scannedCode == null || scannedCode.trim().isEmpty || !mounted) {
      return;
    }
    _qrController.text = scannedCode.trim();
    await _lookup();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        Text('Скан QR', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, size: 54),
              ),
              const SizedBox(height: 18),
              Text('Сканируйте QR клиента', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('Можно вставить код из внешнего сканера', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _qrController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _lookup(),
          decoration: InputDecoration(
            labelText: 'QR-код клиента',
            hintText: 'uuid-string',
            prefixIcon: const Icon(Icons.qr_code_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _openCamera,
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('ОТКРЫТЬ КАМЕРУ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _lookup,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search_rounded),
                label: const Text('НАЙТИ'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textPrimary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
              ),
            ),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 18),
        if (_client != null) _ClientBonusCard(client: _client!),
      ],
    );
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final _controller = MobileScannerController();
  bool _isReturning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_isReturning || capture.barcodes.isEmpty) {
      return;
    }

    final value = capture.barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) {
      return;
    }

    _isReturning = true;
    Navigator.of(context).pop(value.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Скан QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent, width: 3),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 28,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Наведите камеру на QR-код клиента',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientBonusCard extends StatelessWidget {
  const _ClientBonusCard({required this.client});

  final QrClient client;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_rounded),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(client.fullName, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(client.phone, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  'Баланс: ${client.currentBonusBalance.toStringAsFixed(0)} ★',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
