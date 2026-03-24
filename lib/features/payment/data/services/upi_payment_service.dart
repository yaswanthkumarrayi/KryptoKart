import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kryptokart/core/error/failure.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class UpiPaymentService {
  Razorpay? _razorpay;
  StreamController<Either<Failure, String>>? _controller;

  /// Process a UPI payment via Razorpay.
  ///
  /// Returns a stream that emits exactly one event:
  ///   - [Right(paymentId)] on success
  ///   - [Left(failure)] on failure or external wallet selection
  Stream<Either<Failure, String>> processPayment({
    required String merchantUpiId,
    required double amountInr,
    String description = 'KryptoKart Payment',
    String? contactName,
  }) {
    // Close any previous controller
    _controller?.close();
    _razorpay?.clear();

    _controller = StreamController<Either<Failure, String>>();
    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = {
      'key': 'rzp_test_YOUR_KEY_HERE', // Replace with your Razorpay key
      'amount': (amountInr * 100).toInt(), // In paise
      'name': 'KryptoKart',
      'description': description,
      'prefill': {
        'contact': '',
        'email': '',
        'method': 'upi',
        'vpa': merchantUpiId,
      },
      'theme': {'color': '#6C63FF'},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('UpiPaymentService Razorpay.open error: $e');
      _controller!.add(Left(ServerFailure('Could not open Razorpay: $e')));
      _controller!.close();
    }

    return _controller!.stream;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay success: ${response.paymentId}');
    _controller?.add(Right(response.paymentId ?? 'unknown'));
    _cleanup();
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('Razorpay error: ${response.message}');
    _controller?.add(Left(ServerFailure(response.message ?? 'Payment failed')));
    _cleanup();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
    _controller?.add(
        Left(ServerFailure('External wallet chosen: ${response.walletName}')));
    _cleanup();
  }

  void _cleanup() {
    _razorpay?.clear();
    _razorpay = null;
    _controller?.close();
    _controller = null;
  }

  void dispose() => _cleanup();
}
