import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/kk_theme_context.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../shared/services/razorpay_payment_service.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../core/service_locator.dart';
import '../../../core/utils/wallet_display.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? paymentData;
  const PaymentScreen({super.key, this.paymentData});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _apiService = sl<ApiService>();
  final _coinGecko = sl<CoinGeckoService>();
  final _razorpayService = sl<RazorpayPaymentService>();
  final _amountController = TextEditingController();
  bool _isCrypto = false;
  bool _isProcessing = false;
  String _recipientName = 'Recipient';
  String _recipientAddress = '';
  double _cryptoEquivalent = 0;
  final String _selectedCoin = 'ethereum';

  @override
  void initState() {
    super.initState();
    _razorpayService.setAuthToken(_apiService.token);

    if (widget.paymentData != null) {
      _recipientName = widget.paymentData!['recipientName'] ?? 'Recipient';
      _recipientAddress =
          widget.paymentData!['recipientUpi'] ??
          widget.paymentData!['recipientWallet'] ??
          '';
      if (widget.paymentData!['amount'] != null &&
          widget.paymentData!['amount'].toString().isNotEmpty) {
        _amountController.text = widget.paymentData!['amount'].toString();
      }
      if (widget.paymentData!['recipientWallet'] != null) _isCrypto = true;
    }
    _amountController.addListener(_onAmountChanged);
  }

  void _onAmountChanged() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0 && _isCrypto) {
      try {
        final crypto = await _coinGecko.convertInrToCrypto(
          amount,
          _selectedCoin,
        );
        if (mounted) setState(() => _cryptoEquivalent = crypto);
      } catch (_) {}
    }
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid amount'),
          backgroundColor: context.palette.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    if (_isCrypto) {
      await _processCryptoPayment(amount);
    } else {
      await _processUpiPayment(amount);
    }
  }

  Future<void> _processUpiPayment(double amount) async {
    try {
      final amountPaise = (amount * 100).toInt();

      final result = await _razorpayService.startPayment(
        amountPaise: amountPaise,
        name: 'KryptoKart',
        description: 'Payment to $_recipientName',
      );

      if (!mounted) return;

      if (result.success) {
        final txnId =
            'TXN-${result.paymentId ?? const Uuid().v4().substring(0, 8).toUpperCase()}';
        try {
          final txnData = await _apiService.createTransaction({
            'txnId': txnId,
            'type': 'upi',
            'amountInr': amount,
            'recipientName': _recipientName,
            'recipientAddress': _recipientAddress,
            'status': 'success',
            'razorpayPaymentId': result.paymentId,
            'razorpayOrderId': result.orderId,
            'usedFallback': result.usedFallback,
          });
          final txn = TransactionModel.fromJson(txnData['transaction']);
          if (mounted) {
            setState(() => _isProcessing = false);
            context.push('/receipt', extra: txn);
          }
        } catch (e) {
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment successful! (ID: ${result.paymentId}) Recording issue: $e',
                ),
                backgroundColor: context.palette.yellow,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result.message}'),
              backgroundColor: context.palette.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: context.palette.red,
          ),
        );
      }
    }
  }

  Future<void> _processCryptoPayment(double amount) async {
    try {
      final txnId = 'TXN-${const Uuid().v4().substring(0, 8).toUpperCase()}';
      final txnData = await _apiService.createTransaction({
        'txnId': txnId,
        'type': 'crypto',
        'amountInr': amount,
        'cryptoCoin': _selectedCoin,
        'cryptoAmount': _cryptoEquivalent,
        'recipientName': _recipientName,
        'recipientAddress': _recipientAddress,
        'status': 'success',
      });
      final txn = TransactionModel.fromJson(txnData['transaction']);
      if (mounted) {
        setState(() => _isProcessing = false);
        context.push('/receipt', extra: txn);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: context.palette.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(Icons.person, color: p.accent),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: p.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_recipientName, style: t.titleSmall),
                        Text(
                          _isCrypto
                              ? shortenWalletAddress(_recipientAddress)
                              : _recipientAddress,
                          style: t.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCrypto = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isCrypto ? p.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            'Crypto',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isCrypto
                                  ? p.textOnAccentButton
                                  : p.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCrypto = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isCrypto ? p.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            'UPI',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !_isCrypto
                                  ? p.textOnAccentButton
                                  : p.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹',
                    style: t.number.copyWith(
                      color: p.textSecondary,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: t.number.copyWith(fontSize: 48),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: p.textSecondary,
                          fontSize: 48,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isCrypto && _cryptoEquivalent > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '≈ ${CurrencyFormatter.formatCrypto(_cryptoEquivalent)} ${_selectedCoin.toUpperCase().substring(0, 3)}',
                  style: t.caption.copyWith(color: p.accent),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ).animate().fadeIn(),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [100, 500, 1000, 5000].map((amt) {
                return GestureDetector(
                  onTap: () => _amountController.text = amt.toString(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: p.border),
                    ),
                    child: Text('₹$amt', style: t.captionMedium),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: p.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isCrypto
                          ? 'BLOCKCHAIN VERIFIED TRANSFER'
                          : 'UPI SECURE PAYMENT VIA RAZORPAY',
                      style: t.caption.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            KkButton(
              label: _isCrypto ? 'Send Crypto' : 'Pay via Razorpay',
              onTap: _processPayment,
              isLoading: _isProcessing,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
