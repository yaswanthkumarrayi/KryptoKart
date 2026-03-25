part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class QrScannedUpi extends PaymentState {
  final String upiId;
  final String? merchantName;

  const QrScannedUpi({required this.upiId, this.merchantName});

  @override
  List<Object?> get props => [upiId, merchantName];
}

class QrScannedCrypto extends PaymentState {
  final String ethAddress;
  final String? merchantName;

  const QrScannedCrypto({required this.ethAddress, this.merchantName});

  @override
  List<Object?> get props => [ethAddress, merchantName];
}

class QrScannedUnknown extends PaymentState {}

class PaymentMethodSelected extends PaymentState {
  final PaymentMethod method;
  const PaymentMethodSelected(this.method);

  @override
  List<Object?> get props => [method];
}

class WalletConnecting extends PaymentState {}

class WalletConnected extends PaymentState {
  final String address;
  const WalletConnected(this.address);

  @override
  List<Object?> get props => [address];
}

class WalletDisconnected extends PaymentState {}

class FetchingCryptoRate extends PaymentState {}

class CryptoRateFetched extends PaymentState {
  final double inrRate;
  final String symbol;

  const CryptoRateFetched({required this.inrRate, required this.symbol});

  @override
  List<Object?> get props => [inrRate, symbol];
}

class PaymentProcessing extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final PaymentResult result;
  const PaymentSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class PaymentFailure extends PaymentState {
  final String message;
  const PaymentFailure(this.message);

  @override
  List<Object?> get props => [message];
}
