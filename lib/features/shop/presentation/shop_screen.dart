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
  List<ProductModel> _allProducts = []; // Unfiltered list
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _sortBy = 'name'; // 'name', 'price_asc', 'price_desc'

  // Category → icon/color mapping for better visuals
  static const _categoryStyles = <String, Map<String, dynamic>>{
    'Beverages': {'icon': Icons.local_drink, 'color': 0xFF2196F3},
    'Electronics': {'icon': Icons.devices, 'color': 0xFF9C27B0},
    'Snacks': {'icon': Icons.fastfood, 'color': 0xFFFF9800},
    'Dairy': {'icon': Icons.egg, 'color': 0xFF4CAF50},
    'Personal Care': {'icon': Icons.face, 'color': 0xFFE91E63},
    'General': {'icon': Icons.inventory_2_outlined, 'color': 0xFF607D8B},
  };

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
      final products = (data['products'] as List)
          .map((j) => ProductModel.fromJson(j))
          .toList();
      setState(() {
        _allProducts = products;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<ProductModel>.from(_allProducts);

    // Category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((p) =>
          p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'price_asc':
        filtered.sort((a, b) => a.priceInr.compareTo(b.priceInr));
        break;
      case 'price_desc':
        filtered.sort((a, b) => b.priceInr.compareTo(a.priceInr));
        break;
      default:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    _products = filtered;
  }

  List<String> get _categories {
    final cats = _allProducts.map((p) => p.category.isNotEmpty ? p.category : 'General').toSet().toList();
    cats.sort();
    return ['All', ...cats];
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

  /// Gets the icon and color for a product's category.
  Map<String, dynamic> _getCategoryStyle(String category) {
    return _categoryStyles[category] ?? _categoryStyles['General']!;
  }

  void _showProductDetail(ProductModel product) {
    final catStyle = _getCategoryStyle(product.category.isNotEmpty ? product.category : 'General');
    final catColor = Color(catStyle['color'] as int);

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
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(catStyle['icon'] as IconData, color: catColor, size: 36),
            ),
            const SizedBox(height: 12),
            Text(product.name, style: AppTextStyles.titleSmall),
            const SizedBox(height: 4),
            Text(CurrencyFormatter.formatInr(product.priceInr),
                style: AppTextStyles.numberSmall.copyWith(color: AppColors.accent)),
            const SizedBox(height: 8),
            if (product.category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(product.category, style: AppTextStyles.caption.copyWith(color: catColor, fontSize: 11)),
              ),
            const SizedBox(height: 4),
            Text('Barcode: ${product.barcode}', style: AppTextStyles.caption),
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
          // Sort dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded, color: Colors.white),
            color: AppColors.surface,
            onSelected: (v) => setState(() { _sortBy = v; _applyFilters(); }),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'name', child: Text('Sort by Name', style: AppTextStyles.bodyMedium)),
              PopupMenuItem(value: 'price_asc', child: Text('Price: Low → High', style: AppTextStyles.bodyMedium)),
              PopupMenuItem(value: 'price_desc', child: Text('Price: High → Low', style: AppTextStyles.bodyMedium)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: _openScanner,
            tooltip: 'Scan Barcode',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          if (q.isEmpty) {
                            setState(() => _applyFilters());
                            return;
                          }
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

                  // Category filter chips
                  if (_allProducts.isNotEmpty)
                    SizedBox(
                      height: 48,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              selectedColor: AppColors.accent.withValues(alpha: 0.2),
                              onSelected: (_) => setState(() {
                                _selectedCategory = cat;
                                _applyFilters();
                              }),
                              side: BorderSide(
                                color: isSelected ? AppColors.accent : AppColors.border,
                              ),
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.accent : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
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
                              Text(_selectedCategory != 'All' ? 'No $_selectedCategory products' : 'No products yet',
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
                                    childAspectRatio: 0.82),
                            itemCount: _products.length,
                            itemBuilder: (_, i) {
                              final p = _products[i];
                              final catStyle = _getCategoryStyle(
                                  p.category.isNotEmpty ? p.category : 'General');
                              final catColor = Color(catStyle['color'] as int);

                              return GlassCard(
                                onTap: () => _showProductDetail(p),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Category-colored icon header
                                    Container(
                                        height: 60,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                            color: catColor.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Icon(
                                            catStyle['icon'] as IconData,
                                            color: catColor,
                                            size: 28)),
                                    const SizedBox(height: 10),
                                    Text(p.name,
                                        style: AppTextStyles.bodyMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    if (p.category.isNotEmpty)
                                      Text(p.category,
                                          style: AppTextStyles.caption.copyWith(
                                              color: catColor, fontSize: 10)),
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
                                            width: 30,
                                            height: 30,
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
