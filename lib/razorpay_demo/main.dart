import 'package:flutter/material.dart';
import 'payment_service.dart';

void main() {
  runApp(const RazorpayDemoApp());
}

class RazorpayDemoApp extends StatelessWidget {
  const RazorpayDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const CheckoutScreen(),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final RazorpayPaymentService _service = RazorpayPaymentService();
  final TextEditingController _amountController = TextEditingController(text: '100');
  bool _loading = false;

  @override
  void dispose() {
    _service.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _payNow() async {
    final rupees = int.tryParse(_amountController.text.trim());
    if (rupees == null || rupees <= 0) {
      _openResult(
        const PaymentStatus(success: false, message: 'Enter a valid amount in rupees.'),
      );
      return;
    }

    setState(() => _loading = true);
    final result = await _service.startPayment(
      amountPaise: rupees * 100,
      name: 'KryptoKart',
      description: 'Checkout payment',
      email: 'customer@example.com',
      contact: '9999999999',
    );
    if (!mounted) return;
    setState(() => _loading = false);
    _openResult(result);
  }

  void _openResult(PaymentStatus result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Razorpay Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (INR)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading ? null : _payNow,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Checkout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final PaymentStatus result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final success = result.success;
    return Scaffold(
      appBar: AppBar(title: Text(success ? 'Payment Success' : 'Payment Failed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                size: 72,
                color: success ? Colors.green : Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (result.paymentId != null) ...[
                const SizedBox(height: 8),
                Text('Payment ID: ${result.paymentId}'),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
