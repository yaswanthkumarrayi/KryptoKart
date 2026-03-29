import 'package:flutter/material.dart';
import '../../../core/theme/kk_palette.dart';
import '../../../core/theme/kk_theme_context.dart';
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
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  TransactionModel? _txn;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = sl<ApiService>();
      final res = await api.get(
        '${ApiConstants.transactions}/${widget.transactionId}',
      );
      setState(() {
        _txn = TransactionModel.fromJson(res.data['transaction']);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = context.txt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: p.accent))
          : _txn == null
              ? Center(
                  child: Text(
                    'Transaction not found',
                    style: t.body,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: (_txn!.isSuccess ? p.green : p.red)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _txn!.status.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _txn!.isSuccess ? p.green : p.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        CurrencyFormatter.formatInr(_txn!.amountInr),
                        style: t.number.copyWith(color: p.red),
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _r(context, 'Transaction ID', _txn!.txnId),
                            _d(p),
                            _r(context, 'Type', _txn!.type.toUpperCase()),
                            _d(p),
                            _r(context, 'Recipient', _txn!.recipientName),
                            _d(p),
                            _r(
                              context,
                              'Date & Time',
                              DateFormatter.formatFull(_txn!.createdAt),
                            ),
                            if (_txn!.recipientAddress.isNotEmpty) ...[
                              _d(p),
                              _r(context, 'Address', _txn!.recipientAddress),
                            ],
                            if (_txn!.isCrypto && _txn!.cryptoAmount != null) ...[
                              _d(p),
                              _r(
                                context,
                                'Crypto Amount',
                                '${_txn!.cryptoAmount} ${(_txn!.cryptoCoin ?? '').toUpperCase()}',
                              ),
                            ],
                            if (_txn!.txnHash != null) ...[
                              _d(p),
                              _r(
                                context,
                                'Tx Hash',
                                '${_txn!.txnHash!.substring(0, 20)}...',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      KkButton(
                        label: 'Download Receipt',
                        outlined: true,
                        icon: Icons.download_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Report Issue',
                          style: t.body.copyWith(color: p.red),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _r(BuildContext context, String l, String v) {
    final t = context.txt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l, style: t.caption),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              v,
              style: t.bodyMedium,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _d(KkPalette p) => Divider(color: p.border, height: 20);
}
