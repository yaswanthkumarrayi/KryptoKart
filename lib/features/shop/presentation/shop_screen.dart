import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/product_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';
import '../../scanner/presentation/scanner_screen.dart';

class ShopScreen extends StatefulWidget {
  final String? initialBarcode;
  const ShopScreen({super.key, this.initialBarcode});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final _apiService = sl<ApiService>();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      _lookupBarcode(widget.initialBarcode!);
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await _apiService.getProducts();
      setState(() {
        _products = (data['products'] as List)
            .map((j) => ProductModel.fromJson(j))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _lookupBarcode(String barcode) async {
    try {
      final data = await _apiService.getProductByBarcode(barcode);
      final product = ProductModel.fromJson(data['product']);
      if (mounted) {
        _showProductDetail(product);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Product not found for barcode: $barcode'),
              backgroundColor: AppColors.yellow),
        );
      }
    }
  }

  Future<void> _addToCart(ProductModel product) async {
    try {
      await _apiService.addToCart(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${product.name} added to cart'),
              backgroundColor: AppColors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error adding to cart'),
              backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(productMode: true),
      ),
    ).then((_) => _loadProducts());
  }

  void _showProductDetail(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 12),
            Text(product.name, style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(CurrencyFormatter.formatInr(product.priceInr),
                style: AppTextStyles.numberSmall.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            Text('Barcode: ${product.barcode}', style: AppTextStyles.caption),
            if (product.category.isNotEmpty)
              Text('Category: ${product.category}', style: AppTextStyles.caption),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: KkButton(
                    label: 'Add to Cart',
                    icon: Icons.add_shopping_cart,
                    height: 48,
                    onTap: () async {
                      await _addToCart(product);
                      if (mounted) Navigator.pop(ctx);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KkButton(
                    label: 'Buy Now',
                    outlined: true,
                    icon: Icons.flash_on,
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Shop & Go'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _openScanner,
            tooltip: 'Scan Barcode',
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart_outlined),
              ],
            ),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: () async => _loadProducts(),
              child: Column(
                children: [
                  // Scan banner
                  GestureDetector(
                    onTap: _openScanner,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_scanner_rounded,
                              color: AppColors.background, size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Scan to Add',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.background,
                                        fontWeight: FontWeight.bold)),
                                Text('Scan product barcode to find & add items',
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.background
                                            .withValues(alpha: 0.8))),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: AppColors.background, size: 16),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().slideX(begin: -0.1),

                  const SizedBox(height: 8),

                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border)),
                      child: TextField(
                        style: AppTextStyles.body,
                        decoration: const InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: Icon(Icons.search,
                                color: AppColors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14)),
                        onChanged: (q) async {
                          final data = await _apiService.getProducts(search: q);
                          setState(() {
                            _products = (data['products'] as List)
                                .map((j) => ProductModel.fromJson(j))
                                .toList();
                          });
                        },
                      ),
                    ),
                  ),

                  // Product grid
                  Expanded(
                    child: _products.isEmpty
                        ? Center(
                            child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  size: 64,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 16),
                              Text('No products yet',
                                  style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  KkButton(
                                      label: 'Scan',
                                      width: 120,
                                      height: 44,
                                      icon: Icons.qr_code_scanner,
                                      onTap: _openScanner),
                                  const SizedBox(width: 12),
                                  KkButton(
                                      label: 'Add',
                                      width: 120,
                                      height: 44,
                                      outlined: true,
                                      icon: Icons.add,
                                      onTap: _showAddDialog),
                                ],
                              ),
                            ],
                          ))
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.85),
                            itemCount: _products.length,
                            itemBuilder: (_, i) {
                              final p = _products[i];
                              return GlassCard(
                                onTap: () => _showProductDetail(p),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        height: 60,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            color: AppColors.surface2,
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: const Icon(
                                            Icons.inventory_2_outlined,
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 10),
                                    Text(p.name,
                                        style: AppTextStyles.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    const Spacer(),
                                    Row(children: [
                                      Text(
                                          CurrencyFormatter.formatInr(
                                              p.priceInr),
                                          style: AppTextStyles.bodyMedium
                                              .copyWith(
                                                  color: AppColors.accent)),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _addToCart(p),
                                        child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: const Icon(Icons.add,
                                                color: AppColors.accent,
                                                size: 18)),
                                      ),
                                    ]),
                                  ],
                                ),
                              )
                                  .animate()
                                  .fadeIn(
                                      delay:
                                          Duration(milliseconds: 80 * i));
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }

  void _showAddDialog() {
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final barcodeC = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Product', style: AppTextStyles.titleSmall),
            const SizedBox(height: 16),
            TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'Product Name')),
            const SizedBox(height: 12),
            TextField(
                controller: priceC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (INR)')),
            const SizedBox(height: 12),
            TextField(
                controller: barcodeC,
                decoration: const InputDecoration(labelText: 'Barcode (optional)')),
            const SizedBox(height: 20),
            KkButton(
              label: 'Add Product',
              onTap: () async {
                if (nameC.text.isEmpty) return;
                try {
                  await _apiService.createProduct({
                    'name': nameC.text,
                    'priceInr': double.tryParse(priceC.text) ?? 0,
                    'barcode': barcodeC.text.isNotEmpty
                        ? barcodeC.text
                        : DateTime.now()
                            .millisecondsSinceEpoch
                            .toString()
                            .substring(0, 10),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    _loadProducts();
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
              height: 48,
            ),
          ],
        ),
      ),
    );
  }
}
