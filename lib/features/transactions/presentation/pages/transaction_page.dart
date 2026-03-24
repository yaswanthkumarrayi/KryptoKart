import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../store/transaction_store.dart';

class TransactionPage extends StatelessWidget {
  const TransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'UPI'),
              Tab(text: 'Crypto'),
              Tab(text: 'Shopping'),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF060812), Color(0xFF10162A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ValueListenableBuilder<List<KkTransaction>>(
            valueListenable: TransactionStore.transactions,
            builder: (context, transactions, _) {
              return TabBarView(
                children: [
                  _TransactionList(
                    type: KkTransactionType.upi,
                    transactions: transactions,
                  ),
                  _TransactionList(
                    type: KkTransactionType.crypto,
                    transactions: transactions,
                  ),
                  _TransactionList(
                    type: KkTransactionType.shopping,
                    transactions: transactions,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final KkTransactionType type;
  final List<KkTransaction> transactions;

  const _TransactionList({required this.type, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final filtered = transactions.where((entry) => entry.type == type).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No transactions yet.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final transaction = filtered[index];
        final dateText = DateFormat('dd MMM, hh:mm a').format(transaction.date);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0x2A1A1F37),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorderColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF30224C),
                child: Icon(_iconForType(type), color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs ${transaction.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF22D3EE),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _iconForType(KkTransactionType input) {
    switch (input) {
      case KkTransactionType.upi:
        return Icons.account_balance_wallet_outlined;
      case KkTransactionType.crypto:
        return Icons.currency_bitcoin_rounded;
      case KkTransactionType.shopping:
        return Icons.shopping_bag_outlined;
    }
  }
}
