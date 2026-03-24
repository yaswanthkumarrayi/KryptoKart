import 'package:equatable/equatable.dart';

enum UpiStatus { initial, payeeSelected, processing, success, failure }

class UpiState extends Equatable {
  final UpiStatus status;
  final String payeeUpiId;
  final String payeeName;
  final double amount;
  final double? paidAmount;
  final DateTime? paidAt;
  final String? errorMessage;

  const UpiState({
    this.status = UpiStatus.initial,
    this.payeeUpiId = '',
    this.payeeName = 'KryptoKart Merchant',
    this.amount = 0,
    this.paidAmount,
    this.paidAt,
    this.errorMessage,
  });

  UpiState copyWith({
    UpiStatus? status,
    String? payeeUpiId,
    String? payeeName,
    double? amount,
    double? paidAmount,
    DateTime? paidAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UpiState(
      status: status ?? this.status,
      payeeUpiId: payeeUpiId ?? this.payeeUpiId,
      payeeName: payeeName ?? this.payeeName,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      paidAt: paidAt ?? this.paidAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    payeeUpiId,
    payeeName,
    amount,
    paidAmount,
    paidAt,
    errorMessage,
  ];
}
