import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kryptokart/core/theme/app_theme.dart';
import 'package:kryptokart/core/utils/printer_helper.dart';
import 'package:kryptokart/core/data/hive_database.dart';
import 'package:kryptokart/features/payment/data/models/transaction_model.dart';
import 'package:kryptokart/features/payment/domain/entities/payment_result.dart';

class ReceiptScreen extends StatefulWidget {
  final PaymentResult result;

  const ReceiptScreen({super.key, required this.result});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _saveTransaction();
  }

  void _saveTransaction() {
    try {
      final box = HiveDatabase.transactionBox;
      final tx = TransactionModel(
        txId: widget.result.txId,
        method: widget.result.method == PaymentMethod.crypto ? 'crypto' : 'upi',
        amountInr: widget.result.amountInr,
        cryptoAmount: widget.result.cryptoAmount,
        cryptoSymbol: widget.result.cryptoSymbol,
        timestamp: widget.result.timestamp,
        merchantId: widget.result.merchantId,
      );
      box.add(tx);
    } catch (_) {}
  }

  Future<void> _printReceipt() async {
    setState(() => _printing = true);
    try {
      final printer = PrinterHelper();
      if (!printer.isConnected) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Printer not connected. Open Settings to pair.')),
          );
        }
        return;
      }

      final r = widget.result;
      final items = <Map<String, dynamic>>[
        {
          'name': r.method == PaymentMethod.crypto ? 'Crypto Payment' : 'UPI Payment',
          'qty': 1,
          'price': r.amountInr,
          'total': r.amountInr,
        },
      ];

      await printer.printReceipt(
        shopName: 'KryptoKart',
        address1: r.merchantId,
        address2: '',
        phone: '',
        items: items,
        total: r.amountInr,
        footer: 'Thank you for using KryptoKart!',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Receipt printed!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final isCrypto = r.method == PaymentMethod.crypto;
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(r.timestamp);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Success badge
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 50),
              ),
              const SizedBox(height: 16),
              const Text('Payment Successful!',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(dateStr,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 28),
              // Receipt card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _ReceiptRow('Amount',
                          '₹${r.amountInr.toStringAsFixed(2)}',
                          bold: true),
                      _ReceiptRow('Method',
                          isCrypto ? 'Crypto (Polygon)' : 'UPI'),
                      _ReceiptRow(
                          'Merchant / ID', r.merchantId,
                          small: true),
                      if (isCrypto && r.cryptoAmount != null)
                        _ReceiptRow('Crypto Sent',
                            '${r.cryptoAmount} ${r.cryptoSymbol ?? ''}'),
                      const Divider(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TX ID',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: r.txId));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('TX ID copied')),
                                );
                              },
                              child: Text(r.txId,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: AppTheme.primaryColor)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _printing ? null : _printReceipt,
                      icon: _printing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.print_outlined),
                      label: Text(_printing ? 'Printing...' : 'Print'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Done',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool small;

  const _ReceiptRow(this.label, this.value,
      {this.bold = false, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: small ? 12 : 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: small ? 12 : 14),
            ),
          ),
        ],
      ),
    );
  }
}
