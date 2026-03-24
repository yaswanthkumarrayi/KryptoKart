import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/upi_bloc.dart';
import '../bloc/upi_event.dart';

class ScanPayPage extends StatefulWidget {
  const ScanPayPage({super.key});

  @override
  State<ScanPayPage> createState() => _ScanPayPageState();
}

class _ScanPayPageState extends State<ScanPayPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: false,
  );

  final TextEditingController _manualUpiController = TextEditingController();
  bool _hasNavigated = false;

  @override
  void dispose() {
    _manualUpiController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasNavigated) return;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null || rawValue.trim().isEmpty) continue;

      final extracted = _extractUpiInfo(rawValue.trim());
      if (extracted == null) continue;

      _continueToPayment(upiId: extracted.$1, payeeName: extracted.$2);
      break;
    }
  }

  (String, String)? _extractUpiInfo(String raw) {
    if (raw.startsWith('upi://pay')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        final upiId = uri.queryParameters['pa']?.trim() ?? '';
        final payeeName = uri.queryParameters['pn']?.trim() ?? 'Merchant';
        if (upiId.isNotEmpty) {
          return (upiId, payeeName.isEmpty ? 'Merchant' : payeeName);
        }
      }
      return null;
    }

    final maybeUpiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,}@[a-zA-Z]{2,}$');
    if (maybeUpiRegex.hasMatch(raw)) {
      return (raw, 'Merchant');
    }

    return null;
  }

  void _continueToPayment({required String upiId, required String payeeName}) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    context.read<UpiBloc>().add(
      UpiPayeeSetEvent(upiId: upiId, payeeName: payeeName),
    );

    _scannerController.stop();
    context.push('/upi/pay').then((_) {
      if (!mounted) return;
      setState(() => _hasNavigated = false);
      _scannerController.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan & Pay')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: _onDetect,
                      ),
                      Align(
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white70, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Point your camera at a UPI QR code or enter a UPI ID manually.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _manualUpiController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Enter UPI ID',
                  hintText: 'merchant@bank',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
            ),
            PrimaryButton(
              onPressed: () {
                final upiId = _manualUpiController.text.trim();
                final info = _extractUpiInfo(upiId);
                if (info == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid UPI ID or scan a valid UPI QR.',
                      ),
                    ),
                  );
                  return;
                }

                _continueToPayment(upiId: info.$1, payeeName: info.$2);
              },
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}
