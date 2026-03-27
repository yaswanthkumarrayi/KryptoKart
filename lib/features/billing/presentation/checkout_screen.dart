import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/models/cart_item_model.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _apiService = sl<ApiService>();
  late final Razorpay _razorpay;
  CartModel? _cart;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _paymentMethod = 'upi';

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadCart();
  }

  @override
  void dispose() {
    _razorpay.clear();
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

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      // Verify payment
      if (response.orderId != null && response.paymentId != null && response.signature != null) {
        await _apiService.verifyPayment(
          orderId: response.orderId!,
          paymentId: response.paymentId!,
          signature: response.signature!,
        );
      }

      // Create transaction & clear cart
      final txnId = 'TXN-${response.paymentId ?? const Uuid().v4().substring(0, 8).toUpperCase()}';
      final itemIds = _cart!.items.map((i) => i.product.id).toList();
      final txnData = await _apiService.createTransaction({
        'txnId': txnId,
        'type': 'shopping',
        'amountInr': _cart!.total,
        'recipientName': 'KryptoMart Store',
        'recipientAddress': 'kryptomart@upi',
        'status': 'success',
        'itemIds': itemIds,
        'razorpayPaymentId': response.paymentId,
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
          SnackBar(content: Text('Error recording transaction: $e'), backgroundColor: AppColors.yellow),
        );
      }
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('External wallet: ${response.walletName}')),
      );
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
      // Use Razorpay for UPI
      try {
        final amountPaise = (_cart!.total * 100).toInt();
        final orderData = await _apiService.createPaymentOrder(amountPaise);

        final options = {
          'key': orderData['key_id'] ?? 'rzp_test_S01qKJJ0ovAUGa',
          'amount': orderData['amount'] ?? amountPaise,
          'currency': orderData['currency'] ?? 'INR',
          'order_id': orderData['order_id'],
          'name': 'KryptoKart',
          'description': 'Shopping checkout - ${_cart!.items.length} items',
          'theme': {'color': '#00E5FF'},
          'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
        };

        _razorpay.open(options);
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Razorpay error: $e'), backgroundColor: AppColors.yellow),
          );
          _processDirectCheckout();
        }
      }
    } else {
      // Crypto: direct transaction
      await _processDirectCheckout();
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
          SnackBar(content: Text('Checkout failed: $e'), backgroundColor: AppColors.red),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
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
                        ...(_cart?.items ?? []).map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(child: Text('${item.product.name} x${item.quantity}', style: AppTextStyles.body)),
                              Text(CurrencyFormatter.formatInr(item.totalPrice), style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        )),
                        const Divider(color: AppColors.border, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: AppTextStyles.bodyMedium),
                            Text(CurrencyFormatter.formatInr(_cart?.total ?? 0),
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent)),
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
                    label: 'Confirm & Pay ${CurrencyFormatter.formatInr(_cart?.total ?? 0)}',
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
          border: Border.all(color: sel ? AppColors.accent : AppColors.border, width: sel ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodyMedium),
            const Spacer(),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: sel ? AppColors.accent : AppColors.border, width: 2),
                color: sel ? AppColors.accent : Colors.transparent,
              ),
              child: sel ? const Icon(Icons.check, size: 12, color: AppColors.background) : null,
            ),
          ],
        ),
      ),
    );
  }
}
