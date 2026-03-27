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
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';
import 'shop_screen.dart';

/// In-session cart item (local, not backend cart)
class _SessionItem {
  final ProductModel product;
  int quantity;
  _SessionItem(this.product, {this.quantity = 1});
  double get total => product.priceInr * quantity;
}

class StoreSessionScreen extends StatefulWidget {
  final SupermarketInfo store;
  const StoreSessionScreen({super.key, required this.store});

  @override
  State<StoreSessionScreen> createState() => _StoreSessionScreenState();
}

class _StoreSessionScreenState extends State<StoreSessionScreen>
    with SingleTickerProviderStateMixin {
  final _apiService = sl<ApiService>();
  MobileScannerController? _controller;
  bool _cameraFailed = false;
  bool _torchOn = false;
  bool _hasScanned = false;
  bool _showCart = false;

  final List<_SessionItem> _cart = [];
  String? _lastAddedName;

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

  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.total);
  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);

  Future<void> _vibrate() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        Vibration.vibrate(duration: 150, amplitude: 128);
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    setState(() => _hasScanned = true);
    _vibrate();
    _lookupAndAdd(rawValue);
  }

  Future<void> _lookupAndAdd(String barcode) async {
    try {
      final data = await _apiService.getProductByBarcode(barcode);
      final product = ProductModel.fromJson(data['product']);
      if (mounted) _addToSessionCart(product);
    } catch (e) {
      if (mounted) {
        _showNotFoundSnackbar(barcode);
        // Allow re-scan after 1.5s
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _hasScanned = false);
        });
      }
    }
  }

  void _addToSessionCart(ProductModel product) {
    setState(() {
      final existing = _cart.indexWhere((i) => i.product.id == product.id);
      if (existing >= 0) {
        _cart[existing].quantity++;
      } else {
        _cart.add(_SessionItem(product));
      }
      _lastAddedName = product.name;
    });

    // Show added confirmation & allow re-scan after 1s
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _hasScanned = false;
          _lastAddedName = null;
        });
      }
    });
  }

  void _showNotFoundSnackbar(String barcode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Product not found: $barcode'),
        backgroundColor: AppColors.yellow,
        action: SnackBarAction(
          label: 'OK',
          textColor: AppColors.background,
          onPressed: () {},
        ),
      ),
    );
  }

  void _removeItem(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      _cart[index].quantity += delta;
      if (_cart[index].quantity <= 0) _cart.removeAt(index);
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    // Push all items to backend cart, then navigate to checkout
    try {
      // Clear backend cart first
      await _apiService.clearCart();

      // Add each item
      for (final item in _cart) {
        await _apiService.addToCart(item.product.id, quantity: item.quantity);
      }

      if (mounted) {
        context.push('/checkout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Camera ──
          if (!_cameraFailed && _controller != null)
            MobileScanner(
              controller: _controller!,
              onDetect: _onDetect,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.background,
                child: const Center(
                  child: Icon(Icons.camera_alt_outlined,
                      size: 64, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Container(
              color: AppColors.background,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.qr_code_scanner_rounded,
                      size: 80, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('Camera Preview', style: AppTextStyles.titleSmall),
                ]),
              ),
            ),

          // ── Dark overlay ──
          Container(color: Colors.black.withValues(alpha: 0.45)),

          // ── Scan frame ──
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3), width: 2),
              ),
              child: Stack(children: [
                ..._buildCorners(),
                _buildScanLine(),
              ]),
            ),
          ),

          // ── Top bar with store info ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 8,
                  right: 12,
                  bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.store.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.store.icon,
                        color: widget.store.accentColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.store.name,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Scan items to add to cart',
                            style: AppTextStyles.caption.copyWith(fontSize: 10)),
                      ],
                    ),
                  ),
                  // Torch
                  IconButton(
                    icon: Icon(
                      _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                      color: _torchOn ? AppColors.accent : Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      _controller?.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── "Item added" toast ──
          if (_lastAddedName != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 40,
              right: 40,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_lastAddedName!} added to cart',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: -0.3, duration: 300.ms),
            ),

          // ── Bottom cart bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.97),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border:
                    const Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cart summary bar
                    GestureDetector(
                      onTap: () => setState(() => _showCart = !_showCart),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                children: [
                                  const Center(
                                    child: Icon(Icons.shopping_cart_rounded,
                                        color: AppColors.accent, size: 22),
                                  ),
                                  if (_cartCount > 0)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: AppColors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('$_cartCount',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cartCount == 0
                                        ? 'Cart is empty'
                                        : '$_cartCount item${_cartCount > 1 ? 's' : ''} in cart',
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  if (_cartCount > 0)
                                    Text(
                                      CurrencyFormatter.formatInr(_cartTotal),
                                      style: AppTextStyles.captionMedium
                                          .copyWith(color: AppColors.accent),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              _showCart
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expanded cart items
                    if (_showCart && _cart.isNotEmpty)
                      Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 8),
                          itemCount: _cart.length,
                          itemBuilder: (_, i) {
                            final item = _cart[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.product.name,
                                            style: AppTextStyles.bodyMedium,
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis),
                                        Text(
                                          CurrencyFormatter.formatInr(
                                              item.product.priceInr),
                                          style: AppTextStyles.caption,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Qty controls
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _qtyBtn(Icons.remove, () => _updateQuantity(i, -1)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text('${item.quantity}',
                                            style: AppTextStyles.bodyMedium),
                                      ),
                                      _qtyBtn(Icons.add, () => _updateQuantity(i, 1)),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyFormatter.formatInr(item.total),
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(color: AppColors.accent),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    // Checkout button
                    if (_cart.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: KkButton(
                          label:
                              'Checkout  •  ${CurrencyFormatter.formatInr(_cartTotal)}',
                          icon: Icons.shopping_cart_checkout_rounded,
                          onTap: _checkout,
                        ),
                      ),

                    if (_cart.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: Text('Scan product barcodes to start shopping',
                            style: AppTextStyles.caption),
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

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const s = 28.0, w = 3.0;
    const c = AppColors.accent;
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.transparent, AppColors.accent, Colors.transparent]),
          ),
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .slideY(begin: 0, end: 110, duration: 2500.ms, curve: Curves.easeInOut);
  }
}
