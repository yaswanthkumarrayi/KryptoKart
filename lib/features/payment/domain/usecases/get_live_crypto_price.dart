import 'package:fpdart/fpdart.dart';
import 'package:kryptokart/core/error/failure.dart';
import 'package:kryptokart/core/usecase/usecase.dart';
import 'package:kryptokart/features/payment/data/services/price_oracle_service.dart';

class GetLiveCryptoPrice
    implements UseCase<Map<String, double>, NoParams> {
  final PriceOracleService service;

  GetLiveCryptoPrice(this.service);

  @override
  Future<Either<Failure, Map<String, double>>> call(NoParams params) {
    return service.getLivePrices();
  }
}
