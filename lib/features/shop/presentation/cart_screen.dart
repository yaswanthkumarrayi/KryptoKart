import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/cart_item_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _apiService = sl<ApiService>();
  CartModel? _cart;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _loadCart(); }

  Future<void> _loadCart() async {
    try { final data = await _apiService.getCart(); setState(() { _cart = CartModel.fromJson(data['cart']); _isLoading = false; }); } catch (e) { setState(() => _isLoading = false); }
  }

  Future<void> _updateQty(String pid, int qty) async {
    try { final data = await _apiService.updateCartItem(pid, qty); setState(() => _cart = CartModel.fromJson(data['cart'])); } catch (_) {}
  }

  Future<void> _remove(String pid) async {
    try { final data = await _apiService.removeFromCart(pid); setState(() => _cart = CartModel.fromJson(data['cart'])); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _cart == null || _cart!.items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16), Text('Your cart is empty', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
                ]))
              : Column(children: [
                  Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: _cart!.items.length, itemBuilder: (_, i) {
                    final item = _cart!.items[i];
                    return Dismissible(key: Key(item.product.id), direction: DismissDirection.endToStart, onDismissed: (_) => _remove(item.product.id),
                      background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete, color: AppColors.red)),
                      child: GlassCard(child: Row(children: [
                        Container(width: 50, height: 50, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_outlined, color: AppColors.textSecondary, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.product.name, style: AppTextStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis), Text(CurrencyFormatter.formatInr(item.product.priceInr), style: AppTextStyles.caption)])),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                          _qtyBtn(Icons.remove, () { if (item.quantity > 1) _updateQty(item.product.id, item.quantity - 1); else _remove(item.product.id); }),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${item.quantity}', style: AppTextStyles.bodyMedium)),
                          _qtyBtn(Icons.add, () => _updateQty(item.product.id, item.quantity + 1)),
                        ],
                        ),
                      ])));
                  })),
                  Container(padding: const EdgeInsets.all(20), decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
                    child: SafeArea(child: Column(children: [
                      _row('Subtotal', CurrencyFormatter.formatInr(_cart!.subtotal)),
                      _row('Tax (5%)', CurrencyFormatter.formatInr(_cart!.tax)),
                      const Divider(color: AppColors.border),
                      _row('Total', CurrencyFormatter.formatInr(_cart!.total), bold: true),
                      const SizedBox(height: 16),
                      KkButton(label: 'Proceed to Checkout →', onTap: () => context.push('/checkout')),
                    ]))),
                ]),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(width: 30, height: 30, decoration: BoxDecoration(color: AppColors.surface2, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: AppColors.textPrimary)));
  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Flexible(
              flex: 2,
              child: Text(
                l,
                style: bold ? AppTextStyles.bodyMedium : AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 3,
              child: Text(
                v,
                style: bold
                    ? AppTextStyles.bodyMedium.copyWith(color: AppColors.accent)
                    : AppTextStyles.bodyMedium,
                textAlign: TextAlign.end,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
