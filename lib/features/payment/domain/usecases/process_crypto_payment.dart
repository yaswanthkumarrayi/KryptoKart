import 'package:fpdart/fpdart.dart';
import 'package:kryptokart/core/error/failure.dart';
import 'package:kryptokart/core/usecase/usecase.dart';
import 'package:kryptokart/features/payment/data/services/crypto_payment_service.dart';

class CryptoPaymentParams {
  final String merchantEthAddress;
  final double amountInr;
  final CryptoToken token;

  const CryptoPaymentParams({
    required this.merchantEthAddress,
    required this.amountInr,
    required this.token,
  });
}

class ProcessCryptoPayment implements UseCase<String, CryptoPaymentParams> {
  final CryptoPaymentService service;

  ProcessCryptoPayment(this.service);

  @override
  Future<Either<Failure, String>> call(CryptoPaymentParams params) {
    return service.sendPayment(
      merchantEthAddress: params.merchantEthAddress,
      amountInr: params.amountInr,
      token: params.token,
    );
  }
}
