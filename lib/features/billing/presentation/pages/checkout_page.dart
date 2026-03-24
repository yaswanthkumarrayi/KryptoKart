import 'package:kryptokart/core/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../../shop/presentation/bloc/shop_bloc.dart';
import '../../../payment/presentation/bloc/payment_bloc.dart';
import '../bloc/billing_bloc.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE5E5EA);

    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          context.go('/');
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Checkout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              onPressed: () {
                context.go('/');
              },
            ),
          ),
          body: BlocConsumer<BillingBloc, BillingState>(
            listener: (context, state) {
              if (state.printSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Printed successfully'),
                    backgroundColor: Colors.green));
              }
            },
            builder: (context, billingState) {
              return BlocBuilder<ShopBloc, ShopState>(
                  builder: (context, shopState) {
                String upiId = '';
                String shopName = 'Shop';

                if (shopState is ShopLoaded) {
                  upiId = shopState.shop.upiId;
                  shopName = shopState.shop.name;
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        child: Column(
                          children: [
                            // Table
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Table(
                                  border: const TableBorder(
                                    horizontalInside:
                                        BorderSide(color: borderColor),
                                    bottom: BorderSide(color: borderColor),
                                  ),
                                  children: [
                                    // Header row
                                    TableRow(
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF8FAFC),
                                        border: Border(
                                            bottom:
                                                BorderSide(color: borderColor)),
                                      ),
                                      children: [
                                        _buildHeaderCell(
                                            'Product Name', TextAlign.left),
                                        _buildHeaderCell(
                                            'Price', TextAlign.right),
                                        _buildHeaderCell(
                                            'Total', TextAlign.right),
                                      ],
                                    ),
                                    // Items rows
                                    ...billingState.cartItems.map((item) {
                                      return TableRow(
                                        children: [
                                          _buildDataCell(
                                            '${item.quantity} x ${item.product.name}',
                                            TextAlign.left,
                                          ),
                                          _buildDataCell(
                                              '₹${item.product.price.toStringAsFixed(2)}',
                                              TextAlign.right,
                                              isSubtitle: true),
                                          _buildDataCell(
                                              '₹${item.total.toStringAsFixed(2)}',
                                              TextAlign.right,
                                              isBold: true),
                                        ],
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Grand Total Row
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'GRAND TOTAL',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Text(
                                    '₹${billingState.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Wallet Connection Status (for Crypto payments)
                            BlocBuilder<PaymentBloc, PaymentState>(
                              builder: (context, paymentState) {
                                final walletService = context.read<PaymentBloc>().walletService;
                                final isConnected = walletService.isConnected;
                                final address = walletService.getConnectedAddress();
                                
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isConnected
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isConnected
                                          ? Colors.green.shade200
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isConnected ? Icons.check_circle : Icons.account_balance_wallet,
                                        color: isConnected ? Colors.green : Colors.orange,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isConnected ? 'Wallet Connected' : 'Wallet Not Connected',
                                              style: TextStyle(
                                                color: isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            if (isConnected && address != null)
                                              Text(
                                                '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                                                style: TextStyle(
                                                  color: Colors.green.shade600,
                                                  fontSize: 11,
                                                ),
                                              )
                                            else
                                              Text(
                                                'Connect wallet for crypto payments',
                                                style: TextStyle(
                                                  color: Colors.orange.shade600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (isConnected)
                                        TextButton(
                                          onPressed: () {
                                            context.read<PaymentBloc>().add(DisconnectWalletEvent());
                                          },
                                          child: const Text('Disconnect'),
                                        )
                                      else
                                        ElevatedButton(
                                          onPressed: () {
                                            context.read<PaymentBloc>().add(ConnectWalletEvent());
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFE65100),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text('Connect'),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Payment Options Section
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Choose Payment Method',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Crypto Payment Option
                            _PaymentOptionCard(
                              icon: Icons.currency_bitcoin,
                              title: 'Pay with Crypto',
                              subtitle: 'ETH & MATIC on Polygon',
                              color: const Color(0xFFE65100),
                              accentColor: const Color(0xFFFFF3E0),
                              onTap: () {
                                _showPaymentScanner(
                                  context,
                                  isCrypto: true,
                                  amount: billingState.totalAmount,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            // UPI Payment Option
                            _PaymentOptionCard(
                              icon: Icons.account_balance,
                              title: 'Pay via UPI',
                              subtitle: 'Instant bank transfer',
                              color: const Color(0xFF1565C0),
                              accentColor: const Color(0xFFE3F2FD),
                              onTap: () {
                                _showPaymentScanner(
                                  context,
                                  isCrypto: false,
                                  amount: billingState.totalAmount,
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            // Shop QR Code for UPI (if available)
                            if (upiId.isNotEmpty) ...[
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text(
                                'Or Scan Shop QR',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      width: 160,
                                      height: 160,
                                      child: PrettyQrView.data(
                                        data:
                                            'upi://pay?pa=$upiId&pn=$shopName&am=${billingState.totalAmount.toStringAsFixed(2)}&cu=INR',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      shopName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      upiId,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                    // Bottom Bar - Print Receipt
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: PrimaryButton(
                        onPressed: () {
                          if (shopState is ShopLoaded) {
                            context.read<BillingBloc>().add(
                                PrintReceiptEvent(
                                    shopName: shopState.shop.name,
                                    address1: shopState.shop.addressLine1,
                                    address2: shopState.shop.addressLine2,
                                    phone: shopState.shop.phoneNumber,
                                    footer: shopState.shop.footerText));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Shop details not loaded'),
                                    backgroundColor: Colors.red));
                          }
                        },
                        label: 'Print Receipt',
                        icon: Icons.print,
                        isLoading: billingState.isPrinting,
                      ),
                    ),
                  ],
                );
              });
            },
          ),
        ));
  }

  void _showPaymentScanner(BuildContext context,
      {required bool isCrypto, required double amount}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _PaymentEntrySheet(
          isCrypto: isCrypto,
          amount: amount,
          onProceed: (merchantId) {
            Navigator.of(ctx).pop();
            if (isCrypto) {
              context.push('/payment/crypto', extra: {
                'ethAddress': merchantId,
                'amountInr': amount,
              });
            } else {
              context.push('/payment/upi', extra: {
                'upiId': merchantId,
                'amountInr': amount,
              });
            }
          },
          onScan: () {
            Navigator.of(ctx).pop();
            _navigateToPaymentScanner(context, isCrypto: isCrypto, amount: amount);
          },
        );
      },
    );
  }

  void _navigateToPaymentScanner(BuildContext context,
      {required bool isCrypto, required double amount}) async {
    final raw = await context.push<String>('/scanner');
    if (raw != null && context.mounted) {
      final rawTrimmed = raw.trim();
      if (isCrypto) {
        // Expect ETH address
        String ethAddress = rawTrimmed;
        if (rawTrimmed.startsWith('0x') && rawTrimmed.length == 42) {
          context.push('/payment/crypto', extra: {
            'ethAddress': ethAddress,
            'amountInr': amount,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Ethereum address scanned'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Expect UPI
        String upiId = rawTrimmed;
        if (rawTrimmed.startsWith('upi://')) {
          final uri = Uri.tryParse(rawTrimmed);
          upiId = uri?.queryParameters['pa'] ?? rawTrimmed;
        }
        if (upiId.contains('@')) {
          context.push('/payment/upi', extra: {
            'upiId': upiId,
            'amountInr': amount,
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid UPI ID scanned'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildHeaderCell(String text, TextAlign align) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text.toUpperCase(),
        textAlign: align,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, TextAlign align,
      {bool isBold = false, bool isSubtitle = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: isSubtitle ? 12 : 14,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: isSubtitle ? Colors.grey[500] : Colors.black87,
        ),
      ),
    );
  }
}

// Payment Option Card Widget
class _PaymentOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade700)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// Payment Entry Sheet Widget
class _PaymentEntrySheet extends StatefulWidget {
  final bool isCrypto;
  final double amount;
  final Function(String merchantId) onProceed;
  final VoidCallback onScan;

  const _PaymentEntrySheet({
    required this.isCrypto,
    required this.amount,
    required this.onProceed,
    required this.onScan,
  });

  @override
  State<_PaymentEntrySheet> createState() => _PaymentEntrySheetState();
}

class _PaymentEntrySheetState extends State<_PaymentEntrySheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isCrypto ? 'Pay with Crypto' : 'Pay via UPI',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: ₹${widget.amount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: widget.isCrypto
                ? TextInputType.text
                : TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: widget.isCrypto ? 'Ethereum Address' : 'UPI ID',
              hintText: widget.isCrypto ? '0x...' : 'example@upi',
              prefixIcon: Icon(widget.isCrypto
                  ? Icons.account_balance_wallet
                  : Icons.alternate_email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onScan,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final value = _controller.text.trim();
                    if (value.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(widget.isCrypto
                              ? 'Please enter Ethereum address'
                              : 'Please enter UPI ID'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    widget.onProceed(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isCrypto
                        ? const Color(0xFFE65100)
                        : const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Proceed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
