import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/store/transaction_store.dart';
import '../../../upi/presentation/bloc/upi_bloc.dart';
import '../../../upi/presentation/bloc/upi_event.dart';
import '../../../upi/presentation/bloc/upi_state.dart';

enum UnifiedMethod { upi, eth }

class UnifiedPaymentPage extends StatefulWidget {
  final String? initialType;
  final double? initialAmount;
  final String? initialUpiId;
  final String? initialPayeeName;
  final String? initialWalletAddress;
  final String? initialRawData;

  const UnifiedPaymentPage({
    super.key,
    this.initialType,
    this.initialAmount,
    this.initialUpiId,
    this.initialPayeeName,
    this.initialWalletAddress,
    this.initialRawData,
  });

  @override
  State<UnifiedPaymentPage> createState() => _UnifiedPaymentPageState();
}

class _UnifiedPaymentPageState extends State<UnifiedPaymentPage> {
  static const double _ethRateInInr = 315000;
  late final TextEditingController _amountController;
  late UnifiedMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.initialAmount ?? 0).toStringAsFixed(2),
    );
    _selectedMethod = _mapMethod(widget.initialType);
    if ((widget.initialUpiId ?? '').isNotEmpty) {
      context.read<UpiBloc>().add(
        UpiPayeeSetEvent(
          upiId: widget.initialUpiId!,
          payeeName: widget.initialPayeeName ?? 'KryptoKart Merchant',
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  UnifiedMethod _mapMethod(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'eth':
      case 'crypto':
        return UnifiedMethod.eth;
      default:
        return UnifiedMethod.upi;
    }
  }

  bool get _isUnknownQr => widget.initialType?.toLowerCase() == 'unknown';
  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  Future<void> _payUpi(UpiState upiState) async {
    if (_amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }

    if (upiState.payeeUpiId.trim().isEmpty) {
      _showError('UPI ID missing. Scan UPI QR or add payee details.');
      return;
    }

    context.read<UpiBloc>()
      ..add(UpiAmountUpdatedEvent(_amount))
      ..add(UpiPaymentProcessingEvent());

    final upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiState.payeeUpiId,
        'pn': upiState.payeeName,
        'am': _amount.toStringAsFixed(2),
        'cu': 'INR',
      },
    );

    final launched = await launchUrl(
      upiUri,
      mode: LaunchMode.externalApplication,
    );
    if (!mounted) return;

    if (!launched) {
      context.read<UpiBloc>().add(
        const UpiPaymentFailureEvent('Could not open a UPI app'),
      );
      _showError('Could not open a UPI app on this device.');
      return;
    }

    final paidAt = DateTime.now();
    context.read<UpiBloc>().add(
      UpiPaymentSuccessEvent(amount: _amount, paidAt: paidAt),
    );
    TransactionStore.add(
      KkTransaction(
        type: KkTransactionType.upi,
        amount: _amount,
        title: 'UPI - ${upiState.payeeName}',
        date: paidAt,
      ),
    );
    await _openSuccessScreen(
      method: 'UPI',
      amount: _amount,
      receiver: upiState.payeeName,
      detail: upiState.payeeUpiId,
    );
  }

  Future<void> _payEth() async {
    if (_amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    final now = DateTime.now();
    final wallet = widget.initialWalletAddress ?? '0x7bA3...9E21';
    TransactionStore.add(
      KkTransaction(
        type: KkTransactionType.crypto,
        amount: _amount,
        title: 'ETH - $wallet',
        date: now,
      ),
    );
    await _openSuccessScreen(
      method: 'ETH',
      amount: _amount,
      receiver: 'Ethereum Wallet',
      detail: wallet,
    );
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openSuccessScreen({
    required String method,
    required double amount,
    required String receiver,
    required String detail,
  }) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentSuccessScreen(
          method: method,
          amount: amount,
          receiver: receiver,
          detail: detail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ethAmount = _amount > 0 ? _amount / _ethRateInInr : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: BlocBuilder<UpiBloc, UpiState>(
        builder: (context, upiState) {
          final upiId = upiState.payeeUpiId.isEmpty
              ? (widget.initialUpiId ?? 'kryptokart@upi')
              : upiState.payeeUpiId;
          final payeeName = upiState.payeeName.isEmpty
              ? (widget.initialPayeeName ?? 'KryptoKart Merchant')
              : upiState.payeeName;
          final wallet = widget.initialWalletAddress ?? '0x7bA3F95fA2...9E21';
          if (_isUnknownQr) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              children: [
                _GlassBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QR Info',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This code is not recognized as UPI or ETH.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.initialRawData ?? 'No data found',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go('/scan'),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan Again'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
            children: [
              _GlassBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receiver Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _infoRow(context, 'Payee', payeeName),
                    _infoRow(context, 'UPI ID', upiId),
                    _infoRow(context, 'ETH Wallet', wallet),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.currency_rupee_rounded),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassBox(
                child: Column(
                  children: [
                    Text(
                      'Payment Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MethodCard(
                            selected: _selectedMethod == UnifiedMethod.upi,
                            icon: Icons.qr_code_2_rounded,
                            label: 'UPI',
                            onTap: () => setState(
                              () => _selectedMethod = UnifiedMethod.upi,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _MethodCard(
                            selected: _selectedMethod == UnifiedMethod.eth,
                            icon: Icons.currency_bitcoin_rounded,
                            label: 'ETH',
                            onTap: () => setState(
                              () => _selectedMethod = UnifiedMethod.eth,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _GlassBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMethod == UnifiedMethod.upi
                          ? 'UPI Checkout'
                          : 'ETH Checkout',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_selectedMethod == UnifiedMethod.upi)
                      _infoRow(context, 'Pay to', '$payeeName ($upiId)'),
                    _infoRow(
                      context,
                      'Amount',
                      'Rs ${_amount.toStringAsFixed(2)}',
                    ),
                    if (_selectedMethod == UnifiedMethod.eth) ...[
                      _infoRow(context, 'Wallet', wallet),
                      _infoRow(
                        context,
                        'ETH',
                        '${ethAmount.toStringAsFixed(6)} ETH',
                      ),
                      _infoRow(
                        context,
                        'Rate',
                        '1 ETH = Rs ${_ethRateInInr.toStringAsFixed(0)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => _payUpi(upiState),
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('Pay with UPI'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _payEth,
                icon: const Icon(Icons.currency_bitcoin_rounded),
                label: const Text('Pay with ETH'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.cardBorderColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MethodCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0x7A7352E0) : const Color(0x28141B34),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.cardBorderColor,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _GlassBox extends StatelessWidget {
  final Widget child;

  const _GlassBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0x2D171E38),
        border: Border.all(color: AppTheme.cardBorderColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PaymentSuccessScreen extends StatelessWidget {
  final String method;
  final double amount;
  final String receiver;
  final String detail;

  const PaymentSuccessScreen({
    super.key,
    required this.method,
    required this.amount,
    required this.receiver,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF080A14), Color(0xFF171D36), Color(0xFF201C42)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x2545D483),
                    border: Border.all(
                      color: const Color(0xFF45D483),
                      width: 1.4,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF45D483),
                    size: 52,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Payment Successful',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rs ${amount.toStringAsFixed(2)} paid via $method',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color(0x2A1C2342),
                    border: Border.all(color: AppTheme.cardBorderColor),
                  ),
                  child: Column(
                    children: [
                      _detailRow('Receiver', receiver),
                      _detailRow('Method', method),
                      _detailRow('Details', detail),
                    ],
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => context.go('/'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(key, style: const TextStyle(color: Colors.white70)),
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
