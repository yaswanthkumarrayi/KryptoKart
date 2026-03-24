import 'package:equatable/equatable.dart';

abstract class UpiEvent extends Equatable {
  const UpiEvent();

  @override
  List<Object?> get props => [];
}

class UpiPayeeSetEvent extends UpiEvent {
  final String upiId;
  final String payeeName;

  const UpiPayeeSetEvent({
    required this.upiId,
    this.payeeName = 'KryptoKart Merchant',
  });

  @override
  List<Object?> get props => [upiId, payeeName];
}

class UpiAmountUpdatedEvent extends UpiEvent {
  final double amount;

  const UpiAmountUpdatedEvent(this.amount);

  @override
  List<Object?> get props => [amount];
}

class UpiPaymentProcessingEvent extends UpiEvent {}

class UpiPaymentSuccessEvent extends UpiEvent {
  final double amount;
  final DateTime paidAt;

  const UpiPaymentSuccessEvent({required this.amount, required this.paidAt});

  @override
  List<Object?> get props => [amount, paidAt];
}

class UpiPaymentFailureEvent extends UpiEvent {
  final String message;

  const UpiPaymentFailureEvent(this.message);

  @override
  List<Object?> get props => [message];
}

class UpiResetEvent extends UpiEvent {}
