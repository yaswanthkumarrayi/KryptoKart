import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/qr_classifier.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';

class ScannerScreen extends StatefulWidget {
  final bool productMode;
  const ScannerScreen({super.key, this.productMode = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  late String _selectedMode;
  String _statusText = 'Point camera at QR / Barcode';
  bool _torchOn = false;
  bool _cameraFailed = false;
  final _apiService = sl<ApiService>();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.productMode ? 'Product' : 'UPI Pay';
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

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() {
      _hasScanned = true;
      _statusText = 'Detected: ${rawValue.length > 30 ? '${rawValue.substring(0, 30)}...' : rawValue}';
    });

    // Vibrate on scan
    _vibrate();

    // If in product mode, always look up product
    if (_selectedMode == 'Product') {
      _lookupProduct(rawValue);
      return;
    }

    final type = QrClassifier.classify(rawValue);

    switch (type) {
      case QrType.upi:
        final parsed = QrClassifier.parseUpi(rawValue);
        context.push('/payment', extra: {
          'recipientName': parsed['pn'] ?? 'Unknown',
          'recipientUpi': parsed['pa'] ?? '',
          'amount': parsed['am'] ?? '',
        });
        break;
      case QrType.cryptoWallet:
        final address = QrClassifier.parseWalletAddress(rawValue);
        context.push('/payment', extra: {
          'recipientName': 'Wallet',
          'recipientWallet': address ?? rawValue,
        });
        break;
      case QrType.productBarcode:
        _lookupProduct(rawValue);
        break;
      case QrType.unknown:
        // Try product lookup for unknowns too (could be barcode)
        _lookupProduct(rawValue);
        break;
    }
  }

  Future<void> _lookupProduct(String barcode) async {
    try {
      final data = await _apiService.getProductByBarcode(barcode);
      final product = ProductModel.fromJson(data['product']);
      if (mounted) {
        _showProductDialog(product);
      }
    } catch (e) {
      if (mounted) {
        _showProductNotFoundDialog(barcode);
      }
    }
  }

  void _showProductDialog(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Product Found!', style: AppTextStyles.titleSmall),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                children: [
                  _detailRow('Name', product.name),
                  const Divider(color: AppColors.border),
                  _detailRow('Price', CurrencyFormatter.formatInr(product.priceInr)),
                  const Divider(color: AppColors.border),
                  _detailRow('Barcode', product.barcode),
                  if (product.category.isNotEmpty) ...[
                    const Divider(color: AppColors.border),
                    _detailRow('Category', product.category),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: KkButton(
                    label: 'Add to Cart',
                    icon: Icons.add_shopping_cart,
                    height: 48,
                    onTap: () async {
                      try {
                        await _apiService.addToCart(product.id);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('${product.name} added to cart!'),
                                backgroundColor: AppColors.green),
                          );
                          _resetScanner();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Failed to add to cart'),
                                backgroundColor: AppColors.red),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KkButton(
                    label: 'Buy Now',
                    icon: Icons.flash_on,
                    outlined: true,
                    height: 48,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.push('/payment', extra: {
                        'recipientName': 'KryptoMart Store',
                        'recipientUpi': 'kryptomart@upi',
                        'amount': product.priceInr.toString(),
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetScanner();
              },
              child: Text('Scan Again',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) _resetScanner();
    });
  }

  void _showProductNotFoundDialog(String barcode) {
    final nameC = TextEditingController();
    final priceC = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.help_outline_rounded,
                  color: AppColors.yellow, size: 48),
            ),
            const SizedBox(height: 16),
            Text('Product Not Found', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            Text('Barcode: $barcode',
                style: AppTextStyles.caption),
            const SizedBox(height: 16),
            Text('Would you like to add this product?',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Product Name')),
            const SizedBox(height: 12),
            TextField(
                controller: priceC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (INR)')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: KkButton(
                    label: 'Add Product',
                    height: 48,
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
                            SnackBar(
                                content: Text('${nameC.text} added!'),
                                backgroundColor: AppColors.green),
                          );
                          _resetScanner();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.red),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KkButton(
                    label: 'Cancel',
                    outlined: true,
                    height: 48,
                    onTap: () {
                      Navigator.pop(ctx);
                      _resetScanner();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) _resetScanner();
    });
  }

  void _resetScanner() {
    setState(() {
      _hasScanned = false;
      _statusText = 'Point camera at QR / Barcode';
    });
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
              child: Text(value,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera preview
          if (!_cameraFailed && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
              errorBuilder: (context, error, widget) {
                return Container(
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 16),
                        Text('Camera not available',
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              },
            )
          else
            Container(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded,
                        size: 80, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    Text('Camera Preview', style: AppTextStyles.titleSmall),
                    Text('Requires physical device', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),

          // Dark overlay
          Container(color: Colors.black.withValues(alpha: 0.5)),

          // Scan frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3), width: 2),
              ),
              child: Stack(
                children: [
                  ..._buildCorners(),
                  _buildScanLine(),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.02, 1.02),
                    duration: 1500.ms),
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Text('Scan QR / Barcode', style: AppTextStyles.titleSmall),
                ],
              ),
            ),
          ),

          // Mode chips
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['UPI Pay', 'Crypto', 'Product'].map((mode) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(mode),
                    selected: _selectedMode == mode,
                    selectedColor: AppColors.accent.withValues(alpha: 0.2),
                    onSelected: (_) => setState(() => _selectedMode = mode),
                    side: BorderSide(
                      color: _selectedMode == mode
                          ? AppColors.accent
                          : AppColors.border,
                    ),
                    labelStyle: TextStyle(
                      color: _selectedMode == mode
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.95),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bottomAction(
                      icon: _torchOn
                          ? Icons.flashlight_on
                          : Icons.flashlight_off,
                      label: 'Torch',
                      onTap: () {
                        _controller?.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                    ),
                    _bottomAction(
                        icon: Icons.image_outlined,
                        label: 'Upload QR',
                        onTap: () {}),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _hasScanned
                              ? Icons.check_circle
                              : Icons.info_outline,
                          size: 16,
                          color: _hasScanned
                              ? AppColors.green
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 150,
                          child: Text(_statusText,
                              style: AppTextStyles.caption,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 30.0;
    const width = 3.0;
    const color = AppColors.accent;
    return [
      Positioned(
          top: 0,
          left: 0,
          child: Container(width: size, height: width, color: color)),
      Positioned(
          top: 0,
          left: 0,
          child: Container(width: width, height: size, color: color)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(width: size, height: width, color: color)),
      Positioned(
          top: 0,
          right: 0,
          child: Container(width: width, height: size, color: color)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: size, height: width, color: color)),
      Positioned(
          bottom: 0,
          left: 0,
          child: Container(width: width, height: size, color: color)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: size, height: width, color: color)),
      Positioned(
          bottom: 0,
          right: 0,
          child: Container(width: width, height: size, color: color)),
    ];
  }

  Widget _buildScanLine() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          height: 2,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.accent, Colors.transparent],
            ),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .slideY(begin: 0, end: 120, duration: 2500.ms, curve: Curves.easeInOut);
  }
}
