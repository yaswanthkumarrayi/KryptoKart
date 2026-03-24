import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../upi/presentation/bloc/upi_bloc.dart';
import '../../../upi/presentation/bloc/upi_event.dart';

enum _QrType { upi, crypto, unknown }

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

      final qrType = _resolveType(raw);
      if (!mounted) return;
      switch (qrType) {
        case _QrType.upi:
          final upiData = _extractUpi(raw);
          if (upiData != null) {
            context.read<UpiBloc>().add(
              UpiPayeeSetEvent(upiId: upiData.$1, payeeName: upiData.$2),
            );
            final amountPart = upiData.$3 > 0 ? '&amount=${upiData.$3}' : '';
            context.go(
              '/payment?type=upi&upiId=${Uri.encodeComponent(upiData.$1)}&payeeName=${Uri.encodeComponent(upiData.$2)}$amountPart',
            );
            return;
          }
          break;
        case _QrType.crypto:
          final wallet = _extractWallet(raw);
          context.go('/payment?type=eth&wallet=${Uri.encodeComponent(wallet)}');
          return;
        case _QrType.unknown:
          break;
      }

      _isHandled = false;
      _showUnknownQrMessage(raw);
      return;
    }
  }

  _QrType _resolveType(String raw) {
    final lower = raw.toLowerCase();
    final hasWallet = RegExp(r'0x[a-fA-F0-9]{40}').hasMatch(raw);
    final hasUpiLike = RegExp(
      r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$',
    ).hasMatch(raw);

    if (lower.startsWith('upi://pay') || hasUpiLike) return _QrType.upi;
    if (lower.startsWith('ethereum:') ||
        lower.startsWith('eth:') ||
        lower.startsWith('crypto:') ||
        hasWallet) {
      return _QrType.crypto;
    }
    return _QrType.unknown;
  }

  (String, String, double)? _extractUpi(String raw) {
    if (raw.startsWith('upi://pay')) {
      final uri = Uri.tryParse(raw);
      if (uri == null) return null;
      final upiId = uri.queryParameters['pa']?.trim() ?? '';
      final payeeName = uri.queryParameters['pn']?.trim() ?? 'Merchant';
      final amount = double.tryParse(uri.queryParameters['am'] ?? '') ?? 0;
      if (upiId.isEmpty) return null;
      return (upiId, payeeName, amount);
    }
    final basic = RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$');
    if (basic.hasMatch(raw)) {
      return (raw, 'Merchant', 0);
    }
    return null;
  }

  String _extractWallet(String raw) {
    final match = RegExp(r'0x[a-fA-F0-9]{40}').firstMatch(raw);
    if (match != null) {
      return match.group(0)!;
    }
    return raw.length > 24 ? '${raw.substring(0, 24)}...' : raw;
  }

  void _showUnknownQrMessage(String raw) {
    context.go('/payment?type=unknown&raw=${Uri.encodeComponent(raw)}');
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
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
              'Scan any UPI or ETH QR code',
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
