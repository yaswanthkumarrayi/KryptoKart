import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/primary_button.dart';
import '../bloc/upi_bloc.dart';
import '../bloc/upi_event.dart';
import '../bloc/upi_state.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _payNow(UpiState upiState) async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount greater than 0.')),
      );
      return;
    }

    if (upiState.payeeUpiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payee selected. Please scan again.')),
      );
      return;
    }

    context.read<UpiBloc>()
      ..add(UpiAmountUpdatedEvent(amount))
      ..add(UpiPaymentProcessingEvent());

    final upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiState.payeeUpiId,
        'pn': upiState.payeeName,
        'am': amount.toStringAsFixed(2),
        'cu': 'INR',
      },
    );

    final launched = await launchUrl(
      upiUri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;

    if (launched) {
      context.read<UpiBloc>().add(
        UpiPaymentSuccessEvent(amount: amount, paidAt: DateTime.now()),
      );
      context.go('/upi/success');
      return;
    }

    context.read<UpiBloc>().add(
      const UpiPaymentFailureEvent('Could not open a UPI app.'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open a UPI app on this device.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Payment')),
      body: BlocBuilder<UpiBloc, UpiState>(
        builder: (context, state) {
          if (state.payeeUpiId.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code_2_rounded, size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      'No UPI payee selected yet.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => context.go('/upi/scan'),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (_amountController.text.isEmpty && state.amount > 0) {
            _amountController.text = state.amount.toStringAsFixed(2);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payee UPI ID',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.payeeUpiId,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.payeeName,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.currency_rupee_rounded),
                  hintText: '0.00',
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [100, 250, 500, 1000]
                    .map(
                      (amount) => ActionChip(
                        label: Text('₹$amount'),
                        onPressed: () =>
                            _amountController.text = amount.toStringAsFixed(2),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              if (state.status == UpiStatus.processing)
                const LinearProgressIndicator(minHeight: 3),
              PrimaryButton(
                onPressed: state.status == UpiStatus.processing
                    ? null
                    : () => _payNow(state),
                label: 'Pay Now',
                icon: Icons.lock_rounded,
                isLoading: state.status == UpiStatus.processing,
              ),
            ],
          );
        },
      ),
    );
  }
}
