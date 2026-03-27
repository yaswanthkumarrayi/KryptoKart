import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/services/api_service.dart';
import '../../../shared/services/coingecko_service.dart';
import '../../../shared/services/razorpay_payment_service.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../core/service_locator.dart';

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
    // Set auth token for Razorpay service
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
        const SnackBar(
          content: Text('Enter a valid amount'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    if (_isCrypto) {
      // For crypto payments, create transaction directly (no Razorpay)
      await _processCryptoPayment(amount);
    } else {
      // UPI payment via Razorpay with fallback
      await _processUpiPayment(amount);
    }
  }

  Future<void> _processUpiPayment(double amount) async {
    try {
      final amountPaise = (amount * 100).toInt();

      // Use the new Razorpay service with automatic fallback
      final result = await _razorpayService.startPayment(
        amountPaise: amountPaise,
        name: 'KryptoKart',
        description: 'Payment to $_recipientName',
      );

      if (!mounted) return;

      if (result.success) {
        // Payment successful - create transaction record
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
          // Transaction record failed but payment succeeded
          if (mounted) {
            setState(() => _isProcessing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Payment successful! (ID: ${result.paymentId}) Recording issue: $e',
                ),
                backgroundColor: AppColors.yellow,
              ),
            );
          }
        }
      } else {
        // Payment failed
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${result.message}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.red),
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
            backgroundColor: AppColors.red,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Recipient card
            GlassCard(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.surface2,
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(Icons.person, color: AppColors.accent),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: AppColors.green,
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
                        Text(_recipientName, style: AppTextStyles.titleSmall),
                        Text(
                          _recipientAddress,
                          style: AppTextStyles.caption,
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

            // Crypto / UPI toggle
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCrypto = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isCrypto
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            'Crypto',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _isCrypto
                                  ? AppColors.background
                                  : AppColors.textSecondary,
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
                          color: !_isCrypto
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            'UPI',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !_isCrypto
                                  ? AppColors.background
                                  : AppColors.textSecondary,
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

            // Amount input
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹',
                  style: AppTextStyles.number.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.number.copyWith(fontSize: 48),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 48,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isCrypto && _cryptoEquivalent > 0)
              Text(
                '≈ ${CurrencyFormatter.formatCrypto(_cryptoEquivalent)} ${_selectedCoin.toUpperCase().substring(0, 3)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.accent),
              ).animate().fadeIn(),

            const SizedBox(height: 16),

            // Quick amount buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [100, 500, 1000, 5000].map((amt) {
                return GestureDetector(
                  onTap: () => _amountController.text = amt.toString(),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('₹$amt', style: AppTextStyles.captionMedium),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Security badge
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCrypto
                        ? 'BLOCKCHAIN VERIFIED TRANSFER'
                        : 'UPI SECURE PAYMENT VIA RAZORPAY',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            KkButton(
              label: _isCrypto ? 'Send Crypto →' : 'Pay via Razorpay →',
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
