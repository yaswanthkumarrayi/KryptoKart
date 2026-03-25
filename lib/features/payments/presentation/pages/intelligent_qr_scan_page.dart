import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../billing/presentation/bloc/billing_bloc.dart';

enum QrPayloadType { upi, crypto, barcode }

class IntelligentQrScanPage extends StatefulWidget {
  const IntelligentQrScanPage({super.key});

  @override
  State<IntelligentQrScanPage> createState() => _IntelligentQrScanPageState();
}

class _IntelligentQrScanPageState extends State<IntelligentQrScanPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );
  late final AnimationController _scanLineController;
  bool _isHandled = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isHandled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) continue;
      _isHandled = true;

      final canVibrate = await Vibration.hasVibrator();
      if (canVibrate == true) {
        Vibration.vibrate(duration: 80);
      }

      if (!mounted) return;

      final type = _classifyQr(raw);
      switch (type) {
        case QrPayloadType.upi:
          _handleUpiQr(raw);
          return;
        case QrPayloadType.crypto:
          _handleCryptoQr(raw);
          return;
        case QrPayloadType.barcode:
          _handleBarcode(raw);
          return;
      }
    }
  }

  QrPayloadType _classifyQr(String raw) {
    final lower = raw.toLowerCase();

    if (lower.startsWith('upi://')) return QrPayloadType.upi;

    final looksLikeUpiId = RegExp(
      r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$',
    ).hasMatch(raw);
    if (looksLikeUpiId) return QrPayloadType.upi;

    if (lower.startsWith('0x') && RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(raw)) {
      return QrPayloadType.crypto;
    }
    if (lower.startsWith('ethereum:') || lower.startsWith('eth:')) {
      return QrPayloadType.crypto;
    }

    return QrPayloadType.barcode;
  }

  void _handleUpiQr(String raw) {
    String upiId = '';
    String payeeName = 'Merchant';
    double amount = 0;

    if (raw.startsWith('upi://')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        upiId = uri.queryParameters['pa']?.trim() ?? '';
        payeeName = uri.queryParameters['pn']?.trim() ?? 'Merchant';
        amount = double.tryParse(uri.queryParameters['am'] ?? '') ?? 0;
      }
    } else {
      upiId = raw;
    }

    if (upiId.isEmpty) {
      _resetAndShowError('Could not parse UPI data from QR');
      return;
    }

    final amountPart = amount > 0 ? '&amount=${amount.toStringAsFixed(2)}' : '';
    context.go(
      '/payment?type=upi'
      '&upiId=${Uri.encodeComponent(upiId)}'
      '&payeeName=${Uri.encodeComponent(payeeName)}'
      '$amountPart',
    );
  }

  void _handleCryptoQr(String raw) {
    final walletMatch = RegExp(r'0x[a-fA-F0-9]{40}').firstMatch(raw);
    final wallet = walletMatch?.group(0) ?? raw;

    context.go('/payment?type=eth&wallet=${Uri.encodeComponent(wallet)}');
  }

  void _handleBarcode(String raw) {
    context.read<BillingBloc>().add(ScanBarcodeEvent(raw));
    context.go('/shopping');
  }

  void _resetAndShowError(String message) {
    _isHandled = false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _toggleFlash() {
    setState(() => _flashOn = !_flashOn);
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Pay'),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(_flashOn ? Icons.flashlight_off : Icons.flashlight_on),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.48),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.62),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 268,
              height: 268,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.neonColor.withValues(alpha: 0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonColor.withValues(alpha: 0.24),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const _ScannerCorner(alignment: Alignment.topLeft),
                  const _ScannerCorner(alignment: Alignment.topRight),
                  const _ScannerCorner(alignment: Alignment.bottomLeft),
                  const _ScannerCorner(alignment: Alignment.bottomRight),
                  AnimatedBuilder(
                    animation: _scanLineController,
                    builder: (context, _) {
                      return Align(
                        alignment: Alignment(
                          0,
                          -1 + (_scanLineController.value * 2),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          height: 2.2,
                          decoration: BoxDecoration(
                            color: AppTheme.neonColor,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.neonColor.withValues(
                                  alpha: 0.55,
                                ),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: Text(
              'Scan UPI QR, ETH wallet, or product barcode',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerCorner extends StatelessWidget {
  final Alignment alignment;

  const _ScannerCorner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppTheme.neonColor, width: 3.2)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppTheme.neonColor, width: 3.2)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppTheme.neonColor, width: 3.2)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppTheme.neonColor, width: 3.2)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
