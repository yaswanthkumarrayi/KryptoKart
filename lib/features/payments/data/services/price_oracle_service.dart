import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:billing_fixed/core/error/failure.dart';

class PriceOracleService {
  final Dio _dio;

  Map<String, double>? _cache;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(seconds: 60);

  PriceOracleService({Dio? dio}) : _dio = dio ?? Dio();

  Future<Either<Failure, Map<String, double>>> getLivePrices() async {
    // Return cached result if still valid
    if (_cache != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return Right(_cache!);
    }

    try {
      final response = await _dio.get(
        'https://api.coingecko.com/api/v3/simple/price',
        queryParameters: {
          'ids': 'ethereum,matic-network',
          'vs_currencies': 'inr',
        },
      );

      final data = response.data as Map<String, dynamic>;

      final eth =
          (data['ethereum']?['inr'] as num?)?.toDouble() ?? 0.0;
      final matic =
          (data['matic-network']?['inr'] as num?)?.toDouble() ?? 0.0;

      _cache = {'eth': eth, 'matic': matic};
      _cacheTime = DateTime.now();

      return Right(_cache!);
    } on DioException catch (e) {
      return Left(NetworkFailure(
          'Failed to fetch crypto prices: ${e.message ?? e.toString()}'));
    } catch (e) {
      return Left(NetworkFailure('Unexpected error: $e'));
    }
  }
}
