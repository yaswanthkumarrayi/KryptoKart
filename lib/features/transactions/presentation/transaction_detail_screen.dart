import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/kk_button.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../shared/models/transaction_model.dart';
import '../../../shared/services/api_service.dart';
import '../../../core/service_locator.dart';

import '../../../shared/constants/api_constants.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  const TransactionDetailScreen({super.key, required this.transactionId});
  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _txn;
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final api = sl<ApiService>();
      final res = await api.get('${ApiConstants.transactions}/${widget.transactionId}');
      setState(() { _txn = TransactionModel.fromJson(res.data['transaction']); _isLoading = false; });
    } catch (e) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Transaction Details'), actions: [IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {})]),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _txn == null ? Center(child: Text('Transaction not found', style: AppTextStyles.body))
          : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: (_txn!.isSuccess ? AppColors.green : AppColors.red).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(50)),
                child: Text(_txn!.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w600, color: _txn!.isSuccess ? AppColors.green : AppColors.red))),
              const SizedBox(height: 20),
              Text(CurrencyFormatter.formatInr(_txn!.amountInr), style: AppTextStyles.number.copyWith(color: AppColors.red)),
              const SizedBox(height: 24),
              GlassCard(padding: const EdgeInsets.all(20), child: Column(children: [
                _r('Transaction ID', _txn!.txnId), _d(), _r('Type', _txn!.type.toUpperCase()), _d(), _r('Recipient', _txn!.recipientName), _d(), _r('Date & Time', DateFormatter.formatFull(_txn!.createdAt)),
                if (_txn!.recipientAddress.isNotEmpty) ...[_d(), _r('Address', _txn!.recipientAddress)],
                if (_txn!.isCrypto && _txn!.cryptoAmount != null) ...[_d(), _r('Crypto Amount', '${_txn!.cryptoAmount} ${(_txn!.cryptoCoin ?? '').toUpperCase()}')],
                if (_txn!.txnHash != null) ...[_d(), _r('Tx Hash', '${_txn!.txnHash!.substring(0, 20)}...')],
              ])),
              const SizedBox(height: 24),
              KkButton(label: 'Download Receipt', outlined: true, icon: Icons.download_rounded, onTap: () {}),
              const SizedBox(height: 16),
              TextButton(onPressed: () {}, child: Text('Report Issue', style: AppTextStyles.body.copyWith(color: AppColors.red))),
            ])));
  }

  Widget _r(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l, style: AppTextStyles.caption), const SizedBox(width: 12), Flexible(child: Text(v, style: AppTextStyles.bodyMedium, textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis))]));
  Widget _d() => const Divider(color: AppColors.border, height: 20);
}
