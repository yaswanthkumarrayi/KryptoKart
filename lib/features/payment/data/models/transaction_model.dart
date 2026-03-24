import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String txId;

  @HiveField(1)
  final String method; // 'upi' or 'crypto'

  @HiveField(2)
  final double amountInr;

  @HiveField(3)
  final String? cryptoAmount;

  @HiveField(4)
  final String? cryptoSymbol;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final String merchantId;

  TransactionModel({
    required this.txId,
    required this.method,
    required this.amountInr,
    this.cryptoAmount,
    this.cryptoSymbol,
    required this.timestamp,
    required this.merchantId,
  });
}
