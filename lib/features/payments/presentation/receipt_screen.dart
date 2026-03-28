import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/transaction_model.dart';

class ReceiptScreen extends StatelessWidget {
  final TransactionModel transaction;
  const ReceiptScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        const SizedBox(height: 40),
        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, color: AppColors.accent, size: 44))
            .animate().scale(begin: const Offset(0, 0), duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text('Payment Successful!', style: AppTextStyles.numberSmall).animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 8),
        Text(CurrencyFormatter.formatInr(transaction.amountInr), style: AppTextStyles.number.copyWith(color: AppColors.accent)).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 30),
        GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [
          _row('Transaction ID', transaction.txnId),
          const Divider(color: AppColors.border, height: 24),
          _row('Recipient', transaction.recipientName),
          const Divider(color: AppColors.border, height: 24),
          _row('Method', transaction.isCrypto ? 'Crypto (${(transaction.cryptoCoin ?? '').toUpperCase()})' : 'UPI'),
          const Divider(color: AppColors.border, height: 24),
          _row('Date & Time', DateFormatter.formatFull(transaction.createdAt)),
          if (transaction.isCrypto && transaction.networkFee > 0) ...[
            const Divider(color: AppColors.border, height: 24),
            _row('Network Fee', '${transaction.networkFee} ${(transaction.cryptoCoin ?? 'ETH').toUpperCase()}'),
          ],
        ])).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
        const SizedBox(height: 30),
        Row(children: [
          Expanded(child: KkButton(label: 'Share Receipt', onTap: () {}, outlined: true, height: 48, icon: Icons.share)),
          const SizedBox(width: 12),
          Expanded(child: KkButton(label: 'Done', onTap: () => context.go('/home'), height: 48)),
        ]).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 40),
      ]))),
    );
  }

  Widget _row(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.caption),
      Flexible(child: Text(value, style: AppTextStyles.bodyMedium, textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}
