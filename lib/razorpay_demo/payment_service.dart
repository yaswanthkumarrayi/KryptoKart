import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentStatus {
  final bool success;
  final String message;
  final String? paymentId;

  const PaymentStatus({
    required this.success,
    required this.message,
    this.paymentId,
  });
}

class RazorpayPaymentService {
  static const String _backendBaseUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: 'http://localhost:4000',
  );
  static const String _keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: '',
  );

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Razorpay? _razorpay;
  Completer<PaymentStatus>? _resultCompleter;

  Future<PaymentStatus> startPayment({
    required int amountPaise,
    String currency = 'INR',
    String name = 'KryptoKart',
    String description = 'Test payment',
    String email = '',
    String contact = '',
  }) async {
    if (kIsWeb) {
      return const PaymentStatus(
        success: false,
        message: 'Razorpay native checkout works only on Android/iOS.',
      );
    }
    if (_keyId.isEmpty) {
      return const PaymentStatus(
        success: false,
        message: 'Missing RAZORPAY_KEY_ID. Pass via --dart-define.',
      );
    }
    if (amountPaise <= 0) {
      return const PaymentStatus(
        success: false,
        message: 'Amount must be greater than zero.',
      );
    }

    _disposeInternals();
    _resultCompleter = Completer<PaymentStatus>();
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    try {
      final order = await _createOrder(amountPaise: amountPaise, currency: currency);
      final options = {
        'key': _keyId,
        'order_id': order['order_id'],
        'amount': order['amount'],
        'currency': order['currency'],
        'name': name,
        'description': description,
        'prefill': {
          'email': email,
          'contact': contact,
        },
        'retry': {
          'enabled': true,
          'max_count': 4,
        },
      };
      _razorpay!.open(options);
      return _resultCompleter!.future;
    } catch (e) {
      debugPrint('startPayment error: $e');
      _complete(
        PaymentStatus(
          success: false,
          message: 'Could not start payment: $e',
        ),
      );
      return _resultCompleter!.future;
    }
  }

  Future<Map<String, dynamic>> _createOrder({
    required int amountPaise,
    required String currency,
  }) async {
    final response = await _dio.post(
      '$_backendBaseUrl/create-order',
      data: {
        'amount': amountPaise,
        'currency': currency,
      },
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid /create-order response.');
    }
    return response.data as Map<String, dynamic>;
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    unawaited(_verifyAndComplete(response));
  }

  Future<void> _verifyAndComplete(PaymentSuccessResponse response) async {
    try {
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;
      if (orderId == null || paymentId == null || signature == null) {
        _complete(const PaymentStatus(
          success: false,
          message: 'Missing success fields for verification.',
        ));
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
        _complete(const PaymentStatus(
          success: false,
          message: 'Signature verification failed.',
        ));
        return;
      }

      _complete(PaymentStatus(
        success: true,
        message: 'Payment verified successfully.',
        paymentId: paymentId,
      ));
    } catch (e) {
      _complete(PaymentStatus(
        success: false,
        message: 'Verification error: $e',
      ));
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _complete(PaymentStatus(
      success: false,
      message: response.message ?? 'Payment failed.',
    ));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    _complete(PaymentStatus(
      success: false,
      message: 'External wallet selected: ${response.walletName ?? 'unknown'}',
    ));
  }

  void _complete(PaymentStatus status) {
    if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
      _resultCompleter!.complete(status);
    }
    _disposeInternals();
  }

  void _disposeInternals() {
    _razorpay?.clear();
    _razorpay = null;
  }

  void dispose() {
    _disposeInternals();
  }
}
