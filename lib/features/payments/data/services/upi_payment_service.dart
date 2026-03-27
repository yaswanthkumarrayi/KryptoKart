import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:billing_fixed/core/error/failure.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class UpiPaymentService {
  static const String _razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );
  static const String _backendBaseUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: 'http://localhost:4000',
  );

  Razorpay? _razorpay;
  StreamController<Either<Failure, String>>? _controller;
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

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
    String? customerEmail,
    String? customerContact,
  }) {
    // Close any previous controller
    _controller?.close();
    _razorpay?.clear();

    _controller = StreamController<Either<Failure, String>>();
    if (kIsWeb) {
      _controller!.add(
        const Left(
          ServerFailure(
            'Razorpay native checkout is supported on Android/iOS only. '
            'Run this payment flow on a mobile device or emulator.',
          ),
        ),
      );
      _controller!.close();
      return _controller!.stream;
    }

    if (_razorpayKeyId.isEmpty) {
      _controller!.add(
        const Left(
          ServerFailure(
            'Razorpay key is missing. Set RAZORPAY_KEY_ID via --dart-define.',
          ),
        ),
      );
      _controller!.close();
      return _controller!.stream;
    }
    if (amountInr <= 0) {
      _controller!.add(const Left(ServerFailure('Amount must be greater than 0.')));
      _controller!.close();
      return _controller!.stream;
    }

    _razorpay = Razorpay();

    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final amountPaise = (amountInr * 100).round();
    final options = <String, dynamic>{
      'key': _razorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'KryptoKart',
      'description': description,
      'send_sms_hash': true,
      'retry': {
        'enabled': true,
        'max_count': 4,
      },
      'prefill': {
        'contact': customerContact ?? '',
        'email': customerEmail ?? '',
        'method': 'upi',
        'vpa': merchantUpiId,
      },
      'theme': {'color': '#6C63FF'},
    };

    unawaited(
      _openCheckoutWithOrder(
        amountPaise: amountPaise,
        options: options,
      ),
    );

    return _controller!.stream;
  }

  Future<void> _openCheckoutWithOrder({
    required int amountPaise,
    required Map<String, dynamic> options,
  }) async {
    try {
      final orderData = await _createOrder(amountPaise: amountPaise);
      options['order_id'] = orderData['order_id'];
      options['amount'] = orderData['amount'];
      options['currency'] = orderData['currency'];
      debugPrint('Razorpay order created: ${orderData['order_id']}');
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('UpiPaymentService Razorpay.open error: $e');
      _controller?.add(Left(ServerFailure('Could not open Razorpay: $e')));
      await _cleanup();
    }
  }

  Future<Map<String, dynamic>> _createOrder({required int amountPaise}) async {
    try {
      final response = await _dio.post(
        '$_backendBaseUrl/create-order',
        data: {
          'amount': amountPaise,
          'currency': 'INR',
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid create-order response.');
      }
      if (data['order_id'] == null || data['amount'] == null || data['currency'] == null) {
        throw Exception('Missing create-order fields.');
      }
      return data;
    } catch (e) {
      throw Exception('Order creation failed: $e');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    unawaited(_verifyAndComplete(response));
  }

  Future<void> _verifyAndComplete(PaymentSuccessResponse response) async {
    try {
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;
      if (orderId == null || paymentId == null || signature == null) {
        _controller?.add(
          const Left(ServerFailure('Missing Razorpay fields required for verification.')),
        );
        await _cleanup();
        return;
      }

      final verify = await _dio.post(
        '$_backendBaseUrl/verify-payment',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      final verified = verify.data is Map<String, dynamic> &&
          verify.data['verified'] == true;
      if (!verified) {
        _controller?.add(const Left(ServerFailure('Payment verification failed.')));
        await _cleanup();
        return;
      }

      debugPrint('Razorpay verified payment: $paymentId');
      _controller?.add(Right(paymentId));
    } catch (e) {
      debugPrint('Payment verification error: $e');
      _controller?.add(Left(ServerFailure('Payment verification error: $e')));
    } finally {
      await _cleanup();
    }
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('Razorpay error: ${response.message}');
    _controller?.add(Left(ServerFailure(response.message ?? 'Payment failed')));
    unawaited(_cleanup());
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
    _controller?.add(
        Left(ServerFailure('External wallet chosen: ${response.walletName}')));
    unawaited(_cleanup());
  }

  Future<void> _cleanup() async {
    _razorpay?.clear();
    _razorpay = null;
    if (_controller != null && !_controller!.isClosed) {
      await _controller!.close();
    }
    _controller = null;
  }

  void dispose() => unawaited(_cleanup());
}
