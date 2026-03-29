import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/qr_classifier.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/wallet_service.dart';
import '../../../core/service_locator.dart';
import '../../../core/utils/wallet_display.dart';

class ScannerScreen extends StatefulWidget {
  final bool productMode;
  const ScannerScreen({super.key, this.productMode = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _torchOn = false;
  bool _cameraFailed = false;
  bool _isProcessingImage = false;
  final _apiService = sl<ApiService>();
  final _imagePicker = ImagePicker();
  final _walletService = sl<WalletService>();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  void _initCamera() {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        formats: [BarcodeFormat.all],
      );
    } catch (e) {
      setState(() => _cameraFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 200, amplitude: 128);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {
      HapticFeedback.heavyImpact();
    }
  }

  // ── Live camera scan callback ──
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _hasScanned = true);
    _vibrate();
    _routeScanResult(rawValue);
  }

  // ── Upload QR from Gallery (like PhonePe / GPay) ──
  Future<void> _uploadQRFromGallery() async {
    try {
      // 1. Open native gallery picker
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFile == null) return; // user cancelled

      // 2. Show processing overlay
      setState(() => _isProcessingImage = true);

      // 3. Decode QR/barcode from the picked image
      final BarcodeCapture? result = await _controller?.analyzeImage(pickedFile.path);

      if (!mounted) return;
      setState(() => _isProcessingImage = false);

      if (result != null && result.barcodes.isNotEmpty) {
        final rawValue = result.barcodes.first.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          _vibrate();
          setState(() => _hasScanned = true);
          _routeScanResult(rawValue);
          return;
        }
      }

      // No QR found in image
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No QR code or barcode found in the selected image'),
            backgroundColor: context.palette.yellow,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan image: $e'),
            backgroundColor: context.palette.red,
          ),
        );
      }
    }
  }

  // ── Route to correct screen based on QR type ──
  void _routeScanResult(String rawValue) {
    if (widget.productMode) {
      _lookupProduct(rawValue);
      return;
    }

    final type = QrClassifier.classify(rawValue);

    switch (type) {
      case QrType.upi:
        final parsed = QrClassifier.parseUpi(rawValue);
        // Show UPI/Crypto payment choice dialog instead of navigating directly
        _showPaymentChoiceDialog(
          recipientName: parsed['pn'] ?? 'Unknown',
          recipientUpi: parsed['pa'] ?? '',
          amount: parsed['am'] ?? '',
        );
        break;
      case QrType.cryptoWallet:
        final address = QrClassifier.parseWalletAddress(rawValue);
        context.push('/payment', extra: {
          'recipientName': 'Wallet',
          'recipientWallet': address ?? rawValue,
        });
        break;
      case QrType.productBarcode:
      case QrType.unknown:
        _lookupProduct(rawValue);
        break;
    }
  }

  /// Shows a bottom sheet with UPI / Crypto payment choice after scanning a UPI QR.
  /// The Crypto option uses the user's hardcoded wallet address.
  void _showPaymentChoiceDialog({
    required String recipientName,
    required String recipientUpi,
    required String amount,
  }) {
    final hasWallet = _walletService.isConnected;
    final walletAddress = _walletService.connectedAddress;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.palette.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            // Success icon
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: context.palette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.qr_code_scanner_rounded, color: context.palette.accent, size: 36),
            ),
            const SizedBox(height: 14),
            Text('QR Scanned!', style: context.txt.titleSmall),
            const SizedBox(height: 6),
            Text(
              recipientName,
              style: context.txt.bodyMedium.copyWith(color: context.palette.accent),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (amount.isNotEmpty)
              Text('Amount: ₹$amount', style: context.txt.caption),
            const SizedBox(height: 24),

            Text('Choose payment method', style: context.txt.bodyMedium),
            const SizedBox(height: 16),

            // UPI Option
            _paymentOptionTile(
              icon: Icons.send_rounded,
              title: 'Pay via UPI',
              subtitle: 'Razorpay secure payment',
              color: context.palette.accentBlue,
              onTap: () {
                Navigator.pop(ctx);
                context.push('/payment', extra: {
                  'recipientName': recipientName,
                  'recipientUpi': recipientUpi,
                  'amount': amount,
                });
              },
            ),

            const SizedBox(height: 10),

            // Crypto Option
            _paymentOptionTile(
              icon: Icons.currency_bitcoin,
              title: 'Pay via Crypto',
              subtitle: hasWallet
                  ? 'Using ${shortenWalletAddress(walletAddress)}'
                  : 'Connect a wallet first',
              color: context.palette.accent,
              enabled: hasWallet,
              onTap: hasWallet
                  ? () {
                      Navigator.pop(ctx);
                      context.push('/payment', extra: {
                        'recipientName': recipientName,
                        'recipientWallet': walletAddress,
                        'amount': amount,
                      });
                    }
                  : null,
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetScanner();
              },
              child: Text('Cancel', style: context.txt.bodyMedium.copyWith(color: context.palette.textSecondary)),
            ),
          ],
        ),
        ),
      ),
    ).whenComplete(() {
      if (mounted) _resetScanner();
    });
  }

  /// A styled payment option tile for the choice dialog.
  Widget _paymentOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: enabled ? context.palette.surface : context.palette.surface2.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: enabled ? color.withValues(alpha: 0.4) : context.palette.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: enabled ? 0.15 : 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: enabled ? color : context.palette.textSecondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.txt.bodyMedium.copyWith(
                    color: enabled ? context.palette.textPrimary : context.palette.textSecondary,
                  )),
                  Text(
                    subtitle,
                    style: context.txt.caption.copyWith(fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14,
                color: enabled ? color : context.palette.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _lookupProduct(String barcode) async {
    try {
      final data = await _apiService.getProductByBarcode(barcode);
      final product = ProductModel.fromJson(data['product']);
      if (mounted) _showProductDialog(product);
    } catch (e) {
      if (mounted) _showProductNotFoundDialog(barcode);
    }
  }

  void _showProductDialog(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.palette.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: context.palette.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.check_circle_rounded, color: context.palette.accent, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Product Found!', style: context.txt.titleSmall),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(children: [
                _detailRow('Name', product.name),
                Divider(color: context.palette.border),
                _detailRow('Price', CurrencyFormatter.formatInr(product.priceInr)),
                Divider(color: context.palette.border),
                _detailRow('Barcode', product.barcode),
                if (product.category.isNotEmpty) ...[
                  Divider(color: context.palette.border),
                  _detailRow('Category', product.category),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: KkButton(label: 'Add to Cart', icon: Icons.add_shopping_cart, height: 48,
                  onTap: () async {
                    try {
                      await _apiService.addToCart(product.id);
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: context.palette.green));
                        _resetScanner();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Failed to add to cart'), backgroundColor: context.palette.red));
                      }
                    }
                  }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KkButton(label: 'Buy Now', icon: Icons.flash_on, outlined: true, height: 48,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/payment', extra: {
                      'recipientName': 'KryptoMart Store',
                      'recipientUpi': 'kryptomart@upi',
                      'amount': product.priceInr.toString(),
                    });
                  }),
              ),
            ]),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () { Navigator.pop(ctx); _resetScanner(); },
              child: Text('Scan Again', style: context.txt.bodyMedium.copyWith(color: context.palette.textSecondary)),
            ),
            ],
          ),
        ),
      ),
    ).whenComplete(() { if (mounted) _resetScanner(); });
  }

  void _showProductNotFoundDialog(String barcode) {
    final nameC = TextEditingController();
    final priceC = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: context.palette.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: context.palette.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: context.palette.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20)),
              child: Icon(Icons.help_outline_rounded, color: context.palette.yellow, size: 48),
            ),
            const SizedBox(height: 10),
            Text('Product Not Found', style: context.txt.titleSmall),
            const SizedBox(height: 8),
            Text('Barcode: $barcode', style: context.txt.caption),
            const SizedBox(height: 16),
            Text('Would you like to add this product?',
                style: context.txt.body.copyWith(color: context.palette.textSecondary)),
            const SizedBox(height: 20),
            TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Product Name')),
            const SizedBox(height: 12),
            TextField(controller: priceC, keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (INR)')),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: KkButton(label: 'Add Product', height: 48,
                  onTap: () async {
                    if (nameC.text.isEmpty || priceC.text.isEmpty) return;
                    try {
                      await _apiService.createProduct({
                        'name': nameC.text,
                        'priceInr': double.tryParse(priceC.text) ?? 0,
                        'barcode': barcode,
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${nameC.text} added!'), backgroundColor: context.palette.green));
                        _resetScanner();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: context.palette.red));
                      }
                    }
                  }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KkButton(label: 'Cancel', outlined: true, height: 48,
                  onTap: () { Navigator.pop(ctx); _resetScanner(); }),
              ),
            ]),
            ],
          ),
        ),
      ),
    ).whenComplete(() { if (mounted) _resetScanner(); });
  }

  void _resetScanner() {
    setState(() => _hasScanned = false);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: context.txt.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              style: context.txt.bodyMedium,
              textAlign: TextAlign.end,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Camera preview ──
          if (!_cameraFailed && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
              errorBuilder: (context, error, widget) {
                return Container(
                  color: context.palette.background,
                  child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.camera_alt_outlined, size: 64, color: context.palette.textSecondary),
                    const SizedBox(height: 16),
                    Text('Camera not available', style: context.txt.body.copyWith(color: context.palette.textSecondary)),
                  ])),
                );
              },
            )
          else
            Container(
              color: context.palette.background,
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.qr_code_scanner_rounded, size: 80, color: context.palette.textSecondary),
                const SizedBox(height: 16),
                Text('Camera Preview', style: context.txt.titleSmall),
                Text('Requires physical device', style: context.txt.caption),
              ])),
            ),

          // ── Semi-transparent overlay ──
          Container(color: Colors.black.withValues(alpha: 0.5)),

          // ── Scan frame ──
          Center(
            child: Container(
              width: 260, height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.palette.accent.withValues(alpha: 0.3), width: 2),
              ),
              child: Stack(children: [..._buildCorners(), _buildScanLine()]),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02), duration: 1500.ms),
          ),

          // ── Top bar ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8, left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) { context.pop(); } else { context.go('/home'); }
                  },
                ),
                const SizedBox(width: 8),
                Text('Scan QR / Barcode', style: context.txt.titleSmall),
              ]),
            ),
          ),

          // ── Bottom panel: Torch + Upload QR ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: context.palette.surface.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: context.palette.border)),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bottomAction(
                      icon: _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                      label: 'Torch',
                      onTap: () {
                        _controller?.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                    ),
                    _bottomAction(
                      icon: Icons.image_outlined,
                      label: 'Upload QR',
                      onTap: _uploadQRFromGallery,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Processing overlay (shown while decoding gallery image) ──
          if (_isProcessingImage)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 48, height: 48,
                      child: CircularProgressIndicator(
                        color: context.palette.accent, strokeWidth: 3),
                    ),
                    const SizedBox(height: 20),
                    Text('Scanning image...', style: context.txt.bodyMedium),
                    const SizedBox(height: 6),
                    Text('Looking for QR codes and barcodes',
                        style: context.txt.caption),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bottomAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: context.palette.surface2, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: context.palette.textSecondary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(label, style: context.txt.caption),
      ]),
    );
  }

  List<Widget> _buildCorners() {
    const s = 30.0, w = 3.0;
    final c = context.palette.accent;
    return [
      Positioned(top: 0, left: 0, child: Container(width: s, height: w, color: c)),
      Positioned(top: 0, left: 0, child: Container(width: w, height: s, color: c)),
      Positioned(top: 0, right: 0, child: Container(width: s, height: w, color: c)),
      Positioned(top: 0, right: 0, child: Container(width: w, height: s, color: c)),
      Positioned(bottom: 0, left: 0, child: Container(width: s, height: w, color: c)),
      Positioned(bottom: 0, left: 0, child: Container(width: w, height: s, color: c)),
      Positioned(bottom: 0, right: 0, child: Container(width: s, height: w, color: c)),
      Positioned(bottom: 0, right: 0, child: Container(width: w, height: s, color: c)),
    ];
  }

  Widget _buildScanLine() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, context.palette.accent, Colors.transparent]),
          ),
        ),
      ),
    ).animate(onPlay: (c) => c.repeat())
        .slideY(begin: 0, end: 120, duration: 2500.ms, curve: Curves.easeInOut);
  }
}
