part of 'payment_bloc.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class ScanQrCodeEvent extends PaymentEvent {
  final String rawQrData;
  const ScanQrCodeEvent(this.rawQrData);

  @override
  List<Object?> get props => [rawQrData];
}

class SelectPaymentMethodEvent extends PaymentEvent {
  final PaymentMethod method;
  const SelectPaymentMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class ConnectWalletEvent extends PaymentEvent {}

class DisconnectWalletEvent extends PaymentEvent {}

class ProcessPaymentEvent extends PaymentEvent {
  final double amountInr;
  final String merchantId;
  final bool isCrypto;
  final CryptoToken? cryptoToken;

  const ProcessPaymentEvent({
    required this.amountInr,
    required this.merchantId,
    this.isCrypto = false,
    this.cryptoToken,
  });

  @override
  List<Object?> get props => [amountInr, merchantId, isCrypto, cryptoToken];
}

class ResetPaymentEvent extends PaymentEvent {}
