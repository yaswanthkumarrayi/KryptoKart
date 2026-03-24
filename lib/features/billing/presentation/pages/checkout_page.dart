import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../transactions/presentation/store/transaction_store.dart';
import '../bloc/billing_bloc.dart';

enum PaymentMethod { upi, eth }

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.upi;
  static const double _ethRateInInr = 315000;

  void _markPaymentSuccess({
    required BillingState billingState,
    required PaymentMethod method,
  }) {
    final label = method == PaymentMethod.upi ? 'UPI' : 'ETH';
    final amountText = billingState.totalAmount.toStringAsFixed(2);
    final time = TimeOfDay.now().format(context);
    TransactionStore.add(
      KkTransaction(
        type: KkTransactionType.shopping,
        amount: billingState.totalAmount,
        title: 'Shopping Checkout - $label',
        date: DateTime.now(),
      ),
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF141B31),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF45D483)),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Text(
          '$label payment of Rs $amountText marked as successful at $time.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/shopping');
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }

  void _printReceipt(ShopState shopState) {
    if (shopState is ShopLoaded) {
      context.read<BillingBloc>().add(
        PrintReceiptEvent(
          shopName: shopState.shop.name,
          address1: shopState.shop.addressLine1,
          address2: shopState.shop.addressLine2,
          phone: shopState.shop.phoneNumber,
          footer: shopState.shop.footerText,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shop details not loaded'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        context.read<BillingBloc>().add(ClearCartEvent());
        context.go('/shopping');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 28),
            onPressed: () {
              context.read<BillingBloc>().add(ClearCartEvent());
              context.go('/shopping');
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080B16), Color(0xFF121A2D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: BlocConsumer<BillingBloc, BillingState>(
            listener: (context, state) {
              if (state.printSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Printed successfully'),
                    backgroundColor: Color(0xFF1F8E5A),
                  ),
                );
              }
            },
            builder: (context, billingState) {
              return BlocBuilder<ShopBloc, ShopState>(
                builder: (context, shopState) {
                  String upiId = '';
                  String shopName = 'Shop';
                  const shopWallet = '0x7bA3F95fA2...9E21';

                  if (shopState is ShopLoaded) {
                    upiId = shopState.shop.upiId;
                    shopName = shopState.shop.name;
                  }

                  final bool showUpiQr =
                      _selectedPaymentMethod == PaymentMethod.upi;
                  final ethAmount = billingState.totalAmount / _ethRateInInr;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _GlassSection(
                        child: Row(
                          children: [
                            const Icon(Icons.storefront_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                shopName,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(
                              'Rs ${billingState.totalAmount.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cart Items',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            if (billingState.cartItems.isEmpty)
                              const Text('No items in cart')
                            else
                              ...billingState.cartItems.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity} x ${item.product.name}',
                                        ),
                                      ),
                                      Text(
                                        'Rs ${item.total.toStringAsFixed(2)}',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      _GlassSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Option',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _PaymentOptionCard(
                                    title: 'UPI',
                                    subtitle: 'Scan and pay',
                                    icon: Icons.qr_code_2_rounded,
                                    isSelected:
                                        _selectedPaymentMethod ==
                                        PaymentMethod.upi,
                                    onTap: () => setState(
                                      () => _selectedPaymentMethod =
                                          PaymentMethod.upi,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PaymentOptionCard(
                                    title: 'ETH',
                                    subtitle: 'Crypto transfer',
                                    icon: Icons.currency_bitcoin_rounded,
                                    isSelected:
                                        _selectedPaymentMethod ==
                                        PaymentMethod.eth,
                                    onTap: () => setState(
                                      () => _selectedPaymentMethod =
                                          PaymentMethod.eth,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (showUpiQr)
                        _GlassSection(
                          child: Column(
                            children: [
                              Text(
                                'Scan to Pay (UPI)',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              if (upiId.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: PrettyQrView.data(
                                      data:
                                          'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
                                    ),
                                  ),
                                )
                              else
                                const Text(
                                  'UPI ID missing in shop details.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                            ],
                          ),
                        )
                      else
                        _GlassSection(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ETH Summary',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              _summaryRow('Wallet', shopWallet),
                              _summaryRow(
                                'INR Amount',
                                'Rs ${billingState.totalAmount.toStringAsFixed(2)}',
                              ),
                              _summaryRow(
                                'ETH Amount',
                                '${ethAmount.toStringAsFixed(6)} ETH',
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: () {
                          if (_selectedPaymentMethod == PaymentMethod.upi &&
                              upiId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please set a UPI ID in shop details first.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          _markPaymentSuccess(
                            billingState: billingState,
                            method: _selectedPaymentMethod,
                          );
                        },
                        icon: Icon(
                          _selectedPaymentMethod == PaymentMethod.upi
                              ? Icons.verified_rounded
                              : Icons.currency_bitcoin_rounded,
                        ),
                        label: Text(
                          _selectedPaymentMethod == PaymentMethod.upi
                              ? 'Confirm UPI Payment'
                              : 'Confirm ETH Payment',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: billingState.isPrinting
                            ? null
                            : () => _printReceipt(shopState),
                        icon: billingState.isPrinting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.print_rounded),
                        label: const Text('Print Receipt'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: Colors.white,
                          side: const BorderSide(
                            color: AppTheme.cardBorderColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final Widget child;

  const _GlassSection({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x2B171F3A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : AppTheme.cardBorderColor;
    final bgColor = isSelected
        ? const Color(0x57382771)
        : const Color(0x1C131B33);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
