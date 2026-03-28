import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/cart_item_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/razorpay_payment_service.dart';
import '../../../core/service_locator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _apiService = sl<ApiService>();
  final _razorpayService = sl<RazorpayPaymentService>();
  CartModel? _cart;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _paymentMethod = 'upi';

  @override
  void initState() {
    super.initState();
    // Set auth token for Razorpay service
    _razorpayService.setAuthToken(_apiService.token);
    _loadCart();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCart() async {
    try {
      final data = await _apiService.getCart();
      setState(() {
        _cart = CartModel.fromJson(data['cart']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processCheckout() async {
    if (_cart == null || _cart!.items.isEmpty) return;
    setState(() => _isProcessing = true);

    if (_paymentMethod == 'cash') {
      // Direct transaction for cash
      await _processDirectCheckout();
      return;
    }

    if (_paymentMethod == 'upi') {
      // Use Razorpay for UPI with automatic fallback
      await _processUpiCheckout();
    } else {
      // Crypto: direct transaction
      await _processDirectCheckout();
    }
  }

  Future<void> _processUpiCheckout() async {
    try {
      final amountPaise = (_cart!.total * 100).toInt();

      // Use the new Razorpay service with automatic fallback
      final result = await _razorpayService.startPayment(
        amountPaise: amountPaise,
        name: 'KryptoKart',
        description: 'Shopping checkout - ${_cart!.items.length} items',
      );

      if (!mounted) return;

      if (result.success) {
        // Payment successful - create transaction and clear cart
        final txnId =
            'TXN-${result.paymentId ?? const Uuid().v4().substring(0, 8).toUpperCase()}';
        try {
          final itemIds = _cart!.items.map((i) => i.product.id).toList();
          final txnData = await _apiService.createTransaction({
            'txnId': txnId,
            'type': 'shopping',
            'amountInr': _cart!.total,
            'recipientName': 'KryptoMart Store',
            'recipientAddress': 'kryptomart@upi',
            'status': 'success',
            'itemIds': itemIds,
            'razorpayPaymentId': result.paymentId,
            'razorpayOrderId': result.orderId,
            'usedFallback': result.usedFallback,
          });
          await _apiService.clearCart();
          final txn = TransactionModel.fromJson(txnData['transaction']);
          if (mounted) {
            setState(() => _isProcessing = false);
            context.push('/receipt', extra: txn);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment successful! Recording issue: $e'),
                backgroundColor: AppColors.yellow,
              ),
            );
          }
        }
      } else {
        // Payment failed
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Future<void> _processDirectCheckout() async {
    try {
      final txnId = 'TXN-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      final itemIds = _cart!.items.map((i) => i.product.id).toList();
      final txnData = await _apiService.createTransaction({
        'txnId': txnId,
        'type': _paymentMethod == 'crypto' ? 'crypto' : 'shopping',
        'amountInr': _cart!.total,
        'recipientName': 'KryptoMart Store',
        'recipientAddress': 'kryptomart@upi',
        'status': 'success',
        'itemIds': itemIds,
      });
      await _apiService.clearCart();
      final txn = TransactionModel.fromJson(txnData['transaction']);
      if (mounted) context.push('/receipt', extra: txn);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order Summary', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 12),
                        ...(_cart?.items ?? []).map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.product.name} x${item.quantity}',
                                    style: AppTextStyles.body,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  CurrencyFormatter.formatInr(item.totalPrice),
                                  style: AppTextStyles.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(color: AppColors.border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTextStyles.bodyMedium),
                            Text(
                              CurrencyFormatter.formatInr(_cart?.total ?? 0),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text('Payment Method', style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),

                  _option('UPI / Card (Razorpay)', 'upi', Icons.send_rounded),
                  _option('Crypto', 'crypto', Icons.currency_bitcoin),
                  _option('Cash', 'cash', Icons.money_rounded),

                  const SizedBox(height: 30),

                  KkButton(
                    label:
                        'Confirm & Pay ${CurrencyFormatter.formatInr(_cart?.total ?? 0)}',
                    onTap: _processCheckout,
                    isLoading: _isProcessing,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _option(String label, String value, IconData icon) {
    final sel = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? AppColors.accent : AppColors.border,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: sel ? AppColors.accent : AppColors.border,
                  width: 2,
                ),
                color: sel ? AppColors.accent : Colors.transparent,
              ),
              child: sel
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.background,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
