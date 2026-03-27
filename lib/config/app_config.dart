/// Centralized app configuration reading from compile-time environment variables.
///
/// Pass values via `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=RAZORPAY_KEY_ID=rzp_test_xxx \
///   --dart-define=PAYMENT_BACKEND_URL=http://10.0.2.2:4000
/// ```
///
/// For development, fallback test keys are provided so the app works
/// immediately without --dart-define.
class AppConfig {
  AppConfig._();

  // ---------------------------------------------------------------------------
  // Razorpay Configuration
  // ---------------------------------------------------------------------------

  /// Razorpay test key for development fallback.
  /// IMPORTANT: Replace with empty string in production builds.
  static const String _fallbackTestKey = 'rzp_test_S01qKJJ0ovAUGa';

  /// Razorpay API Key ID (public key, safe to include in client).
  /// Falls back to test key in development if not provided via --dart-define.
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: _fallbackTestKey,
  );

  /// Whether Razorpay is properly configured.
  static bool get isRazorpayConfigured => razorpayKeyId.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Backend Configuration
  // ---------------------------------------------------------------------------

  /// Payment backend URL for order creation and verification.
  ///
  /// Defaults to Android emulator localhost (10.0.2.2:4000).
  /// Override via --dart-define for other environments:
  /// - iOS Simulator: http://localhost:4000
  /// - Physical Device: http://<your-machine-ip>:4000
  static const String paymentBackendUrl = String.fromEnvironment(
    'PAYMENT_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );

  // ---------------------------------------------------------------------------
  // Debug Utilities
  // ---------------------------------------------------------------------------

  /// Prints current configuration (for debugging).
  static void printConfig() {
    // ignore: avoid_print
    print('''
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                     KRYPTOKART CONFIGURATION                        
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  RAZORPAY_KEY_ID:     ${razorpayKeyId.isEmpty ? '❌ NOT SET' : '✅ ${_maskKey(razorpayKeyId)}'}
  PAYMENT_BACKEND_URL: $paymentBackendUrl
  Razorpay Ready:      ${isRazorpayConfigured ? '✅ YES' : '❌ NO'}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  NOTE: If backend is down, payments will use FALLBACK mode
        (direct Razorpay checkout without server verification)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');
  }

  /// Masks API key for safe logging (shows first 12 and last 4 chars).
  static String _maskKey(String key) {
    if (key.length <= 16) return key;
    return '${key.substring(0, 12)}...${key.substring(key.length - 4)}';
  }

  /// Returns a user-friendly error message if Razorpay is not configured.
  static String get razorpayMissingMessage =>
      'Razorpay key is missing. Set RAZORPAY_KEY_ID via --dart-define.\n\n'
      'Example:\n'
      'flutter run --dart-define=RAZORPAY_KEY_ID=rzp_test_xxx';
}
