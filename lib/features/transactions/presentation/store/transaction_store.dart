import 'package:flutter/foundation.dart';

enum KkTransactionType { upi, crypto, shopping }

class KkTransaction {
  final KkTransactionType type;
  final double amount;
  final String title;
  final DateTime date;

  const KkTransaction({
    required this.type,
    required this.amount,
    required this.title,
    required this.date,
  });
}

class TransactionStore {
  TransactionStore._();

  static final ValueNotifier<List<KkTransaction>> transactions =
      ValueNotifier<List<KkTransaction>>([
        KkTransaction(
          type: KkTransactionType.upi,
          amount: 249.0,
          title: 'UPI - Grocery Merchant',
          date: DateTime.now().subtract(const Duration(hours: 4)),
        ),
        KkTransaction(
          type: KkTransactionType.crypto,
          amount: 1200.0,
          title: 'ETH - Wallet Transfer',
          date: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
        ),
        KkTransaction(
          type: KkTransactionType.shopping,
          amount: 1899.0,
          title: 'Shopping - Reliance Smart',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ]);

  static void add(KkTransaction transaction) {
    final updated = [transaction, ...transactions.value];
    transactions.value = updated;
  }
}
