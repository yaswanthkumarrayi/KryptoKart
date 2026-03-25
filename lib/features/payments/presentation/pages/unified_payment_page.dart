import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/data/hive_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/store/transaction_store.dart';
import '../../data/models/transaction_model.dart';
import '../../domain/entities/payment_result.dart';
import '../bloc/payment_bloc.dart';

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
  late final TextEditingController _amountController;
  late UnifiedMethod _selectedMethod;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.initialAmount ?? 0) > 0
          ? widget.initialAmount!.toStringAsFixed(2)
          : '',
    );
    _selectedMethod = _mapMethod(widget.initialType);
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

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  String get _upiId => widget.initialUpiId ?? '';
  String get _payeeName => widget.initialPayeeName ?? 'Merchant';
  String get _wallet => widget.initialWalletAddress ?? '';

  void _processPayment() {
    if (_amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }

    final isCrypto = _selectedMethod == UnifiedMethod.eth;
    final merchantId = isCrypto ? _wallet : _upiId;

    if (merchantId.isEmpty) {
      _showError(isCrypto
          ? 'Wallet address is missing.'
          : 'UPI ID is missing.');
      return;
    }

    context.read<PaymentBloc>().add(ProcessPaymentEvent(
      amountInr: _amount,
      merchantId: merchantId,
      isCrypto: isCrypto,
    ));
  }

  void _onPaymentSuccess(PaymentResult result) {
    _saveToHive(result);
    _saveToTransactionStore(result);
    context.go('/payment/receipt', extra: result);
  }

  void _saveToHive(PaymentResult result) {
    try {
      HiveDatabase.transactionBox.add(TransactionModel(
        txId: result.txId,
        method: result.method == PaymentMethod.crypto ? 'crypto' : 'upi',
        amountInr: result.amountInr,
        cryptoAmount: result.cryptoAmount,
        cryptoSymbol: result.cryptoSymbol,
        timestamp: result.timestamp,
        merchantId: result.merchantId,
      ));
    } catch (_) {}
  }

  void _saveToTransactionStore(PaymentResult result) {
    final isCrypto = result.method == PaymentMethod.crypto;
    TransactionStore.add(KkTransaction(
      type: isCrypto ? KkTransactionType.crypto : KkTransactionType.upi,
      amount: result.amountInr,
      title: isCrypto
          ? 'ETH - ${result.merchantId}'
          : 'UPI - $_payeeName',
      date: result.timestamp,
    ));
  }

  void _showError(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state is PaymentSuccess) {
          _onPaymentSuccess(state.result);
        } else if (state is PaymentFailure) {
          _showError(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Payment')),
        body: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, paymentState) {
            final isProcessing = paymentState is PaymentProcessing ||
                paymentState is FetchingCryptoRate;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                  children: [
                    _buildReceiverCard(context),
                    const SizedBox(height: 14),
                    _buildAmountCard(context),
                    const SizedBox(height: 14),
                    _buildMethodPicker(context),
                    const SizedBox(height: 14),
                    _buildSummaryCard(context),
                    const SizedBox(height: 22),
                    _buildPayButtons(context, isProcessing),
                  ],
                ),
                if (isProcessing) _buildLoadingOverlay(paymentState),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildReceiverCard(BuildContext context) {
    return _GlassBox(
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
          _infoRow(context, 'Payee', _payeeName),
          if (_upiId.isNotEmpty) _infoRow(context, 'UPI ID', _upiId),
          if (_wallet.isNotEmpty) _infoRow(context, 'ETH Wallet', _wallet),
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context) {
    return _GlassBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              hintText: '0.00',
              prefixIcon: Icon(Icons.currency_rupee_rounded),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodPicker(BuildContext context) {
    return _GlassBox(
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
                  onTap: () =>
                      setState(() => _selectedMethod = UnifiedMethod.upi),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MethodCard(
                  selected: _selectedMethod == UnifiedMethod.eth,
                  icon: Icons.currency_bitcoin_rounded,
                  label: 'ETH',
                  onTap: () =>
                      setState(() => _selectedMethod = UnifiedMethod.eth),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final isCrypto = _selectedMethod == UnifiedMethod.eth;

    return _GlassBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCrypto ? 'ETH Checkout' : 'UPI Checkout',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (!isCrypto)
            _infoRow(context, 'Pay to', '$_payeeName ($_upiId)'),
          _infoRow(
            context,
            'Amount',
            'Rs ${_amount.toStringAsFixed(2)}',
          ),
          if (isCrypto) ...[
            _infoRow(context, 'Wallet', _wallet),
            Text(
              'ETH conversion will be calculated at live rate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPayButtons(BuildContext context, bool isProcessing) {
    return Column(
      children: [
        FilledButton.icon(
          onPressed: isProcessing
              ? null
              : () {
                  setState(() => _selectedMethod = UnifiedMethod.upi);
                  _processPayment();
                },
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
          onPressed: isProcessing
              ? null
              : () {
                  setState(() => _selectedMethod = UnifiedMethod.eth);
                  _processPayment();
                },
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
  }

  Widget _buildLoadingOverlay(PaymentState state) {
    final label = state is FetchingCryptoRate
        ? 'Fetching live crypto rate...'
        : 'Processing payment...';

    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
                Text(label, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
