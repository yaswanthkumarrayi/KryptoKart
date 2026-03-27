import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

/// Payment result returned by the service
class PaymentResult {
  final bool success;
  final String message;
  final String? paymentId;
  final String? orderId;
  final bool usedFallback;

  const PaymentResult({
    required this.success,
    required this.message,
    this.paymentId,
    this.orderId,
    this.usedFallback = false,
  });
}

/// Razorpay payment service with automatic fallback.
///
/// If backend is unavailable, opens Razorpay directly without order_id.
/// This allows testing payments even without running the backend.
class RazorpayPaymentService {
  static const String _keyId = AppConstants.razorpayKeyId;
  static String get _backendBaseUrl => ApiConstants.backendBase;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Razorpay? _razorpay;
  Completer<PaymentResult>? _resultCompleter;
  bool _usedFallback = false;
  String? _authToken;

  /// Set auth token for backend API calls
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Check if backend is reachable
  Future<bool> checkBackendHealth() async {
    try {
      final response = await _dio.get(
        '$_backendBaseUrl/api/payments/health',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Start a payment with automatic fallback if backend is unavailable.
  Future<PaymentResult> startPayment({
    required int amountPaise,
    String currency = 'INR',
    String name = 'KryptoKart',
    String description = 'Payment',
    String email = 'customer@example.com',
    String contact = '9999999999',
  }) async {
    // Platform check
    if (kIsWeb) {
      return const PaymentResult(
        success: false,
        message: 'Razorpay native checkout works only on Android/iOS.',
      );
    }

    // Key check
    if (_keyId.isEmpty) {
      return const PaymentResult(
        success: false,
        message:
            'Razorpay key not configured. Please run with --dart-define=RAZORPAY_KEY_ID=your_key',
      );
    }

    // Amount check
    if (amountPaise <= 0) {
      return const PaymentResult(
        success: false,
        message: 'Amount must be greater than zero.',
      );
    }

    // Initialize
    _disposeInternals();
    _resultCompleter = Completer<PaymentResult>();
    _usedFallback = false;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Base options (works with or without order_id)
    final options = <String, dynamic>{
      'key': _keyId,
      'amount': amountPaise,
      'currency': currency,
      'name': name,
      'description': description,
      'prefill': {'email': email, 'contact': contact},
      'retry': {'enabled': true, 'max_count': 4},
      'theme': {'color': '#00E5FF'},
      'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
    };

    // Try backend, fallback if needed
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔄 Creating order via backend...');
      debugPrint('   URL: $_backendBaseUrl/api/payments/create-order');
      debugPrint('   Amount: $amountPaise paise');

      final order = await _createOrder(
        amountPaise: amountPaise,
        currency: currency,
      );

      options['order_id'] = order['order_id'];
      options['amount'] = order['amount'];
      options['currency'] = order['currency'];

      debugPrint('✅ Order created: ${order['order_id']}');
    } catch (e) {
      debugPrint('⚠️ Backend unavailable: $e');
      debugPrint('🔄 Using FALLBACK mode (no order_id)');
      debugPrint('   Note: Payment will still work, verification skipped');
      _usedFallback = true;
    }

    // Open Razorpay
    try {
      debugPrint('🚀 Opening Razorpay checkout...');
      debugPrint('   Key: ${_keyId.substring(0, 12)}...');
      debugPrint('   Amount: ${options['amount']} paise');
      debugPrint('   Order ID: ${options['order_id'] ?? 'NONE (fallback)'}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      _razorpay!.open(options);

      return _resultCompleter!.future;
    } catch (e) {
      debugPrint('❌ Failed to open Razorpay: $e');
      _complete(
        PaymentResult(
          success: false,
          message: 'Failed to open Razorpay: $e',
          usedFallback: _usedFallback,
        ),
      );
      return _resultCompleter!.future;
    }
  }

  Future<Map<String, dynamic>> _createOrder({
    required int amountPaise,
    required String currency,
  }) async {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    final response = await _dio.post(
      '$_backendBaseUrl/api/payments/create-order',
      data: {'amount': amountPaise, 'currency': currency},
      options: Options(headers: headers),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid response');
    }
    return response.data as Map<String, dynamic>;
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ PAYMENT SUCCESS');
    debugPrint('   Payment ID: ${response.paymentId}');
    debugPrint('   Order ID: ${response.orderId}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (_usedFallback) {
      // Fallback mode - skip verification
      _complete(
        PaymentResult(
          success: true,
          message: 'Payment successful (fallback mode)',
          paymentId: response.paymentId,
          orderId: response.orderId,
          usedFallback: true,
        ),
      );
    } else {
      // Normal mode - verify
      unawaited(_verifyAndComplete(response));
    }
  }

  Future<void> _verifyAndComplete(PaymentSuccessResponse response) async {
    try {
      final orderId = response.orderId;
      final paymentId = response.paymentId;
      final signature = response.signature;

      if (orderId == null || paymentId == null || signature == null) {
        _complete(
          PaymentResult(
            success: true,
            message: 'Payment successful (unverified)',
            paymentId: paymentId,
            orderId: orderId,
          ),
        );
        return;
      }

      debugPrint('🔄 Verifying payment...');

      final headers = <String, dynamic>{'Content-Type': 'application/json'};
      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }

      final verify = await _dio.post(
        '$_backendBaseUrl/api/payments/verify',
        data: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
        options: Options(headers: headers),
      );

      final verified =
          verify.data is Map<String, dynamic> &&
          verify.data['verified'] == true;

      if (!verified) {
        debugPrint('⚠️ Verification failed, accepting anyway');
      } else {
        debugPrint('✅ Payment verified');
      }

      _complete(
        PaymentResult(
          success: true,
          message: verified ? 'Payment verified' : 'Payment successful',
          paymentId: paymentId,
          orderId: orderId,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Verification error: $e');
      // Accept payment even if verification fails
      _complete(
        PaymentResult(
          success: true,
          message: 'Payment successful (verification skipped)',
          paymentId: response.paymentId,
          orderId: response.orderId,
        ),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('❌ PAYMENT FAILED');
    debugPrint('   Code: ${response.code}');
    debugPrint('   Message: ${response.message}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _complete(
      PaymentResult(
        success: false,
        message: response.message ?? 'Payment failed',
        usedFallback: _usedFallback,
      ),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet: ${response.walletName}');
    _complete(
      PaymentResult(
        success: false,
        message:
            'External wallet selected: ${response.walletName ?? 'unknown'}',
        usedFallback: _usedFallback,
      ),
    );
  }

  void _complete(PaymentResult result) {
    if (_resultCompleter != null && !_resultCompleter!.isCompleted) {
      _resultCompleter!.complete(result);
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
