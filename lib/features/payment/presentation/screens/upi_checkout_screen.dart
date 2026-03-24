import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kryptokart/features/payment/presentation/bloc/payment_bloc.dart';

class UpiCheckoutScreen extends StatelessWidget {
  final String upiId;
  final double amountInr;

  const UpiCheckoutScreen({
    super.key,
    required this.upiId,
    required this.amountInr,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          context.pushReplacement('/payment/receipt', extra: state.result);
        } else if (state is PaymentFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is PaymentProcessing;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.chevron_left,
                  size: 28, color: Theme.of(context).primaryColor),
              onPressed: () => context.pop(),
            ),
            title: const Text('UPI Checkout'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // UPI ID card
                _DetailRow(
                  label: 'Paying To',
                  value: upiId,
                  icon: Icons.alternate_email,
                  iconColor: const Color(0xFF1565C0),
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Amount',
                  value: '₹${amountInr.toStringAsFixed(2)}',
                  icon: Icons.currency_rupee,
                  iconColor: Colors.green.shade700,
                ),
                const Spacer(),
                // Pay row hint
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF1565C0), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You will be redirected to Razorpay to complete the UPI payment.',
                          style: TextStyle(
                              color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context.read<PaymentBloc>().add(
                              ProcessPaymentEvent(
                                amountInr: amountInr,
                                merchantId: upiId,
                                isCrypto: false,
                              ),
                            ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Icon(Icons.payment),
                    label: Text(
                      isLoading ? 'Processing...' : 'Pay Now',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
