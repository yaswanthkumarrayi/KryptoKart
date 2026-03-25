import 'package:equatable/equatable.dart';

enum PaymentMethod { upi, crypto }

class PaymentResult extends Equatable {
  final String txId;
  final PaymentMethod method;
  final double amountInr;
  final String? cryptoAmount;
  final String? cryptoSymbol;
  final DateTime timestamp;
  final String merchantId;

  const PaymentResult({
    required this.txId,
    required this.method,
    required this.amountInr,
    this.cryptoAmount,
    this.cryptoSymbol,
    required this.timestamp,
    required this.merchantId,
  });

  @override
  List<Object?> get props =>
      [txId, method, amountInr, cryptoAmount, cryptoSymbol, timestamp, merchantId];
}
