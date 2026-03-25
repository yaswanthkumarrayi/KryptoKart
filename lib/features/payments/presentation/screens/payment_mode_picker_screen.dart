import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentModePickerScreen extends StatelessWidget {
  const PaymentModePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.chevron_left,
              size: 28, color: Theme.of(context).primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text('Send Money'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose payment method',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _PayCard(
              icon: Icons.account_balance,
              title: 'Pay via UPI',
              subtitle: 'Fast, instant bank transfers',
              color: const Color(0xFF1565C0),
              accentColor: const Color(0xFFE3F2FD),
              onTap: () => _showUpiForm(context),
            ),
            const SizedBox(height: 16),
            _PayCard(
              icon: Icons.currency_bitcoin,
              title: 'Pay with Crypto',
              subtitle: 'ETH & MATIC on Polygon network',
              color: const Color(0xFFE65100),
              accentColor: const Color(0xFFFFF3E0),
              onTap: () => _showCryptoForm(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpiForm(BuildContext context) {
    final upiCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pay via UPI',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: upiCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'UPI ID',
                  hintText: 'example@upi',
                  prefixIcon: Icon(Icons.alternate_email)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final upi = upiCtrl.text.trim();
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
                  if (upi.isEmpty || amt <= 0) return;
                  ctx.pop();
                  context.push('/payment/upi',
                      extra: {'upiId': upi, 'amountInr': amt});
                },
                child: const Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCryptoForm(BuildContext context) {
    final addrCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pay with Crypto',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: addrCtrl,
              decoration: const InputDecoration(
                  labelText: 'Ethereum Address',
                  hintText: '0x...',
                  prefixIcon: Icon(Icons.account_balance_wallet)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amtCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount in INR (₹)',
                  prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100)),
                onPressed: () {
                  final addr = addrCtrl.text.trim();
                  final amt = double.tryParse(amtCtrl.text) ?? 0;
                  if (addr.isEmpty || amt <= 0) return;
                  ctx.pop();
                  context.push('/payment/crypto',
                      extra: {'ethAddress': addr, 'amountInr': amt});
                },
                child: const Text('Proceed to Pay'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------
class _PayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  const _PayCard({
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: accentColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: color)),
                  const SizedBox(height: 4),
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
