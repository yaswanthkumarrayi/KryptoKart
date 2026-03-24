import 'package:fpdart/fpdart.dart';
import 'package:kryptokart/core/error/failure.dart';
import 'package:kryptokart/core/usecase/usecase.dart';
import 'package:kryptokart/features/payment/data/services/upi_payment_service.dart';

class UpiPaymentParams {
  final String merchantUpiId;
  final double amountInr;
  final String? description;

  const UpiPaymentParams({
    required this.merchantUpiId,
    required this.amountInr,
    this.description,
  });
}

class ProcessUpiPayment implements UseCase<String, UpiPaymentParams> {
  final UpiPaymentService service;

  ProcessUpiPayment(this.service);

  @override
  Future<Either<Failure, String>> call(UpiPaymentParams params) async {
    final stream = service.processPayment(
      merchantUpiId: params.merchantUpiId,
      amountInr: params.amountInr,
      description: params.description ?? 'KryptoKart Payment',
    );

    // Return the first emitted event
    return stream.first;
  }
}
