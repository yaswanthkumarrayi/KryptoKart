import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:billing_fixed/core/error/failure.dart';
import 'package:billing_fixed/features/payments/data/services/price_oracle_service.dart';
import 'package:billing_fixed/features/payments/data/services/wallet_service.dart';

/// Supported crypto tokens for payment
enum CryptoToken { eth, matic }

class CryptoPaymentService {
  final PriceOracleService priceOracleService;
  final WalletService walletService;

  // Polygon Mainnet RPC (used in production for Web3Client)
  // ignore: unused_field
  static const _rpcUrl = 'https://polygon-rpc.com';
  
  // Alternative RPCs if needed:
  // static const _rpcUrl = 'https://rpc.ankr.com/polygon';
  // static const _rpcUrl = 'https://polygon.llamarpc.com';

  CryptoPaymentService({
    required this.priceOracleService,
    required this.walletService,
  });

  Future<Either<Failure, String>> sendPayment({
    required String merchantEthAddress,
    required double amountInr,
    required CryptoToken token,
  }) async {
    try {
      // 1. Get live prices
      final pricesResult = await priceOracleService.getLivePrices();
      late Map<String, double> prices;
      pricesResult.fold(
        (failure) => throw Exception(failure.message),
        (p) => prices = p,
      );

      final priceKey = token == CryptoToken.eth ? 'eth' : 'matic';
      final priceInr = prices[priceKey] ?? 0.0;
      if (priceInr <= 0) {
        return const Left(ServerFailure('Invalid crypto price received'));
      }

      final cryptoAmount = amountInr / priceInr;

      // 2. Get sender address
      final senderAddress = walletService.getConnectedAddress();
      if (senderAddress == null) {
        return const Left(ServerFailure('Wallet not connected'));
      }

      debugPrint('CryptoPaymentService: preparing $cryptoAmount ${token.name.toUpperCase()} '
          'from $senderAddress to $merchantEthAddress');

      // 3. For demo mode: simulate successful transaction
      // In production with WalletConnect, the tx would be signed by the wallet app
      //
      // Production flow would be:
      //   final txHash = await _web3app.request(
      //     topic: session.topic,
      //     chainId: 'eip155:137',
      //     request: SessionRequestParams(method: 'eth_sendTransaction', params: [txData]),
      //   );
      
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate a realistic-looking transaction hash for demo
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fakeTxHash = '0x${timestamp.toRadixString(16).padLeft(64, '0')}';
      
      debugPrint('CryptoPaymentService: Demo transaction created: $fakeTxHash');
      
      return Right(fakeTxHash);
    } catch (e) {
      debugPrint('CryptoPaymentService error: $e');
      return Left(ServerFailure('Crypto payment failed: $e'));
    }
  }

  /// Calculate crypto amount from INR without sending
  Future<Either<Failure, double>> calculateCryptoAmount({
    required double amountInr,
    required CryptoToken token,
  }) async {
    final result = await priceOracleService.getLivePrices();
    return result.fold(
      Left.new,
      (prices) {
        final key = token == CryptoToken.eth ? 'eth' : 'matic';
        final price = prices[key] ?? 0.0;
        if (price <= 0) return const Left(ServerFailure('Invalid price'));
        return Right(amountInr / price);
      },
    );
  }
}
