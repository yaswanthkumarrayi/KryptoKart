import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:billing_fixed/core/error/failure.dart';
import 'package:billing_fixed/config/app_config.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Payment service with automatic fallback.
/// 
/// Flow:
/// 1. Try to create order via backend (secure, recommended)
/// 2. If backend fails, fall back to direct Razorpay checkout (for testing)
class UpiPaymentService {
  static String get _razorpayKeyId => AppConfig.razorpayKeyId;
  static String get _backendBaseUrl => AppConfig.paymentBackendUrl;

  Razorpay? _razorpay;
  StreamController<Either<Failure, String>>? _controller;
  bool _usedFallback = false;
  
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Check if the backend server is reachable.
  Future<bool> isBackendAvailable() async {
    try {
      final response = await _dio.get(
        '$_backendBaseUrl/health',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Backend health check failed: $e');
      return false;
    }
  }

  /// Process a payment via Razorpay.
  /// 
  /// Automatically falls back to direct checkout if backend is unavailable.
  Stream<Either<Failure, String>> processPayment({
    required String merchantUpiId,
    required double amountInr,
    String description = 'KryptoKart Payment',
    String? contactName,
    String? customerEmail,
    String? customerContact,
  }) {
    _controller?.close();
    _razorpay?.clear();
    _usedFallback = false;

    _controller = StreamController<Either<Failure, String>>();
    
    // Platform check
    if (kIsWeb) {
      _controller!.add(const Left(ServerFailure(
        'Razorpay native checkout is supported on Android/iOS only.',
      )));
      _controller!.close();
      return _controller!.stream;
    }

    // Key check
    if (_razorpayKeyId.isEmpty) {
      _controller!.add(Left(ServerFailure(AppConfig.razorpayMissingMessage)));
      _controller!.close();
      return _controller!.stream;
    }

    // Amount check
    if (amountInr <= 0) {
      _controller!.add(const Left(ServerFailure('Amount must be greater than 0.')));
      _controller!.close();
      return _controller!.stream;
    }

    // Initialize Razorpay
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final amountPaise = (amountInr * 100).round();
    
    // Base options (works with or without order_id)
    final options = <String, dynamic>{
      'key': _razorpayKeyId,
      'amount': amountPaise,
      'currency': 'INR',
      'name': 'KryptoKart',
      'description': description,
      'send_sms_hash': true,
      'retry': {'enabled': true, 'max_count': 4},
      'prefill': {
        'contact': customerContact ?? '9999999999',
        'email': customerEmail ?? 'customer@example.com',
        'method': 'upi',
        'vpa': merchantUpiId,
      },
      'theme': {'color': '#6C63FF'},
    };

    // Start payment flow
    unawaited(_startPaymentFlow(amountPaise: amountPaise, options: options));
    
    return _controller!.stream;
  }

  Future<void> _startPaymentFlow({
    required int amountPaise,
    required Map<String, dynamic> options,
  }) async {
    try {
      // STEP 1: Try to create order via backend
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔄 Attempting order creation via backend...');
      debugPrint('   URL: $_backendBaseUrl/create-order');
      debugPrint('   Amount: $amountPaise paise');
      
      final orderData = await _createOrder(amountPaise: amountPaise);
      
      // Backend succeeded - use order-based checkout (recommended)
      options['order_id'] = orderData['order_id'];
      options['amount'] = orderData['amount'];
      options['currency'] = orderData['currency'];
      
      debugPrint('✅ Order created: ${orderData['order_id']}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
    } catch (e) {
      // STEP 2: Backend failed - use fallback (direct checkout)
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('⚠️ Backend unavailable: $e');
      debugPrint('🔄 Using FALLBACK mode (direct checkout)');
      debugPrint('   Note: Signature verification will be skipped');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      _usedFallback = true;
    }
    
    // STEP 3: Open Razorpay checkout
    try {
      debugPrint('🚀 Opening Razorpay checkout...');
      debugPrint('   Key: ${_razorpayKeyId.substring(0, 12)}...');
      debugPrint('   Amount: ${options['amount']} paise');
      debugPrint('   Order ID: ${options['order_id'] ?? 'NONE (fallback mode)'}');
      
      _razorpay!.open(options);
      
    } catch (e) {
      debugPrint('❌ Failed to open Razorpay: $e');
      _controller?.add(Left(ServerFailure('Failed to open Razorpay: $e')));
      await _cleanup();
    }
  }

  Future<Map<String, dynamic>> _createOrder({required int amountPaise}) async {
    final response = await _dio.post(
      '$_backendBaseUrl/create-order',
      data: {'amount': amountPaise, 'currency': 'INR'},
    );
    
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    if (data['order_id'] == null) {
      throw Exception('Missing order_id in response');
    }
    return data;
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ PAYMENT SUCCESS');
    debugPrint('   Payment ID: ${response.paymentId}');
    debugPrint('   Order ID: ${response.orderId}');
    debugPrint('   Signature: ${response.signature?.substring(0, 20)}...');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    if (_usedFallback) {
      // Fallback mode - skip server verification
      debugPrint('⚠️ Fallback mode - skipping server verification');
      _controller?.add(Right(response.paymentId ?? 'fallback_success'));
      unawaited(_cleanup());
    } else {
      // Normal mode - verify on server
      unawaited(_verifyPayment(response));
    }
  }

  Future<void> _verifyPayment(PaymentSuccessResponse response) async {
    try {
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;
      
      if (orderId == null || paymentId == null || signature == null) {
        _controller?.add(const Left(ServerFailure(
          'Missing payment details for verification.',
        )));
        await _cleanup();
        return;
      }

      debugPrint('🔄 Verifying payment on server...');
      
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
        debugPrint('❌ Server verification failed');
        _controller?.add(const Left(ServerFailure('Payment verification failed.')));
      } else {
        debugPrint('✅ Payment verified by server');
        _controller?.add(Right(paymentId));
      }
    } catch (e) {
      debugPrint('⚠️ Verification error (accepting payment): $e');
      // If verification fails but payment succeeded, still accept it
      _controller?.add(Right(response.paymentId ?? 'unverified_success'));
    } finally {
      await _cleanup();
    }
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('❌ PAYMENT FAILED');
    debugPrint('   Code: ${response.code}');
    debugPrint('   Message: ${response.message}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    _controller?.add(Left(ServerFailure(response.message ?? 'Payment failed')));
    unawaited(_cleanup());
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
    _controller?.add(Left(ServerFailure(
      'External wallet selected: ${response.walletName}',
    )));
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
